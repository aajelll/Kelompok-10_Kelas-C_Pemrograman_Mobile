import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/services/firestore_paths.dart';

/// Penyimpanan profil pengguna (nama dan email).
abstract interface class UserProfileStore {
  Future<void> save(
    String uid, {
    required String displayName,
    required String email,
  });
}

/// Lokasi: users/{uid}, field displayName dan email. Memakai merge agar field
/// lain di dokumen yang sama (token, pengaturan pengingat) tidak terhapus.
class FirestoreUserProfileStore implements UserProfileStore {
  @override
  Future<void> save(
    String uid, {
    required String displayName,
    required String email,
  }) =>
      FirestorePaths.user(uid).set(
        {'displayName': displayName, 'email': email},
        SetOptions(merge: true),
      );
}