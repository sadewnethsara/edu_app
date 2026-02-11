import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @chooseYourAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your App Language'**
  String get chooseYourAppLanguage;

  /// No description provided for @languagePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language for the app interface and content.'**
  String get languagePageSubtitle;

  /// No description provided for @pleaseSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select an app language to continue.'**
  String get pleaseSelectLanguage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @learningPreferences.
  ///
  /// In en, this message translates to:
  /// **'Learning Preferences'**
  String get learningPreferences;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @saveAllChanges.
  ///
  /// In en, this message translates to:
  /// **'Save All Changes'**
  String get saveAllChanges;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @selectAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select App Language'**
  String get selectAppLanguage;

  /// No description provided for @learningMedium.
  ///
  /// In en, this message translates to:
  /// **'Learning Medium'**
  String get learningMedium;

  /// No description provided for @selectLearningMedium.
  ///
  /// In en, this message translates to:
  /// **'Select Learning Medium'**
  String get selectLearningMedium;

  /// No description provided for @yourGrades.
  ///
  /// In en, this message translates to:
  /// **'Your Grades'**
  String get yourGrades;

  /// No description provided for @noGradesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No grades available'**
  String get noGradesAvailable;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully!'**
  String get settingsSavedSuccessfully;

  /// No description provided for @failedToSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get failedToSaveSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @pastPapers.
  ///
  /// In en, this message translates to:
  /// **'Past Papers'**
  String get pastPapers;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get signInWithEmail;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @yourLearningJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Learning Journey'**
  String get yourLearningJourney;

  /// No description provided for @continueWhere.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get continueWhere;

  /// No description provided for @exploreSubjects.
  ///
  /// In en, this message translates to:
  /// **'Explore Subjects'**
  String get exploreSubjects;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dailyStreak;

  /// No description provided for @daysStreak.
  ///
  /// In en, this message translates to:
  /// **'days streak'**
  String get daysStreak;

  /// No description provided for @keepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get keepItUp;

  /// No description provided for @allSubjects.
  ///
  /// In en, this message translates to:
  /// **'All Subjects'**
  String get allSubjects;

  /// No description provided for @noSubjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subjects available'**
  String get noSubjectsAvailable;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select a subject to start learning'**
  String get selectSubject;

  /// No description provided for @mathematics.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get mathematics;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @allLessons.
  ///
  /// In en, this message translates to:
  /// **'All Lessons'**
  String get allLessons;

  /// No description provided for @noLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lessons available'**
  String get noLessonsAvailable;

  /// No description provided for @lessonContent.
  ///
  /// In en, this message translates to:
  /// **'Lesson Content'**
  String get lessonContent;

  /// No description provided for @startLesson.
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get startLesson;

  /// No description provided for @continueLesson.
  ///
  /// In en, this message translates to:
  /// **'Continue Lesson'**
  String get continueLesson;

  /// No description provided for @completedLessons.
  ///
  /// In en, this message translates to:
  /// **'Completed Lessons'**
  String get completedLessons;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @subtopics.
  ///
  /// In en, this message translates to:
  /// **'Subtopics'**
  String get subtopics;

  /// No description provided for @noSubtopicsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subtopics available'**
  String get noSubtopicsAvailable;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @pdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get pdfs;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available'**
  String get noVideosAvailable;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available'**
  String get noNotesAvailable;

  /// No description provided for @noPdfsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No PDFs available'**
  String get noPdfsAvailable;

  /// No description provided for @noResourcesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No resources available'**
  String get noResourcesAvailable;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play Video'**
  String get playVideo;

  /// No description provided for @openNote.
  ///
  /// In en, this message translates to:
  /// **'Open Note'**
  String get openNote;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @openInExternalApp.
  ///
  /// In en, this message translates to:
  /// **'Open in External App'**
  String get openInExternalApp;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @videoPlayer.
  ///
  /// In en, this message translates to:
  /// **'Video Player'**
  String get videoPlayer;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// No description provided for @downloadFeatureNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Download feature not yet implemented.'**
  String get downloadFeatureNotImplemented;

  /// No description provided for @searchPastPapers.
  ///
  /// In en, this message translates to:
  /// **'Search Past Papers'**
  String get searchPastPapers;

  /// No description provided for @noPastPapersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No past papers available'**
  String get noPastPapersAvailable;

  /// No description provided for @filterByYear.
  ///
  /// In en, this message translates to:
  /// **'Filter by Year'**
  String get filterByYear;

  /// No description provided for @filterBySubject.
  ///
  /// In en, this message translates to:
  /// **'Filter by Subject'**
  String get filterBySubject;

  /// No description provided for @filterByGrade.
  ///
  /// In en, this message translates to:
  /// **'Filter by Grade'**
  String get filterByGrade;

  /// No description provided for @allYears.
  ///
  /// In en, this message translates to:
  /// **'All Years'**
  String get allYears;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @term.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get term;

  /// No description provided for @viewPaper.
  ///
  /// In en, this message translates to:
  /// **'View Paper'**
  String get viewPaper;

  /// No description provided for @viewAnswers.
  ///
  /// In en, this message translates to:
  /// **'View Answers'**
  String get viewAnswers;

  /// No description provided for @answers.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get answers;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfo;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @noAchievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get noAchievements;

  /// No description provided for @topPerformers.
  ///
  /// In en, this message translates to:
  /// **'Top Performers'**
  String get topPerformers;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @noLeaderboardData.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data available'**
  String get noLeaderboardData;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeTheme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @selectYourGrades.
  ///
  /// In en, this message translates to:
  /// **'Select Your Grades'**
  String get selectYourGrades;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection'**
  String get checkConnection;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @nothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here'**
  String get nothingToShow;

  /// No description provided for @comeBackLater.
  ///
  /// In en, this message translates to:
  /// **'Come back later for updates'**
  String get comeBackLater;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring!'**
  String get startExploring;

  /// No description provided for @errorCouldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not load video.'**
  String get errorCouldNotLoadVideo;

  /// No description provided for @videoCouldNotBePlayed.
  ///
  /// In en, this message translates to:
  /// **'Video could not be played'**
  String get videoCouldNotBePlayed;

  /// No description provided for @untitledVideo.
  ///
  /// In en, this message translates to:
  /// **'Untitled Video'**
  String get untitledVideo;

  /// No description provided for @downloadVideoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download Video'**
  String get downloadVideoTooltip;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @failedToLoadPdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF. Please try again.'**
  String get failedToLoadPdf;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @markedAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as completed.'**
  String markedAsCompleted(String name);

  /// No description provided for @failedToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content. Please try again.'**
  String get failedToLoadContent;

  /// No description provided for @streakDialog.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakDialog;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @keepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning every day!'**
  String get keepLearning;

  /// No description provided for @allYourLessons.
  ///
  /// In en, this message translates to:
  /// **'All Your Lessons'**
  String get allYourLessons;

  /// No description provided for @organizedByGrade.
  ///
  /// In en, this message translates to:
  /// **'Organized by grade and subject'**
  String get organizedByGrade;

  /// No description provided for @tapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand and view lessons'**
  String get tapToExpand;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
