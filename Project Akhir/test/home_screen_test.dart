import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/constants/seed_words.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:voca/features/vocabulary/screens/home_screen.dart';
import 'package:voca/features/vocabulary/screens/search_screen.dart';
import 'package:voca/features/vocabulary/screens/word_detail_screen.dart';
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

Widget _app(VocabularySource source) => ChangeNotifierProvider(
      // Tanggal dikunci agar kata hari ini selalu kSeedWords[0].
      create: (_) =>
          VocabularyProvider(source, now: () => DateTime(2026, 1, 1)),
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    );

VocabularyEntry _entry(String word, {String? phonetic, String? example}) =>
    VocabularyEntry(
      word: word,
      phonetic: phonetic,
      meanings: [
        WordMeaning(
          partOfSpeech: 'adjective',
          definition: 'definisi $word',
          example: example,
        ),
      ],
    );

void main() {
  final dailyWord = kSeedWords[0];

  testWidgets('menampilkan kata hari ini lengkap dengan fonetik dan contoh',
      (tester) async {
    final source = _FakeSource(
      (w) => Success<VocabularyEntry>(
        _entry(w, phonetic: '/fon/', example: 'Contoh kalimat.'),
      ),
    );

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();

    expect(find.text(dailyWord), findsOneWidget);
    expect(find.text('/fon/'), findsOneWidget);
    expect(find.text('definisi $dailyWord'), findsOneWidget);
    expect(find.text('"Contoh kalimat."'), findsOneWidget);
  });

  testWidgets('fonetik dan contoh kosong tidak membuat error', (tester) async {
    final source = _FakeSource(
      (w) => Success<VocabularyEntry>(_entry(w)),
    );

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();

    expect(find.text(dailyWord), findsOneWidget);
    expect(find.text('definisi $dailyWord'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('API gagal menampilkan error, retry berhasil menampilkan kata',
      (tester) async {
    var attempt = 0;
    final source = _FakeSource((w) {
      attempt++;
      return attempt == 1
          ? Failure<VocabularyEntry>('Tidak ada koneksi internet.')
          : Success<VocabularyEntry>(_entry(w));
    });

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi internet.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi internet.'), findsNothing);
    expect(find.text(dailyWord), findsOneWidget);
  });

  testWidgets('Lihat detail membuka halaman detail kata', (tester) async {
    final source = _FakeSource(
      (w) => Success<VocabularyEntry>(_entry(w)),
    );

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat detail'));
    await tester.pumpAndSettle();

    expect(find.byType(WordDetailScreen), findsOneWidget);
  });

  testWidgets('Cari kata membuka halaman pencarian', (tester) async {
    final source = _FakeSource(
      (w) => Success<VocabularyEntry>(_entry(w)),
    );

    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari kata'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });
}