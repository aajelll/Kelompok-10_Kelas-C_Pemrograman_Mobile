import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:voca/features/vocabulary/services/dictionary_api_service.dart';
import 'package:voca/shared/models/result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';
import 'package:voca/shared/services/contracts.dart';

class _FixedSource implements VocabularySource {
  _FixedSource(this._result);

  final Result<VocabularyEntry> _result;

  @override
  Future<Result<VocabularyEntry>> fetchWord(String word) async => _result;
}

void main() {
  test('belum mencari: bukan "tidak ditemukan"', () {
    final provider = VocabularyProvider(
      _FixedSource(Failure<VocabularyEntry>('x')),
    );

    expect(provider.searchNotFound, isFalse);
  });

  test('kata tidak ada di kamus: searchNotFound true', () async {
    final provider = VocabularyProvider(_FixedSource(
      Failure<VocabularyEntry>('Kata "zzzz" tidak ditemukan.'),
    ));

    await provider.search('zzzz');

    expect(provider.searchNotFound, isTrue);
  });

  test('gangguan jaringan: searchNotFound false', () async {
    final provider = VocabularyProvider(_FixedSource(
      Failure<VocabularyEntry>('Tidak ada koneksi internet.'),
    ));

    await provider.search('candid');

    expect(provider.searchStatus, LoadStatus.error);
    expect(provider.searchNotFound, isFalse);
  });

  test('respons 404 dari service dikenali sebagai tidak ditemukan', () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => http.Response('{}', 404)),
    );
    final provider = VocabularyProvider(service);

    await provider.search('asdfghjkl');

    expect(provider.searchNotFound, isTrue);
  });
}