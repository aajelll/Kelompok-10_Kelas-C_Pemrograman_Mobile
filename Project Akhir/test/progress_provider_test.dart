import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/progress/providers/progress_provider.dart';
import 'package:voca/features/quiz/services/quiz_result_repository.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart'
    show LoadStatus;
import 'package:voca/shared/models/quiz_result.dart';

class _FakeRepo implements QuizResultRepository {
  final controller = StreamController<List<QuizResult>>.broadcast();

  @override
  Stream<List<QuizResult>> watchAll() => controller.stream;

  @override
  Future<void> save(QuizResult result) async {}
}

QuizResult _result(int score, DateTime at) =>
    QuizResult(score: score, totalQuestions: 5, completedAt: at);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepo repo;
  late List<String> requestedUids;
  late ProgressProvider provider;

  setUp(() {
    repo = _FakeRepo();
    requestedUids = [];
    provider = ProgressProvider(repositoryFactory: (uid) {
      requestedUids.add(uid);
      return repo;
    });
  });

  tearDown(() => provider.dispose());

  test('tanpa login: idle dan tidak ada data', () {
    expect(provider.status, LoadStatus.idle);
    expect(provider.completedCount, 0);
    expect(provider.lastResult, isNull);
  });

  test('login: loading lalu data diurutkan, terbaru di atas', () async {
    provider.updateUser('u1');
    expect(provider.status, LoadStatus.loading);
    expect(requestedUids, ['u1']);

    repo.controller.add([
      _result(2, DateTime(2026, 1, 1)),
      _result(4, DateTime(2026, 1, 3)),
      _result(3, DateTime(2026, 1, 2)),
    ]);
    await _settle();

    expect(provider.status, LoadStatus.success);
    expect(provider.completedCount, 3);
    expect(provider.lastResult?.score, 4);
    expect(provider.recent.map((r) => r.score), [4, 3, 2]);
  });

  test('belum ada kuis: sukses dengan nol kuis dan tanpa skor terakhir',
      () async {
    provider.updateUser('u1');
    repo.controller.add([]);
    await _settle();

    expect(provider.status, LoadStatus.success);
    expect(provider.completedCount, 0);
    expect(provider.lastResult, isNull);
    expect(provider.recent, isEmpty);
  });

  test('riwayat dibatasi 10 item, tetapi jumlah kuis menghitung semuanya',
      () async {
    provider.updateUser('u1');
    repo.controller.add([
      for (var i = 0; i < 12; i++) _result(i % 6, DateTime(2026, 1, i + 1)),
    ]);
    await _settle();

    expect(provider.completedCount, 12);
    expect(provider.recent.length, 10);
  });

  test('error stream menghasilkan status error, retry memuat ulang', () async {
    provider.updateUser('u1');
    repo.controller.addError(Exception('permission-denied'));
    await _settle();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isNotNull);

    provider.retry();

    expect(provider.status, LoadStatus.loading);
    expect(requestedUids, ['u1', 'u1']);
  });

  test('ganti akun: data akun lama hilang dan tidak bocor ke akun baru',
      () async {
    final repos = {'A': _FakeRepo(), 'B': _FakeRepo()};
    final p = ProgressProvider(repositoryFactory: (uid) => repos[uid]!);

    p.updateUser('A');
    repos['A']!.controller.add([_result(5, DateTime(2026, 1, 1))]);
    await _settle();
    expect(p.completedCount, 1);

    p.updateUser(null); // logout
    expect(p.completedCount, 0);
    expect(p.status, LoadStatus.idle);

    p.updateUser('B'); // login akun lain
    expect(p.completedCount, 0);

    // Stream akun A sudah dibatalkan: kiriman lamanya tidak boleh masuk.
    repos['A']!.controller.add([_result(1, DateTime(2026, 1, 9))]);
    await _settle();
    expect(p.completedCount, 0);

    repos['B']!.controller.add([_result(3, DateTime(2026, 1, 2))]);
    await _settle();
    expect(p.lastResult?.score, 3);

    p.dispose();
  });
}
