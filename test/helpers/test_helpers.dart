import 'package:mockito/annotations.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

@GenerateMocks([
  AuthService,
  FirebaseFirestore,
  DocumentReference,
  CollectionReference,
  QuerySnapshot,
  DocumentSnapshot,
  FirebaseStorage,
  Reference,
  UploadTask,
  TaskSnapshot,
])
void main() {}
