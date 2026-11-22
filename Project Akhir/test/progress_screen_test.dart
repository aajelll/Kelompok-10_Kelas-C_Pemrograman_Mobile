import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/auth/providers/auth_provider.dart';
import 'package:voca/features/progress/providers/progress_provider.dart';
import 'package:voca/features/progress/screens/progress_screen.dart';
import 'package:voca/features/quiz/services/quiz_result_repository.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/services/favorites_store.dart';
import 'package:voca/shared/models/quiz_result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';

/// AuthProvider palsu: ProfileCard hanya membaca nama dan email.
class _FakeAuth extends ChangeNotifier implements AuthProvider {
  @override
  String get displayName => 'Budi';

  @override
  String get email => 'budi@contoh.com';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeFavoritesStore implements FavoritesStore {
  final controller = StreamController<List<VocabularyEntry>>.broadcast();

  @override
  Stream<List<VocabularyEntry>> watchAll() => controller.stream;

  @override
  Future<void> add(VocabularyEntry entry) async {}

  @override
  Future<void> remove(String word) async {}
}

class _FakeQuizRepo implements QuizResultRepository {
  final controller = StreamController<List<QuizResult>>.broadcast();

  @override
  Stream<List<QuizResult>> watchAll() => controller.stream;

  @override
  Future<void> save(QuizResult result) async {}
}

VocabularyEntry _entry(String word) => VocabularyEntry(
      word: word,
      meanings: [
        WordMeaning(partOfSpeech: 'noun', definition: 'definisi $word'),
      ],
    );

QuizResult _result(int score, DateTime at) =>
    QuizResult(score: score, totalQuestions: 5, completedAt: at);

Future<void> _pump(
  WidgetTester tester, {
  required _FakeFavoritesStore favorites,
  required QuizResultRepository Function(String uid) quizFactory,
}) async {
  // Layar besar agar seluruh isi daftar terbangun tanpa menggulir.
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final favoritesProvider = FavoritesProvider(storeFactory: (_) => favorites)
    ..updateUser('u1');
  final progressProvider = ProgressProvider(repositoryFactory: quizFactory)
    ..updateUser('u1');
  addTearDown(favoritesProvider.dispose);
  addTearDown(progressProvider.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuth()),
        ChangeNotifierProvider.value(value: favoritesProvider),
        ChangeNotifierProvider.value(value: progressProvider),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const ProgressScreen()),
    ),
  );
}

void main() {
  testWidgets('belum ada data: angka nol dan pesan riwayat kosong',
      (tester) async {
    final favorites = _FakeFavoritesStore();
    final quiz = _FakeQuizRepo();
    await _pump(tester, favorites: favorites, quizFactory: (_) => quiz);

    favorites.controller.add([]);
    quiz.controller.add([]);
    await tester.pumpAndSettle();

    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('budi@contoh.com'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2)); // favorit dan kuis selesai
    expect(find.text('-'), findsOneWidget); // skor terakhir
    expect(find.text('Belum ada kuis yang diselesaikan'), findsOneWidget);
  });

  testWidgets('menampilkan jumlah favorit, kuis selesai, skor terakhir, riwayat',
      (tester) async {
    final favorites = _FakeFavoritesStore();
    final quiz = _FakeQuizRepo();
    await _pump(tester, favorites: favorites, quizFactory: (_) => quiz);

    favorites.controller.add([_entry('a'), _entry('b'), _entry('c')]);
    quiz.controller.add([
      _result(2, DateTime(2026, 1, 1, 9)),
      _result(4, DateTime(2026, 1, 2, 9)),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget); // kata favorit
    expect(find.text('2'), findsOneWidget); // kuis selesai
    expect(find.text('4/5'), findsOneWidget); // skor terakhir
    expect(find.text('4 / 5'), findsOneWidget); // riwayat terbaru
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('riwayat gagal dimuat: pesan error, coba lagi memuat ulang',
      (tester) async {
    final favorites = _FakeFavoritesStore();
    final quiz = _FakeQuizRepo();
    var calls = 0;
    await _pump(
      tester,
      favorites: favorites,
      quizFactory: (_) {
        calls++;
        return quiz;
      },
    );
    expect(calls, 1);

    quiz.controller.addError(Exception('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal memuat riwayat'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pump();

    expect(calls, 2);
  });
}
