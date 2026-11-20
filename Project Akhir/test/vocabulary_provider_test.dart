import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voca/core/constants/seed_words.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:voca/shared/models/result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';
import 'package:voca/shared/services/contracts.dart';

/// Sumber data palsu agar test tidak butuh internet.
class _FakeSource implements VocabularySource {
  _FakeSource(this._handler);

  final Future<Result<VocabularyEntry>> Function(String word) _handler;
  final List<String> calls = [];

  @override
  Future<Result<VocabularyEntry>> fetchWord(String word) {
    calls.add(word);
    return _handler(word);
  }
}

VocabularyEntry _entry(String word) => VocabularyEntry(
      word: word,
      meanings: [
        WordMeaning(partOfSpeech: 'noun', definition: 'definisi $word'),
      ],
    );

void main() {
  group('search', () {
    test('berhasil: status success dan hasil terisi', () async {
      final source = _FakeSource(
        (w) async => Success<VocabularyEntry>(_entry(w)),
      );
      final provider = VocabularyProvider(source);

      await provider.search('  Candid ');

      expect(provider.searchStatus, LoadStatus.success);
      expect(provider.searchResult?.word, 'candid');
      expect(provider.query, 'Candid');
      expect(source.calls, ['candid']);
    });

    test('gagal: status error, pesan dari service, hasil kosong', () async {
      final source = _FakeSource(
        (w) async => Failure<VocabularyEntry>('Kata "$w" tidak ditemukan.'),
      );
      final provider = VocabularyProvider(source);

      await provider.search('zzzz');

      expect(provider.searchStatus, LoadStatus.error);
      expect(provider.searchError, contains('tidak ditemukan'));
      expect(provider.searchResult, isNull);
    });

    test('input kosong kembali ke idle tanpa memanggil API', () async {
      final source = _FakeSource(
        (w) async => Success<VocabularyEntry>(_entry(w)),
      );
      final provider = VocabularyProvider(source);

      await provider.search('   ');

      expect(provider.searchStatus, LoadStatus.idle);
      expect(source.calls, isEmpty);
    });

    test('kata yang sama dicari dua kali hanya memanggil API sekali', () async {
      final source = _FakeSource(
        (w) async => Success<VocabularyEntry>(_entry(w)),
      );
      final provider = VocabularyProvider(source);

      await provider.search('vivid');
      await provider.search('vivid');

      expect(source.calls.length, 1);
    });

    test('hasil pencarian lama tidak menimpa pencarian yang lebih baru',
        () async {
      final slow = Completer<Result<VocabularyEntry>>();
      final source = _FakeSource(
        (w) => w == 'slow'
            ? slow.future
            : Future<Result<VocabularyEntry>>.value(
                Success<VocabularyEntry>(_entry(w)),
              ),
      );
      final provider = VocabularyProvider(source);

      final slowSearch = provider.search('slow');
      await provider.search('fast');
      slow.complete(Success<VocabularyEntry>(_entry('slow')));
      await slowSearch;

      expect(provider.searchResult?.word, 'fast');
    });
  });

  group('detail', () {
    test('berhasil memuat detail', () async {
      final source = _FakeSource(
        (w) async => Success<VocabularyEntry>(_entry(w)),
      );
      final provider = VocabularyProvider(source);

      await provider.loadDetail('Resilient');

      expect(provider.detailStatus, LoadStatus.success);
      expect(provider.detailEntry?.word, 'resilient');
    });

    test('gagal memuat detail menghasilkan error', () async {
      final source = _FakeSource(
        (w) async => Failure<VocabularyEntry>('Tidak ada koneksi internet.'),
      );
      final provider = VocabularyProvider(source);

      await provider.loadDetail('resilient');

      expect(provider.detailStatus, LoadStatus.error);
      expect(provider.detailError, contains('internet'));
    });
  });

  group('daily vocabulary', () {
    test('kata dipilih dari kSeedWords berdasarkan tanggal', () async {
      final source = _FakeSource(
        (w) async => Success<VocabularyEntry>(_entry(w)),
      );

      final day0 = VocabularyProvider(source, now: () => DateTime(2026, 1, 1));
      await day0.loadDaily();
      expect(day0.dailyWord, kSeedWords[0]);
      expect(day0.dailyStatus, LoadStatus.success);

      final day1 = VocabularyProvider(source, now: () => DateTime(2026, 1, 2));
      await day1.loadDaily();
      expect(day1.dailyWord, kSeedWords[1]);
    });

    test('gagal lalu retry berhasil', () async {
      var attempt = 0;
      final source = _FakeSource((w) async {
        attempt++;
        return attempt == 1
            ? Failure<VocabularyEntry>('Tidak ada koneksi internet.')
            : Success<VocabularyEntry>(_entry(w));
      });
      final provider = VocabularyProvider(source);

      await provider.loadDaily();
      expect(provider.dailyStatus, LoadStatus.error);
      expect(provider.dailyEntry, isNull);

      await provider.loadDaily(); // retry
      expect(provider.dailyStatus, LoadStatus.success);
      expect(provider.dailyEntry, isNotNull);
    });
  });
}