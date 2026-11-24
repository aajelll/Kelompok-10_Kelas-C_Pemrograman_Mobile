import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import '../services/push_token_store.dart';

/// Mengelola izin notifikasi dan token FCM milik pengguna yang login.
/// UID diisi lewat [updateUser] (dipanggil ChangeNotifierProxyProvider).
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(
    this._service, {
    PushTokenStore? tokenStore,
    void Function(String target)? onNavigate,
  })  : _tokenStore = tokenStore ?? FirestorePushTokenStore(),
        _onNavigate = onNavigate;

  final NotificationService _service;
  final PushTokenStore _tokenStore;
  final void Function(String target)? _onNavigate;

  String? _uid;
  int _session = 0;
  Future<void>? _initFuture;
  StreamSubscription<String>? _refreshSub;

  NotificationPermission _permission = NotificationPermission.unknown;
  String? _token;
  String? _error;

  NotificationPermission get permission => _permission;
  String? get token => _token;
  String? get error => _error;

  /// Dipanggil saat UID berubah (login, logout, ganti akun).
  /// Tidak memanggil notifyListeners secara langsung karena dijalankan saat
  /// proses build; pembaruan state datang dari proses asinkron di bawah.
  void updateUser(String? uid) {
    if (uid == _uid) return;

    final wasLoggedIn = _uid != null;
    _uid = uid;
    final session = ++_session;
    _refreshSub?.cancel();
    _refreshSub = null;
    _token = null;
    _error = null;

    // Token milik perangkat dibatalkan saat keluar atau ganti akun, supaya
    // pesan akun lama tidak masuk ke sesi akun lain di perangkat yang sama.
    final cleanup = wasLoggedIn ? _deleteTokenQuietly() : null;

    if (uid != null) unawaited(_setup(uid, session, cleanup));
  }

  Future<void> _setup(String uid, int session, Future<void>? cleanup) async {
    try {
      await cleanup;
      await _ensureInit();
      final permission = await _service.requestPermission();
      if (session != _session) return;
      _permission = permission;
      notifyListeners();
      if (permission != NotificationPermission.granted) return;

      final token = await _service.getToken();
      if (session != _session || token == null) return;
      await _tokenStore.saveToken(uid, token);
      if (session != _session) return;

      _token = token;
      _error = null;
      if (kDebugMode) debugPrint('FCM token: $token');
      _refreshSub = _service.onTokenRefresh
          .listen((t) => unawaited(_saveRefreshed(uid, t, session)));
      notifyListeners();
    } catch (_) {
      if (session != _session) return;
      _error = 'Gagal menyiapkan notifikasi. Periksa koneksi lalu coba lagi.';
      notifyListeners();
    }
  }

  Future<void> _saveRefreshed(String uid, String token, int session) async {
    if (session != _session) return;
    try {
      await _tokenStore.saveToken(uid, token);
      if (session != _session) return;
      _token = token;
      notifyListeners();
    } catch (_) {
      // Gagal menyimpan token baru; akan dicoba lagi saat login berikutnya.
    }
  }

  Future<void> _ensureInit() async {
    final pending = _initFuture ??= _service.init(onTarget: _handleTarget);
    try {
      await pending;
    } catch (_) {
      _initFuture = null; // izinkan percobaan ulang
      rethrow;
    }
  }

  Future<void> _deleteTokenQuietly() async {
    try {
      await _service.deleteToken();
    } catch (_) {
      // Penghapusan token hanya upaya terbaik.
    }
  }

  /// Notifikasi diketuk. Hanya diproses saat pengguna login.
  void _handleTarget(String? target) {
    final t = target;
    if (t == null || t != kQuizTarget || _uid == null) return;
    _onNavigate?.call(t);
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }
}
