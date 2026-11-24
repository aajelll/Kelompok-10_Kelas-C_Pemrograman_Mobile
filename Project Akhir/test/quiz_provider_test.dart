import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/quiz/models/quiz_question.dart';
import 'package:voca/features/quiz/providers/quiz_provider.dart';
import 'package:voca/features/quiz/services/quiz_result_repository.dart';
import 'package:voca/shared/models/quiz_result.dart';
import 'package:voca/shared/models/result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';
import 'package:voca/shared/services/contracts.dart';

class _FakeSource implements VocabularySource {
  _FakeSource(this._handler);
  final Result<VocabularyEntry> Function(String word) _handler;

  @override
  Future<Result<VocabularyEntry>> fetchWord(String word) async =>
      _handler(word);
}

class _FakeRepo implements QuizResultRepository {
  final List<QuizResult> saved = [];
  bool failSave = false;

  @override
  Stream<List<QuizResult>> watchAll() => const Stream.empty();

  @override
  Future<void> save(QuizResult result) async {
    if (failSave) throw Exception('gagal menyimpan');
    saved.add(result);
  }
}

VocabularyEntry _entry(String word, {String? definition}) => VocabularyEntry(
      word: word,
      meanings: [
        WordMeaning(
          partOfSpeech: 'noun',
          definition: definition ?? 'definisi $word',
        ),
      ],
    );

QuizProvider _make(
  _FakeRepo repo, {
  Result<VocabularyEntry> Function(String word)? handler,
  String? uid = 'u1',
}) {
  final provider = QuizProvider(
    _FakeSource(handler ?? (w) => Success<VocabularyEntry>(_entry(w))),
    storeFactory: (_) => repo,
    random: Random(1),
    now: () => DateTime(2026, 1, 1, 10),
  );
  if (uid != null) provider.updateUser(uid);
  return provider;
}

/// Menjawab semua soal sampai kuis selesai.
Future<void> _answerAll(QuizProvider p, {required bool correct}) async {
  while (p.phase == QuizPhase.inProgress) {
    final q = p.currentQuestion!;
    p.select(correct ? q.correctIndex : (q.correctIndex + 1) % q.options.length);
    await p.next();
  }
}

void main() {
  group('buildQuizQuestions', () {
    test('jawaban kembar dibuang agar soal tidak ambigu', () {
      final entries = [
        _entry('a', definition: 'sama'),
        _entry('b', definition: 'sama'),
        _entry('c'),
        _entry('d'),
        _entry('e'),
      ];
      final questions =
          buildQuizQuestions(entries, count: 5, random: Random(1));
      expect(questions.length, 4);
      expect(questions.map((q) => q.word), isNot(contains('b')));
      for (final q in questions) {
        expect(q.options.toSet().length, q.options.length);
      }
    });

    test('data kurang dari 4 menghasilkan daftar kosong', () {
      final entries = [_entry('a'), _entry('b'), _entry('c')];
      expect(buildQuizQuestions(entries, count: 5, random: Random(1)), isEmpty);
    });
  });

  group('QuizProvider', () {
    test('start: 5 soal, tiap soal 4 pilihan unik dengan satu jawaban benar',
        () async {
      final provider = _make(_FakeRepo());
      await provider.start();
      expect(provider.phase, QuizPhase.inProgress);
      expect(provider.totalQuestions, 5);
      expect(provider.currentIndex, 0);
      for (final q in provider.questions) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.correctAnswer, 'definisi ${q.word}');
      }
    });

    test('semua jawaban benar: skor penuh dan tersimpan satu kali', () async {
      final repo = _FakeRepo();
      final provider = _make(repo);
      await provider.start();
      await _answerAll(provider, correct: true);
      expect(provider.phase, QuizPhase.finished);
      expect(provider.result?.score, 5);
      expect(provider.result?.totalQuestions, 5);
      expect(provider.saveStatus, SaveStatus.saved);
      expect(repo.saved.length, 1);
      await provider.next(); // tidak boleh menyimpan lagi
      expect(repo.saved.length, 1);
    });

    test('semua jawaban salah: skor 0', () async {
      final provider = _make(_FakeRepo());
      await provider.start();
      await _answerAll(provider, correct: false);
      expect(provider.result?.score, 0);
    });

    test('menjawab dua kali pada soal yang sama tidak dihitung ulang',
        () async {
      final provider = _make(_FakeRepo());
      await provider.start();
      final q = provider.currentQuestion!;
      provider.select(q.correctIndex);
      provider.select((q.correctIndex + 1) % 4);
      expect(provider.selectedIndex, q.correctIndex);
      expect(provider.score, 1);
    });

    test('next sebelum menjawab tidak pindah soal', () async {
      final provider = _make(_FakeRepo());
      await provider.start();
      await provider.next();
      expect(provider.currentIndex, 0);
    });

    test('gagal mengambil data: error, lalu mulai lagi berhasil', () async {
      var fail = true;
      final provider = _make(
        _FakeRepo(),
        handler: (w) => fail
            ? Failure<VocabularyEntry>('Tidak ada koneksi internet.')
            : Success<VocabularyEntry>(_entry(w)),
      );
      await provider.start();
      expect(provider.phase, QuizPhase.error);
      expect(provider.error, isNotNull);
      fail = false;
      await provider.start();
      expect(provider.phase, QuizPhase.inProgress);
    });

    test('kata berhasil kurang dari 4: error', () async {
      final provider = _make(
        _FakeRepo(),
        handler: (w) => ['resilient', 'candid', 'vivid'].contains(w)
            ? Success<VocabularyEntry>(_entry(w))
            : Failure<VocabularyEntry>('gagal'),
      );
      await provider.start();
      expect(provider.phase, QuizPhase.error);
    });

    test('gagal menyimpan: hasil tetap tampil, retry berhasil', () async {
      final repo = _FakeRepo()..failSave = true;
      final provider = _make(repo);
      await provider.start();
      await _answerAll(provider, correct: true);
      expect(provider.phase, QuizPhase.finished);
      expect(provider.result, isNotNull);
      expect(provider.saveStatus, SaveStatus.error);
      expect(repo.saved, isEmpty);

      repo.failSave = false;
      await provider.retrySave();
      expect(provider.saveStatus, SaveStatus.saved);
      expect(repo.saved.length, 1);
    });

    test('tanpa login: hasil tidak disimpan dan diminta masuk', () async {
      final repo = _FakeRepo();
      final provider = _make(repo, uid: null);
      await provider.start();
      await _answerAll(provider, correct: true);
      expect(provider.saveStatus, SaveStatus.error);
      expect(provider.saveError, contains('masuk'));
      expect(repo.saved, isEmpty);
    });
  });
}
