import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
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

const _full = VocabularyEntry(
  word: 'candid',
  phonetic: '/ˈkændɪd/',
  meanings: [WordMeaning(partOfSpeech: 'adjective', definition: 'Honest.')],
  examples: ['Contoh satu candid.', 'Contoh dua.', 'Contoh tiga.'],
  synonyms: ['frank', 'open'],
);

const _bare = VocabularyEntry(
  word: 'candid',
  meanings: [WordMeaning(partOfSpeech: 'adjective', definition: 'Honest.')],
);

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WordDetailScreen(word: 'candid'),
              ),
            ),
            child: const Text('Buka detail'),
          ),
        ),
      );
}

Future<void> _open(
  WidgetTester tester,
  Result<VocabularyEntry> Function(String word) handler,
) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VocabularyProvider(_FakeSource(handler)),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const _Host()),
    ),
  );
  await tester.tap(find.text('Buka detail'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menampilkan kata, fonetik, arti, 3 contoh, dan sinonim',
      (tester) async {
    await _open(tester, (w) => Success<VocabularyEntry>(_full));

    expect(find.text('Detail Kata'), findsOneWidget);
    expect(find.text('Candid'), findsOneWidget);
    expect(find.text('/ˈkændɪd/'), findsOneWidget);
    expect(find.text('Honest.'), findsOneWidget);
    expect(find.text('Examples'), findsOneWidget);
    expect(find.textContaining('Contoh satu'), findsOneWidget);
    expect(find.textContaining('Contoh dua'), findsOneWidget);
    expect(find.textContaining('Contoh tiga'), findsOneWidget);
    expect(find.text('Synonyms'), findsOneWidget);
    expect(find.text('frank'), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
  });

  testWidgets('tanpa contoh dan sinonim: kedua bagian tersembunyi',
      (tester) async {
    await _open(tester, (w) => Success<VocabularyEntry>(_bare));

    expect(find.text('Candid'), findsOneWidget);
    expect(find.text('Examples'), findsNothing);
    expect(find.text('Synonyms'), findsNothing);
  });

  testWidgets('gagal memuat: pesan error, coba lagi berhasil', (tester) async {
    var attempt = 0;
    await _open(tester, (w) {
      attempt++;
      return attempt == 1
          ? Failure<VocabularyEntry>('Tidak ada koneksi internet.')
          : Success<VocabularyEntry>(_full);
    });

    expect(find.text('Tidak ada koneksi internet.'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Candid'), findsOneWidget);
  });

  testWidgets('tombol kembali menutup halaman detail', (tester) async {
    await _open(tester, (w) => Success<VocabularyEntry>(_full));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Buka detail'), findsOneWidget);
    expect(find.byType(WordDetailScreen), findsNothing);
  });
}