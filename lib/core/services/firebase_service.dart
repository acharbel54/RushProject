import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Collection references
  static CollectionReference get users => firestore.collection('users');
  static CollectionReference get donations => firestore.collection('donations');
  static CollectionReference get reservations => firestore.collection('reservations');
  static CollectionReference get notifications => firestore.collection('notifications');
  static CollectionReference get messages => firestore.collection('messages');
  static CollectionReference get conversations => firestore.collection('conversations');
}