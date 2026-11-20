import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/vocabulary_entry.dart';
import '../services/favorites_store.dart';
import 'vocabulary_provider.dart' show LoadStatus;

/// Daftar favorit milik pengguna yang sedang login.
/// UID diisi lewat [updateUser] (dipanggil ChangeNotifierProxyProvider).
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesStore Function(String uid)? storeFactory})
      : _storeFactory = storeFactory ?? FirestoreFavoritesStore.new;

  final FavoritesStore Function(String uid) _storeFactory;

  String? _uid;
  FavoritesStore? _store;
  StreamSubscription<List<VocabularyEntry>>? _subscription;

  LoadStatus _status = LoadStatus.idle;
  List<VocabularyEntry> _items = const [];
  Set<String> _words = const {};
  String? _error;

  LoadStatus get status => _status;
  List<VocabularyEntry> get items => _items;
  String? get error => _error;
  int get count => _items.length;

  bool isFavorite(String word) => _words.contains(word.trim().toLowerCase());

  /// Dipanggil saat UID berubah (login, logout, ganti akun).
  /// Tidak memanggil notifyListeners karena dijalankan saat proses build;
  /// listener diberi tahu oleh stream begitu data akun baru tiba.
  void updateUser(String? uid) {
    if (uid == _uid) return;

    _subscription?.cancel();
    _subscription = null;
    _uid = uid;
    _store = null;
    _items = const [];
    _words = const {};
    _error = null;

    if (uid == null) {
      _status = LoadStatus.idle;
      return;
    }

    _status = LoadStatus.loading;
    final store = _storeFactory(uid);
    _store = store;
    _subscription = store.watchAll().listen(
      (list) {
        _items = [...list]..sort(
            (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
          );
        _words = _items.map((e) => e.word.trim().toLowerCase()).toSet();
        _status = LoadStatus.success;
        _error = null;
        notifyListeners();
      },
      onError: (Object _) {
        _status = LoadStatus.error;
        _error = 'Gagal memuat favorit. Periksa koneksi lalu coba lagi.';
        notifyListeners();
      },
    );
  }

  /// Memuat ulang setelah error.
  void retry() {
    final uid = _uid;
    _uid = null;
    updateUser(uid);
    notifyListeners();
  }

  /// Menambah kata ke favorit, atau menghapusnya jika sudah favorit.
  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> toggle(VocabularyEntry entry) async {
    final store = _store;
    if (store == null) return 'Silakan masuk terlebih dahulu.';
    try {
      if (isFavorite(entry.word)) {
        await store.remove(entry.word);
      } else {
        await store.add(entry);
      }
      return null;
    } catch (_) {
      return 'Gagal memperbarui favorit. Periksa koneksi lalu coba lagi.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}