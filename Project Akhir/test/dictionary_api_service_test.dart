import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voca/features/vocabulary/services/dictionary_api_service.dart';
import 'package:voca/shared/models/result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';

http.Response _json(String body, [int status = 200]) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

VocabularyEntry _entryOf(Result<VocabularyEntry> result) {
  expect(result, isA<Success<VocabularyEntry>>());
  return (result as Success<VocabularyEntry>).data;
}

void main() {
  test('kata valid: phonetic, arti, part of speech, dan contoh terbaca',
      () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => _json(jsonEncode([
            {
              'word': 'resilient',
              'phonetic': '/rɪˈzɪliənt/',
              'meanings': [
                {
                  'partOfSpeech': 'adjective',
                  'definitions': [
                    {
                      'definition': 'Able to recover quickly.',
                      'example': 'She is a resilient person.'
                    },
                    {'definition': 'Flexible.'},
                  ],
                },
              ],
            },
          ]))),
    );

    final entry = _entryOf(await service.fetchWord('Resilient'));

    expect(entry.word, 'resilient');
    expect(entry.phonetic, '/rɪˈzɪliənt/');
    expect(entry.meanings.length, 2);
    expect(entry.meanings.first.partOfSpeech, 'adjective');
    expect(entry.meanings.first.definition, 'Able to recover quickly.');
    expect(entry.meanings.first.example, 'She is a resilient person.');
  });

  test('phonetic dan example kosong tidak membuat error', () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => _json(jsonEncode([
            {
              'word': 'candid',
              'phonetics': [
                {'text': ''}
              ],
              'meanings': [
                {
                  'partOfSpeech': 'adjective',
                  'definitions': [
                    {'definition': 'Honest.'}
                  ],
                },
              ],
            },
          ]))),
    );

    final entry = _entryOf(await service.fetchWord('candid'));

    expect(entry.phonetic, isNull);
    expect(entry.meanings.single.example, isNull);
  });

  test('phonetic diambil dari daftar phonetics jika field utama tidak ada',
      () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => _json(jsonEncode([
            {
              'word': 'vivid',
              'phonetics': [
                {'text': ''},
                {'text': '/ˈvɪvɪd/'},
              ],
              'meanings': [
                {
                  'partOfSpeech': 'adjective',
                  'definitions': [
                    {'definition': 'Producing powerful feelings.'}
                  ],
                },
              ],
            },
          ]))),
    );

    final entry = _entryOf(await service.fetchWord('vivid'));

    expect(entry.phonetic, '/ˈvɪvɪd/');
  });

  test('kata tidak ditemukan (404) menghasilkan Failure', () async {
    final service = DictionaryApiService(
      client: MockClient(
        (_) async => _json(jsonEncode({'title': 'No Definitions Found'}), 404),
      ),
    );

    final result = await service.fetchWord('asdfghjkl');

    expect(result, isA<Failure<VocabularyEntry>>());
    expect((result as Failure<VocabularyEntry>).message,
        contains('tidak ditemukan'));
  });

  test('input kosong ditolak tanpa memanggil API', () async {
    var called = false;
    final service = DictionaryApiService(
      client: MockClient((_) async {
        called = true;
        return _json('[]');
      }),
    );

    final result = await service.fetchWord('   ');

    expect(result, isA<Failure<VocabularyEntry>>());
    expect(called, isFalse);
  });

  test('tidak ada internet menghasilkan Failure, bukan crash', () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => throw const SocketException('offline')),
    );

    final result = await service.fetchWord('resilient');

    expect(result, isA<Failure<VocabularyEntry>>());
    expect((result as Failure<VocabularyEntry>).message, contains('internet'));
  });
  test('contoh dikumpulkan dari semua arti, maksimal 3, tanpa duplikat',
      () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => _json(jsonEncode([
            {
              'word': 'candid',
              'meanings': [
                {
                  'partOfSpeech': 'adjective',
                  'definitions': [
                    {'definition': 'Honest.', 'example': 'Contoh satu.'},
                    {'definition': 'Frank.', 'example': 'contoh SATU.'},
                    {'definition': 'Open.', 'example': 'Contoh dua.'},
                  ],
                },
                {
                  'partOfSpeech': 'noun',
                  'definitions': [
                    {'definition': 'A photo.', 'example': 'Contoh tiga.'},
                    {'definition': 'Another.', 'example': 'Contoh empat.'},
                  ],
                },
              ],
            },
          ]))),
    );

    final entry = _entryOf(await service.fetchWord('candid'));

    expect(entry.examples, ['Contoh satu.', 'Contoh dua.', 'Contoh tiga.']);
  });

  test('sinonim dari definisi dan arti, maksimal 3, tanpa duplikat', () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => _json(jsonEncode([
            {
              'word': 'candid',
              'meanings': [
                {
                  'partOfSpeech': 'adjective',
                  'synonyms': ['frank', 'Honest'],
                  'definitions': [
                    {
                      'definition': 'Honest.',
                      'synonyms': ['honest', 'open'],
                    },
                    {
                      'definition': 'Frank.',
                      'synonyms': ['plain'],
                    },
                  ],
                },
              ],
            },
          ]))),
    );

    final entry = _entryOf(await service.fetchWord('candid'));

    expect(entry.synonyms, ['honest', 'open', 'plain']);
  });

  test('tanpa contoh dan sinonim: daftar kosong, tidak error', () async {
    final service = DictionaryApiService(
      client: MockClient((_) async => _json(jsonEncode([
            {
              'word': 'candid',
              'meanings': [
                {
                  'partOfSpeech': 'adjective',
                  'definitions': [
                    {'definition': 'Honest.'}
                  ],
                },
              ],
            },
          ]))),
    );

    final entry = _entryOf(await service.fetchWord('candid'));

    expect(entry.examples, isEmpty);
    expect(entry.synonyms, isEmpty);
  });
}