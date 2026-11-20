import 'package:flutter/foundation.dart';

import '../../../core/constants/seed_words.dart';
import '../../../shared/models/result.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../../../shared/services/contracts.dart';

enum LoadStatus { idle, loading, success, error }

/// Mengelola data kosakata untuk layar Beranda, Cari, dan Detail.
/// Bergantung pada kontrak [VocabularySource], bukan pada API tertentu.
///
/// Catatan untuk layar: jangan panggil [loadDetail] / [loadDaily] langsung
/// di initState tanpa penundaan (pakai addPostFrameCallback), karena Provider
/// memanggil notifyListeners() secara langsung.
class VocabularyProvider extends ChangeNotifier {
  VocabularyProvider(this._source, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final VocabularySource _source;
  final DateTime Function() _now;

  /// Kata yang sudah pernah diambil, supaya tidak memanggil API berulang.
  final Map<String, VocabularyEntry> _cache = {};

  // ===== Pencarian =====
  LoadStatus _searchStatus = LoadStatus.idle;
  VocabularyEntry? _searchResult;
  String? _searchError;
  String _query = '';
  int _searchToken = 0;

  LoadStatus get searchStatus => _searchStatus;
  VocabularyEntry? get searchResult => _searchResult;
  String? get searchError => _searchError;
  String get query => _query;

  Future<void> search(String input) async {
    final query = input.trim();
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    final token = ++_searchToken;
    _query = query;
    _searchStatus = LoadStatus.loading;
    _searchResult = null;
    _searchError = null;
    notifyListeners();

    final result = await _fetch(query);
    if (token != _searchToken) return; // ada pencarian yang lebih baru

    switch (result) {
      case Success<VocabularyEntry>(:final data):
        _searchStatus = LoadStatus.success;
        _searchResult = data;
      case Failure<VocabularyEntry>(:final message):
        _searchStatus = LoadStatus.error;
        _searchError = message;
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchToken++;
    _query = '';
    _searchStatus = LoadStatus.idle;
    _searchResult = null;
    _searchError = null;
    notifyListeners();
  }

  // ===== Detail =====
  LoadStatus _detailStatus = LoadStatus.idle;
  VocabularyEntry? _detailEntry;
  String? _detailError;
  int _detailToken = 0;

  LoadStatus get detailStatus => _detailStatus;
  VocabularyEntry? get detailEntry => _detailEntry;
  String? get detailError => _detailError;

  Future<void> loadDetail(String word) async {
    final token = ++_detailToken;
    _detailStatus = LoadStatus.loading;
    _detailEntry = null;
    _detailError = null;
    notifyListeners();

    final result = await _fetch(word);
    if (token != _detailToken) return;

    switch (result) {
      case Success<VocabularyEntry>(:final data):
        _detailStatus = LoadStatus.success;
        _detailEntry = data;
      case Failure<VocabularyEntry>(:final message):
        _detailStatus = LoadStatus.error;
        _detailError = message;
    }
    notifyListeners();
  }

  // ===== Daily Vocabulary =====
  LoadStatus _dailyStatus = LoadStatus.idle;
  VocabularyEntry? _dailyEntry;
  String? _dailyError;
  String _dailyWord = '';

  LoadStatus get dailyStatus => _dailyStatus;
  VocabularyEntry? get dailyEntry => _dailyEntry;
  String? get dailyError => _dailyError;
  String get dailyWord => _dailyWord;

  /// Kata hari ini dipilih dari [kSeedWords] berdasarkan tanggal,
  /// jadi kata yang sama muncul sepanjang hari dan berganti besok.
  /// Dipanggil lagi saat retry (setelah error).
  Future<void> loadDaily() async {
    if (_dailyStatus == LoadStatus.loading ||
        _dailyStatus == LoadStatus.success) {
      return;
    }

    _dailyWord = _pickDailyWord();
    _dailyStatus = LoadStatus.loading;
    _dailyError = null;
    notifyListeners();

    final result = await _fetch(_dailyWord);

    switch (result) {
      case Success<VocabularyEntry>(:final data):
        _dailyStatus = LoadStatus.success;
        _dailyEntry = data;
      case Failure<VocabularyEntry>(:final message):
        _dailyStatus = LoadStatus.error;
        _dailyError = message;
    }
    notifyListeners();
  }

  String _pickDailyWord() {
    final now = _now();
    // UTC supaya selisih hari selalu tepat (tidak terpengaruh jam musim panas).
    final today = DateTime.utc(now.year, now.month, now.day);
    final dayNumber = today.difference(DateTime.utc(2026)).inDays;
    return kSeedWords[dayNumber % kSeedWords.length];
  }

  // ===== Umum =====
  Future<Result<VocabularyEntry>> _fetch(String word) async {
    final key = word.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null) return Success<VocabularyEntry>(cached);

    final result = await _source.fetchWord(key);
    if (result is Success<VocabularyEntry>) {
      _cache[key] = result.data;
    }
    return result;
  }
}