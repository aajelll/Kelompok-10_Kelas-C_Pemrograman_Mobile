import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/services/firestore_paths.dart';

/// Penyimpanan token FCM milik satu pengguna.
abstract interface class PushTokenStore {
  Future<void> saveToken(String uid, String token);
}

/// Lokasi: users/{uid}, field `fcmToken`. Memakai merge agar field lain di
/// dokumen yang sama (mis. pengaturan pengingat) tidak terhapus.
class FirestorePushTokenStore implements PushTokenStore {
  @override
  Future<void> saveToken(String uid, String token) =>
      FirestorePaths.user(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
}
