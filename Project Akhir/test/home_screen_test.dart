import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/constants/seed_words.dart';
import 'package:voca/core/extensions/datetime_extensions.dart';
import 'package:voca/core/extensions/string_extensions.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/auth/providers/auth_provider.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:voca/features/vocabulary/screens/home_screen.dart';
import 'package:voca/features/vocabulary/screens/word_detail_screen.dart';
import 'package:voca/shared/models/result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';
import 'package:voca/shared/services/contracts.dart';

import 'helpers/fake_auth.dart';

class _FakeSource implements VocabularySource {
  _FakeSource(this._handler);

  final Result<VocabularyEntry> Function(String word) _handler;

  @override
  Future<Result<VocabularyEntry>> fetchWord(String word) async =>
      _handler(word);
}

VocabularyEntry _entry(String word, {String? example}) => VocabularyEntry(
      word: word,
      phonetic: '/fon/',
      meanings: [
        WordMeaning(partOfSpeech: 'adjective', definition: 'definisi $word'),
      ],
      examples: example == null ? const [] : [example],
    );

Future<void> _pump(
  WidgetTester tester,
  VocabularySource source, {
  String name = 'Budi',
}) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: FakeAuthProvider(name: name),
        ),
        ChangeNotifierProvider(
          // Tanggal dikunci agar kata hari ini selalu kSeedWords[0].
          create: (_) =>
              VocabularyProvider(source, now: () => DateTime(2026, 1, 1)),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final dailyWord = kSeedWords[0];

  testWidgets('menampilkan tanggal, sapaan dengan nama, dan subjudul',
      (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));

    expect(find.text(DateTime.now().dayAndMonth), findsOneWidget);
    expect(find.text('Hi, Budi!'), findsOneWidget);
    expect(find.text('Siap belajar kata baru hari ini?'), findsOneWidget);
  });

  testWidgets('tanpa nama: sapaan Hi!', (tester) async {
    await _pump(
      tester,
      _FakeSource((w) => Success<VocabularyEntry>(_entry(w))),
      name: '',
    );

    expect(find.text('Hi!'), findsOneWidget);
  });

  testWidgets('kartu kata hari ini lengkap: kata, fonetik, arti, contoh',
      (tester) async {
    await _pump(
      tester,
      _FakeSource(
        (w) => Success<VocabularyEntry>(_entry(w, example: 'Contoh kalimat.')),
      ),
    );

    expect(find.text(dailyWord.capitalized), findsOneWidget);
    expect(find.text('/fon/'), findsOneWidget);
    expect(find.text('definisi $dailyWord'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
    expect(find.textContaining('Contoh kalimat.'), findsOneWidget);
  });

  testWidgets('tanpa contoh: kotak Example tersembunyi', (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));

    expect(find.text(dailyWord.capitalized), findsOneWidget);
    expect(find.text('Example'), findsNothing);
  });

  testWidgets('API gagal: pesan error, coba lagi menampilkan kata',
      (tester) async {
    var attempt = 0;
    await _pump(
      tester,
      _FakeSource((w) {
        attempt++;
        return attempt == 1
            ? Failure<VocabularyEntry>('Tidak ada koneksi internet.')
            : Success<VocabularyEntry>(_entry(w));
      }),
    );

    expect(find.text('Tidak ada koneksi internet.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada koneksi internet.'), findsNothing);
    expect(find.text(dailyWord.capitalized), findsOneWidget);
  });

  testWidgets('mengetuk kartu membuka Detail Kata', (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));

    await tester.tap(find.text(dailyWord.capitalized));
    await tester.pumpAndSettle();

    expect(find.byType(WordDetailScreen), findsOneWidget);
    expect(find.text('Detail Kata'), findsOneWidget);
  });

  testWidgets('ada tombol Mulai Kuis; tombol lama sudah tidak ada',
      (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));

    expect(find.text('Mulai Kuis'), findsOneWidget);
    expect(find.text('Cari kata'), findsNothing);
    expect(find.text('Lihat detail'), findsNothing);
  });
}