import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../shared/models/result.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../../../shared/services/contracts.dart';

/// Potongan pesan untuk kata yang tidak ada di kamus. Dipakai Provider agar
/// "tidak ditemukan" bisa dibedakan dari gangguan jaringan.
const String kWordNotFoundMarker = 'tidak ditemukan';

/// Implementasi [VocabularySource] memakai Free Dictionary API.
/// https://dictionaryapi.dev/
class DictionaryApiService implements VocabularySource {
  /// [client] bisa diisi saat testing; kalau kosong dipakai client asli.
  DictionaryApiService({http.Client? client})
      : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  static const _timeout = Duration(seconds: 10);

  /// Batas definisi per jenis kata, supaya data arti tidak terlalu panjang.
  static const _maxDefinitionsPerMeaning = 2;

  /// Batas contoh kalimat dan sinonim yang ditampilkan.
  static const _maxExamples = 3;
  static const _maxSynonyms = 3;

  final http.Client _client;

  @override
  Future<Result<VocabularyEntry>> fetchWord(String word) async {
    final query = word.trim().toLowerCase();
    if (query.isEmpty) {
      return Failure<VocabularyEntry>('Kata tidak boleh kosong.');
    }

    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/${Uri.encodeComponent(query)}'))
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return Failure<VocabularyEntry>('Kata "$query" $kWordNotFoundMarker.');
      }
      if (response.statusCode != 200) {
        return Failure<VocabularyEntry>(
          'Server kamus bermasalah (kode ${response.statusCode}). '
          'Coba lagi nanti.',
        );
      }

      // bodyBytes + utf8: simbol fonetik (IPA) aman terbaca.
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final entry = _parse(query, json);
      if (entry == null) {
        return Failure<VocabularyEntry>(
          'Data untuk kata "$query" tidak lengkap.',
        );
      }
      return Success<VocabularyEntry>(entry);
    } on TimeoutException {
      return Failure<VocabularyEntry>(
        'Koneksi terlalu lama. Periksa internet lalu coba lagi.',
      );
    } on SocketException {
      return Failure<VocabularyEntry>(
        'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
      );
    } on http.ClientException {
      return Failure<VocabularyEntry>(
        'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.',
      );
    } on FormatException {
      return Failure<VocabularyEntry>('Format data dari server tidak valid.');
    } catch (_) {
      return Failure<VocabularyEntry>('Terjadi kesalahan tak terduga.');
    }
  }

  /// Mengubah JSON API menjadi [VocabularyEntry].
  /// Mengembalikan null kalau tidak ada satu pun arti yang bisa dibaca.
  VocabularyEntry? _parse(String query, dynamic json) {
    if (json is! List || json.isEmpty) return null;

    String? word;
    String? phonetic;
    final meanings = <WordMeaning>[];
    final examples = <String>[];
    final synonyms = <String>[];

    // API bisa mengembalikan beberapa entri untuk satu kata; semuanya digabung.
    for (final item in json) {
      if (item is! Map<String, dynamic>) continue;

      word ??= _text(item['word']);
      phonetic ??= _readPhonetic(item);

      final rawMeanings = item['meanings'];
      if (rawMeanings is! List) continue;

      for (final m in rawMeanings) {
        if (m is! Map<String, dynamic>) continue;
        final partOfSpeech = _text(m['partOfSpeech']) ?? '';
        final definitions = m['definitions'];
        if (definitions is! List) continue;

        var kept = 0;
        for (final d in definitions) {
          if (d is! Map<String, dynamic>) continue;
          final definition = _text(d['definition']);
          if (definition == null) continue;

          // Contoh dan sinonim diambil dari semua definisi, bukan hanya
          // yang disimpan sebagai arti.
          final example = _text(d['example']);
          if (example != null) _addUnique(examples, example, _maxExamples);
          _addAll(synonyms, d['synonyms'], _maxSynonyms);

          if (kept < _maxDefinitionsPerMeaning) {
            kept++;
            meanings.add(WordMeaning(
              partOfSpeech: partOfSpeech,
              definition: definition,
              example: example, // sering null
            ));
          }
        }
        _addAll(synonyms, m['synonyms'], _maxSynonyms);
      }
    }

    if (meanings.isEmpty) return null;
    return VocabularyEntry(
      word: word ?? query,
      phonetic: phonetic,
      meanings: meanings,
      examples: examples,
      synonyms: synonyms,
    );
  }

  /// Phonetic bisa ada di field `phonetic` atau di dalam daftar `phonetics`.
  String? _readPhonetic(Map<String, dynamic> item) {
    final direct = _text(item['phonetic']);
    if (direct != null) return direct;

    final list = item['phonetics'];
    if (list is List) {
      for (final p in list) {
        if (p is Map<String, dynamic>) {
          final text = _text(p['text']);
          if (text != null) return text;
        }
      }
    }
    return null;
  }

  /// Menambah [value] ke [target] jika belum ada (tanpa membedakan huruf
  /// besar-kecil) dan belum mencapai [max].
  void _addUnique(List<String> target, String value, int max) {
    if (target.length >= max) return;
    final lower = value.toLowerCase();
    if (target.any((e) => e.toLowerCase() == lower)) return;
    target.add(value);
  }

  void _addAll(List<String> target, Object? values, int max) {
    if (values is! List) return;
    for (final v in values) {
      final text = _text(v);
      if (text != null) _addUnique(target, text, max);
    }
  }

  /// String tidak kosong, atau null jika bukan string / kosong.
  String? _text(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}