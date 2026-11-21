import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Status login pengguna. Sumber UID untuk seluruh fitur (Favorites, Kuis).
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _user = _auth.currentUser;
    // userChanges: ikut memancar saat login, logout, dan perubahan profil.
    _subscription = _auth.userChanges().listen((user) {
      _user = user;
      _initialized = true;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;

  User? _user;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get uid => _user?.uid;
  bool get isLoggedIn => _user != null;

  /// False sampai Firebase melaporkan status login pertama kali.
  bool get initialized => _initialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get displayName {
    final name = _user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return _user?.email?.split('@').first ?? '';
  }

  String get email => _user?.email ?? '';

  Future<bool> login(String email, String password) => _run(() async {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  Future<bool> register(String name, String email, String password) =>
      _run(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await credential.user?.updateDisplayName(name.trim());
        await credential.user?.reload();
        _user = _auth.currentUser;
      });

  Future<void> logout() => _auth.signOut();

  /// Menjalankan aksi auth: mengatur loading dan menerjemahkan error.
  /// Mengembalikan true jika berhasil.
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageFor(e);
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'operation-not-allowed':
        return 'Login email belum diaktifkan di Firebase Console.';
      default:
        return 'Gagal (${e.code}). Coba lagi.';
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}