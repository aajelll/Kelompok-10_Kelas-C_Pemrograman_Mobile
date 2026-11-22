import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/quiz_result.dart';
import '../../quiz/services/quiz_result_repository.dart';
import '../../vocabulary/providers/vocabulary_provider.dart' show LoadStatus;

/// Riwayat dan statistik kuis milik pengguna yang sedang login.
/// UID diisi lewat [updateUser] (dipanggil ChangeNotifierProxyProvider).
class ProgressProvider extends ChangeNotifier {
  ProgressProvider({
    QuizResultRepository Function(String uid)? repositoryFactory,
    this.maxHistory = 10,
  }) : _repositoryFactory =
            repositoryFactory ?? FirestoreQuizResultRepository.new;

  final QuizResultRepository Function(String uid) _repositoryFactory;

  /// Jumlah item yang ditampilkan di riwayat.
  final int maxHistory;

  String? _uid;
  StreamSubscription<List<QuizResult>>? _subscription;

  LoadStatus _status = LoadStatus.idle;
  List<QuizResult> _results = const [];
  String? _error;

  LoadStatus get status => _status;
  String? get error => _error;

  /// Jumlah seluruh kuis yang pernah diselesaikan.
  int get completedCount => _results.length;

  /// Hasil kuis paling baru, atau null jika belum pernah kuis.
  QuizResult? get lastResult => _results.isEmpty ? null : _results.first;

  /// Riwayat terbaru (paling baru di atas), dibatasi [maxHistory].
  List<QuizResult> get recent => _results.take(maxHistory).toList();

  /// Dipanggil saat UID berubah (login, logout, ganti akun).
  /// Langganan lama dibatalkan, jadi data akun lain tidak bisa bocor.
  /// Tidak memanggil notifyListeners karena dijalankan saat proses build;
  /// listener diberi tahu oleh stream begitu data akun baru tiba.
  void updateUser(String? uid) {
    if (uid == _uid) return;

    _subscription?.cancel();
    _subscription = null;
    _uid = uid;
    _results = const [];
    _error = null;

    if (uid == null) {
      _status = LoadStatus.idle;
      return;
    }

    _status = LoadStatus.loading;
    _subscription = _repositoryFactory(uid).watchAll().listen(
      (list) {
        _results = [...list]
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        _status = LoadStatus.success;
        _error = null;
        notifyListeners();
      },
      onError: (Object _) {
        _status = LoadStatus.error;
        _error = 'Gagal memuat riwayat kuis. Periksa koneksi lalu coba lagi.';
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
