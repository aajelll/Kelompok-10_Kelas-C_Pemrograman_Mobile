import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaths {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      _db.collection('users').doc(uid);

  static CollectionReference<Map<String, dynamic>> favorites(String uid) =>
      user(uid).collection('favorites');      // id dokumen = kata (huruf kecil)

  static CollectionReference<Map<String, dynamic>> quizResults(String uid) =>
      user(uid).collection('quizResults');    // id dokumen = otomatis
}