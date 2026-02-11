import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:math/core/services/device_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/core/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// This enum helps our router decide which screen to show
enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final DeviceService _deviceService =
      DeviceService(); // Assuming this is needed

  User? _user;
  UserModel? _userModel;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isGoogleSignInInitialized = false;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  AuthStatus get status => _status;

  // State for phone authentication
  String? _verificationId;
  AuthCredential? _googleCredential; // Store Google credential for linking

  AuthService() : _firebaseAuth = FirebaseAuth.instance {
    _initializeGoogleSignIn();
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    _userDocSubscription?.cancel();

    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userModel = null;
    } else {
      _status = AuthStatus.authenticated;
      _startUserDocListener(user.uid);
      uploadOnboardingData(user);
      _deviceService.saveDeviceInfo(user); // Assuming this is implemented
    }

    logger.i('Auth state changed: $_status');
    notifyListeners(); // This notifies go_router to redirect!
  }

  void _startUserDocListener(String uid) {
    _userDocSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            _userModel = UserModel.fromJson(snapshot.data()!);
            notifyListeners();
          }
        });
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  // --- Profile & Onboarding Helper ---

  Future<void> uploadOnboardingData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

      if (!onboardingComplete) {
        return;
      }

      final Map<String, dynamic> onboardingData = {
        'fullName': prefs.getString('tempUserName'),
        'appLanguage': prefs.getString('onboard_language'),
        'learningMedium': prefs.getString('onboard_medium'),
        'grades': prefs.getStringList('onboard_grades'),
        'province': prefs.getString('onboard_province'),
        'district': prefs.getString('onboard_district'),
        'city': prefs.getString('onboard_city'),
        'gender': prefs.getString('onboard_gender'),
        'onboardingCompleted': true,
        'lastOnboarded': FieldValue.serverTimestamp(),
      };

      onboardingData.removeWhere((key, value) => value == null);

      if (onboardingData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(onboardingData, SetOptions(merge: true));

        await prefs.remove('tempUserName');
        await prefs.remove('onboard_language');
        await prefs.remove('onboard_medium');
        await prefs.remove('onboard_grades');
        await prefs.remove('onboard_province');
        await prefs.remove('onboard_district');
        await prefs.remove('onboard_city');
        await prefs.remove('onboard_gender');
        await prefs.remove('onboardingComplete');
        logger.i('Cleared temp onboarding data from SharedPreferences.');
      }
    } catch (e, s) {
      logger.e('Failed to upload onboarding data', error: e, stackTrace: s);
    }
  }

  // --- Google Sign-In Init Methods ---
  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '1099003660019-96pai0qdt5s847ld94ggk9rh4nm4d6mm.apps.googleusercontent.com',
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      logger.e('Google Sign-In initialization failed', error: e);
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  // --- Auth Checks and Logic ---
  Future<bool> checkEmailExists(String email) async {
    if (email.trim().isEmpty) return false;
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'checkEmailExists',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'email': email.trim(),
      });
      return result.data['exists'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unavailable') {
        logger.w('Cloud Function unavailable: ${e.message}');
        return false; // Assume email doesn't exist if service is down, or handle as needed
      }
      logger.e('Cloud Function error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return false;
    try {
      // Use Cloud Function to check existence securely (bypassing Firestore rules)
      final callable = _functions.httpsCallable('checkPhoneExists');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber.trim(),
      });
      return result.data['exists'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unavailable') {
        logger.w('checkPhoneExists Cloud Function unavailable: ${e.message}');
        return false; // Fallback to allowing flow, Auth will catch duplicates
      }
      logger.e('Cloud Function error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      logger.e('Error checking phone existence', error: e);
      return false;
    }
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e, s) {
      logger.e('signInWithEmail Error', error: e, stackTrace: s);
      return e.message;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // Sign in with Google using authenticate - throws exception if canceled
      final googleUser = await _googleSignIn.authenticate();

      // Get authentication details from the account
      final googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Check if this Google email already exists using Cloud Function (bypasses permission issues)
      final email = googleUser.email;
      final exists = await checkEmailExists(email);

      if (exists) {
        // User exists - sign in
        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );
        final newUser = userCredential.user;

        if (newUser != null) {
          await _createOrUpdateUserDocument(newUser);
        }
        return null;
      } else {
        // New Google user - store credential and return special error code
        _googleCredential = credential;
        return "USER_NOT_FOUND";
      }
    } on FirebaseAuthException catch (e, s) {
      logger.e('Firebase Google Sign-In Error', error: e, stackTrace: s);
      return e.message;
    } catch (e, s) {
      logger.e('Unexpected Google Sign-In Error', error: e, stackTrace: s);
      // Check if it was canceled by user
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        return "Google Sign-In was canceled by the user.";
      }
      return "An unexpected error occurred.";
    }
  }

  // Find user by email in Firestore
  Future<DocumentSnapshot?> _findUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      logger.e('Error finding user by email', error: e);
      return null;
    }
  }

  // Find user by phone number in Firestore
  Future<DocumentSnapshot?> _findUserByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      logger.e('Error finding user by phone', error: e);
      return null;
    }
  }

  // Merge two user accounts (from old UID to new UID)
  Future<void> _mergeUserAccounts(String oldUid, String newUid) async {
    try {
      final oldUserDoc = await _firestore.collection('users').doc(oldUid).get();
      final newUserDoc = await _firestore.collection('users').doc(newUid).get();

      if (oldUserDoc.exists) {
        final oldData = oldUserDoc.data() ?? {};
        final newData = newUserDoc.data() ?? {};

        // Merge data - prefer old user's data for most fields
        final mergedData = {
          ...newData,
          ...oldData,
          'uid': newUid, // Keep new UID
          'mergedFrom': oldUid,
          'mergedAt': FieldValue.serverTimestamp(),
        };

        // Update new user document with merged data
        await _firestore
            .collection('users')
            .doc(newUid)
            .set(mergedData, SetOptions(merge: true));

        // Delete old user document
        await _firestore.collection('users').doc(oldUid).delete();

        logger.i('Successfully merged accounts: $oldUid -> $newUid');
      }
    } catch (e) {
      logger.e('Error merging user accounts', error: e);
    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber, // Add phone number
      'lastSignIn': FieldValue.serverTimestamp(),
    };

    if (!doc.exists) {
      logger.i('Creating new user document for ${user.uid}');
      await userRef.set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'points': 0,
        'completionPercent': 0.0,
        'grades': [],
        'appLanguage': 'en',
        'learningMedium': 'en',
        'completedContentIds': [],
        'followersCount': 0,
        'followingCount': 0,
        'role': 'user',
      });
    } else {
      // Update existing user, merge phone number if available
      final Map<String, dynamic> updateData = {...userData};
      // Don't overwrite phone number if it's already set
      final existingData = doc.data();
      if (existingData?['phoneNumber'] != null && user.phoneNumber == null) {
        updateData.remove('phoneNumber');
      }
      await userRef.update(updateData);
    }
  }

  // --- Phone OTP Methods ---

  Future<void> sendOtpToPhone(BuildContext context, String phoneNumber) async {
    logger.i('Sending OTP to $phoneNumber');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          logger.i('Phone verification completed automatically');
          await _firebaseAuth.signInWithCredential(credential);
          if (context.mounted) Navigator.of(context).pop();
        },
        verificationFailed: (FirebaseAuthException e) {
          logger.e('Phone Verification Failed', error: e);
          if (context.mounted) Navigator.of(context).pop();
          throw Exception(e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          logger.i('Phone code sent, verificationId stored.');
          _verificationId = verificationId; // <-- STORE THE ID
          if (context.mounted) Navigator.of(context).pop();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          logger.w('Phone auto-retrieval timed out');
          _verificationId = verificationId;
        },
      );
    } catch (e, s) {
      logger.e('Error in sendOtpToPhone', error: e, stackTrace: s);
      if (context.mounted) Navigator.of(context).pop();
      throw Exception('Failed to send OTP. Please try again.');
    }
  }

  Future<String?> signInWithPhoneOtp(String smsCode) async {
    if (_verificationId == null) {
      return 'Verification session expired. Please resend the code.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      await _firebaseAuth.signInWithCredential(credential);
      _verificationId = null;
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUpWithEmailPasswordAndLinkPhone({
    required String email,
    required String password,
    required String smsCode,
  }) async {
    if (_verificationId == null) {
      return 'Verification session expired. Please resend the code.';
    }

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = userCredential.user;
      if (newUser == null) {
        return 'Failed to create user account.';
      }

      await newUser.linkWithCredential(credential);

      await _firestore.collection('users').doc(newUser.uid).set({
        'uid': newUser.uid,
        'email': newUser.email,
        'phoneNumber': newUser.phoneNumber,
        'role': 'user',
        'lastSignIn': FieldValue.serverTimestamp(),
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
        'points': 0,
        'completionPercent': 0.0,
        'grades': [],
        'completedContentIds': [],
        'followersCount': 0,
        'followingCount': 0,
      }, SetOptions(merge: true));

      _verificationId = null;
      return null; // Success!
    } on FirebaseAuthException catch (e, s) {
      logger.e('Error during sign up and link', error: e, stackTrace: s);
      if (e.code == 'email-already-in-use') {
        return 'This email is already in use. Please log in.';
      }
      if (e.code == 'credential-already-in-use') {
        return 'This phone number is already linked to another account.';
      }
      if (e.code == 'invalid-verification-code') {
        return 'The OTP code is invalid. Please try again.';
      }
      return e.message ?? 'An unknown authentication error occurred.';
    } catch (e, s) {
      logger.e('Unexpected error during sign up', error: e, stackTrace: s);
      return 'An unexpected error occurred.';
    }
  }

  // --- Custom Business Logic ---

  Future<void> awardPoints(int pointsToAdd) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      await userRef.update({'points': FieldValue.increment(pointsToAdd)});
      logger.i('Awarded $pointsToAdd points to ${user.uid}');
    } catch (e) {
      logger.e('Failed to award points', error: e);
    }
  }

  Future<void> markContentAsCompleted(String contentId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      await userRef.update({
        'completedContentIds': FieldValue.arrayUnion([contentId]),
      });
      logger.i('Marked content $contentId as complete for ${user.uid}');
    } catch (e) {
      logger.e('Failed to mark content as completed', error: e);
    }
  }

  // --- Social Logic (Cloud Function Calls) ---

  // 🚀 FIX 1: followUser
  Future<String?> followUser(String userIdToFollow) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return "You must be logged in.";

    try {
      final callable = _functions.httpsCallable('followUser');
      final result = await callable.call<Map<String, dynamic>>({
        'userIdToFollow': userIdToFollow,
      });

      if (result.data['success'] == true) {
        // Send Notification
        await SocialService().sendNotification(
          toUserId: userIdToFollow,
          title: 'New Follower',
          message: '${user.displayName} started following you.',
          type: 'newFollower',
          senderId: user.uid,
          senderName: user.displayName,
          senderPhotoUrl: user.photoURL,
        );
        return null;
      } else {
        return result.data['error'] ?? 'An unknown error occurred.';
      }
    } on FirebaseFunctionsException catch (e) {
      logger.e('Cloud Function error (followUser): ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // 🚀 FIX 2: unfollowUser
  Future<String?> unfollowUser(String userIdToUnfollow) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return "You must be logged in.";

    try {
      final callable = _functions.httpsCallable('unfollowUser');
      final result = await callable.call<Map<String, dynamic>>({
        'userIdToUnfollow': userIdToUnfollow,
      });
      return (result.data['success'] == true)
          ? null
          : (result.data['error'] ?? 'An unknown error occurred.');
    } on FirebaseFunctionsException catch (e) {
      logger.e('Cloud Function error (unfollowUser): ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> likePost(
    String postId,
    String targetUserId,
    bool isCurrentlyLiked,
  ) async {
    // ... (Your existing likePost logic) ...
    final user = _firebaseAuth.currentUser;
    if (user == null) return "You must be logged in.";

    try {
      final callable = _functions.httpsCallable('likePost');
      final result = await callable.call<Map<String, dynamic>>({
        'postId': postId,
        'unlike': isCurrentlyLiked,
      });

      if (result.data['success'] == true) {
        // Send Notification if Liking (not unliking)
        if (!isCurrentlyLiked) {
          await SocialService().sendNotification(
            toUserId: targetUserId,
            title: 'New Like',
            message: '${user.displayName} liked your post.',
            type: 'postLike',
            senderId: user.uid,
            senderName: user.displayName,
            senderPhotoUrl: user.photoURL,
            targetContentId: postId,
          );
        }
        return null;
      } else {
        return result.data['error'] ?? 'An unknown error occurred.';
      }
    } on FirebaseFunctionsException catch (e) {
      logger.e('Cloud Function error (likePost): ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> likeReply(
    String postId,
    String replyId,
    String targetUserId,
    bool isCurrentlyLiked,
  ) async {
    // ... (Your existing likeReply logic) ...
    final user = _firebaseAuth.currentUser;
    if (user == null) return "You must be logged in.";

    try {
      final callable = _functions.httpsCallable('likeReply');
      final result = await callable.call<Map<String, dynamic>>({
        'postId': postId,
        'replyId': replyId,
        'unlike': isCurrentlyLiked,
      });

      if (result.data['success'] == true) {
        // Send Notification if Liking
        if (!isCurrentlyLiked) {
          await SocialService().sendNotification(
            toUserId: targetUserId,
            title: 'New Like',
            message: '${user.displayName} liked your comment.',
            type: 'postLike', // Or postReplyLike? Generic postLike is fine.
            senderId: user.uid,
            senderName: user.displayName,
            senderPhotoUrl: user.photoURL,
            targetContentId: postId, // Navigate to post
          );
        }
        return null;
      } else {
        return result.data['error'] ?? 'An unknown error occurred.';
      }
    } on FirebaseFunctionsException catch (e) {
      logger.e('Cloud Function error (likeReply): ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> signUpWithGoogleAndPhone({required String smsCode}) async {
    if (_googleCredential == null) {
      return 'Google authentication session expired. Please try again.';
    }
    if (_verificationId == null) {
      return 'Verification session expired. Please resend the code.';
    }

    try {
      final PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      // 1. Sign in with Google first
      final userCredential = await _firebaseAuth.signInWithCredential(
        _googleCredential!,
      );
      final user = userCredential.user;

      if (user == null) {
        return 'Failed to sign in with Google.';
      }

      // 2. Link with phone
      await user.linkWithCredential(phoneCredential);

      // 3. Create user document
      await _createOrUpdateUserDocument(user);

      _googleCredential = null;
      _verificationId = null;
      return null; // Success!
    } on FirebaseAuthException catch (e, s) {
      logger.e('Error during Google-Phone link', error: e, stackTrace: s);
      if (e.code == 'credential-already-in-use') {
        return 'This phone number is already linked to another account.';
      }
      if (e.code == 'invalid-verification-code') {
        return 'The OTP code is invalid. Please try again.';
      }
      return e.message ?? 'An unknown authentication error occurred.';
    } catch (e, s) {
      logger.e('Unexpected error during sign up', error: e, stackTrace: s);
      return 'An unexpected error occurred.';
    }
  }

  // --- Sign Out ---

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      logger.i('User signed out successfully');
    } catch (e, s) {
      logger.e('Error signing out', error: e, stackTrace: s);
    }
  }
}
