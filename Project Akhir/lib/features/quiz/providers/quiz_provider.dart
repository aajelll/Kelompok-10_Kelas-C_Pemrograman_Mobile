import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/constants/seed_words.dart';
import '../../../shared/models/quiz_result.dart';
import '../../../shared/models/result.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../../../shared/services/contracts.dart';
import '../models/quiz_question.dart';
import '../services/quiz_result_repository.dart';

enum QuizPhase { idle, loading, inProgress, finished, error }

enum SaveStatus { idle, saving, saved, error }

/// Mengelola satu sesi kuis: soal, jawaban, skor, dan penyimpanan hasil.
/// Skor dihitung dari daftar jawaban, bukan dari penghitung yang ditambah-
/// tambah, jadi menjawab ulang tidak bisa menghitung dua kali.
class QuizProvider extends ChangeNotifier {
  QuizProvider(
    this._source, {
    QuizResultRepository Function(String uid)? storeFactory,
    Random? random,
    DateTime Function()? now,
    this.questionCount = 5,
    this.poolSize = 8,
  })  : _storeFactory = storeFactory ?? FirestoreQuizResultRepository.new,
        _random = random ?? Random(),
        _now = now ?? DateTime.now;

  final VocabularySource _source;
  final QuizResultRepository Function(String uid) _storeFactory;
  final Random _random;
  final DateTime Function() _now;

  /// Jumlah soal per sesi dan jumlah kata yang diambil dari API sebagai bahan.
  final int questionCount;
  final int poolSize;

  /// Kata yang sudah diambil, supaya "ulangi kuis" tidak memanggil API lagi.
  final Map<String, VocabularyEntry> _cache = {};

  String? _uid;
  QuizResultRepository? _repository;

  /// Penanda sesi: hasil async dari sesi lama diabaikan.
  int _session = 0;

  QuizPhase _phase = QuizPhase.idle;
  String? _error;
  List<QuizQuestion> _questions = const [];
  List<int?> _answers = const [];
  int _currentIndex = 0;
  QuizResult? _result;
  SaveStatus _saveStatus = SaveStatus.idle;
  String? _saveError;

  QuizPhase get phase => _phase;
  String? get error => _error;
  List<QuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  QuizResult? get result => _result;
  SaveStatus get saveStatus => _saveStatus;
  String? get saveError => _saveError;

  QuizQuestion? get currentQuestion =>
      _phase == QuizPhase.inProgress ? _questions[_currentIndex] : null;

  int? get selectedIndex =>
      _answers.isEmpty ? null : _answers[_currentIndex];

  bool get isAnswered => selectedIndex != null;
  bool get isLastQuestion => _currentIndex == _questions.length - 1;

  /// Jumlah jawaban benar sejauh ini.
  int get score {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) correct++;
    }
    return correct;
  }

  /// Dipanggil saat UID berubah (login, logout, ganti akun).
  /// Tidak memanggil notifyListeners karena dijalankan saat proses build.
  void updateUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _repository = uid == null ? null : _storeFactory(uid);
    _session++;
    _clearSession();
    _phase = QuizPhase.idle;
  }

  /// Memulai sesi baru (juga dipakai untuk "ulangi kuis" dan coba lagi).
  Future<void> start() async {
    if (_phase == QuizPhase.loading) return;
    final session = ++_session;
    _clearSession();
    _phase = QuizPhase.loading;
    notifyListeners();

    final words = [...kSeedWords]..shuffle(_random);
    final results = await Future.wait(words.take(poolSize).map(_fetch));
    if (session != _session) return;

    final entries = <VocabularyEntry>[];
    for (final r in results) {
      if (r case Success<VocabularyEntry>(:final data)) entries.add(data);
    }

    final questions = buildQuizQuestions(
      entries,
      count: questionCount,
      random: _random,
    );

    if (questions.isEmpty) {
      _phase = QuizPhase.error;
      _error = 'Data kosakata belum cukup untuk membuat kuis. '
          'Periksa koneksi lalu coba lagi.';
      notifyListeners();
      return;
    }

    _questions = questions;
    _answers = List<int?>.filled(questions.length, null);
    _currentIndex = 0;
    _phase = QuizPhase.inProgress;
    notifyListeners();
  }

  /// Memilih jawaban untuk soal aktif. Hanya jawaban pertama yang dihitung.
  void select(int optionIndex) {
    if (_phase != QuizPhase.inProgress || isAnswered) return;
    if (optionIndex < 0 || optionIndex >= currentQuestion!.options.length) {
      return;
    }
    _answers[_currentIndex] = optionIndex;
    notifyListeners();
  }

  /// Lanjut ke soal berikutnya, atau menyelesaikan kuis di soal terakhir.
  /// Tidak melakukan apa pun jika soal aktif belum dijawab.
  Future<void> next() async {
    if (_phase != QuizPhase.inProgress || !isAnswered) return;
    if (!isLastQuestion) {
      _currentIndex++;
      notifyListeners();
      return;
    }
    await _finish();
  }

  /// Mencoba menyimpan ulang setelah gagal.
  Future<void> retrySave() async {
    if (_phase != QuizPhase.finished || _saveStatus != SaveStatus.error) return;
    await _save();
  }

  /// Kembali ke kondisi awal (mis. setelah pulang ke Beranda).
  void reset() {
    _session++;
    _clearSession();
    _phase = QuizPhase.idle;
    notifyListeners();
  }

  Future<void> _finish() async {
    _result = QuizResult(
      score: score,
      totalQuestions: _questions.length,
      completedAt: _now(),
    );
    _phase = QuizPhase.finished;
    _saveStatus = SaveStatus.idle;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null) return;
    if (_saveStatus == SaveStatus.saving || _saveStatus == SaveStatus.saved) {
      return;
    }

    final repository = _repository;
    if (repository == null) {
      _saveStatus = SaveStatus.error;
      _saveError = 'Silakan masuk terlebih dahulu agar hasil bisa disimpan.';
      notifyListeners();
      return;
    }

    final session = _session;
    _saveStatus = SaveStatus.saving;
    _saveError = null;
    notifyListeners();

    try {
      await repository.save(result).timeout(const Duration(seconds: 10));
      if (session != _session) return;
      _saveStatus = SaveStatus.saved;
    } catch (_) {
      if (session != _session) return;
      _saveStatus = SaveStatus.error;
      _saveError = 'Hasil belum bisa dipastikan tersimpan. '
          'Periksa koneksi lalu coba lagi.';
    }
    notifyListeners();
  }

  Future<Result<VocabularyEntry>> _fetch(String word) async {
    final cached = _cache[word];
    if (cached != null) return Success<VocabularyEntry>(cached);
    final result = await _source.fetchWord(word);
    if (result is Success<VocabularyEntry>) _cache[word] = result.data;
    return result;
  }

  void _clearSession() {
    _error = null;
    _questions = const [];
    _answers = const [];
    _currentIndex = 0;
    _result = null;
    _saveStatus = SaveStatus.idle;
    _saveError = null;
  }
}
