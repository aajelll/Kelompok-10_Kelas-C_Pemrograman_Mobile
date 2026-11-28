import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:voca/features/vocabulary/screens/search_screen.dart';
import 'package:voca/features/vocabulary/screens/word_detail_screen.dart';
import 'package:voca/shared/models/result.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';
import 'package:voca/shared/services/contracts.dart';

class _FakeSource implements VocabularySource {
  _FakeSource(this._handler);

  final Result<VocabularyEntry> Function(String word) _handler;
  final List<String> calls = [];

  @override
  Future<Result<VocabularyEntry>> fetchWord(String word) async {
    calls.add(word);
    return _handler(word);
  }
}

VocabularyEntry _entry(String word) => VocabularyEntry(
      word: word,
      phonetic: '/test/',
      meanings: [
        WordMeaning(partOfSpeech: 'noun', definition: 'definisi $word'),
      ],
      examples: ['She is $word today.'],
    );

Future<void> _pump(WidgetTester tester, VocabularySource source) async {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VocabularyProvider(source)),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const SearchScreen()),
    ),
  );
}

Future<void> _search(WidgetTester tester, String word) async {
  await tester.enterText(find.byType(TextField), word);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('awalnya menampilkan pesan kosong', (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));

    expect(find.text('Tidak ada kata yang sesuai'), findsOneWidget);
    expect(
      find.text('Mulai mencari atau masukkan kata yang benar'),
      findsOneWidget,
    );
  });

  testWidgets('hasil: kata, fonetik, arti, contoh, dan bintang favorit',
      (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));

    await _search(tester, 'resilient');

    expect(find.text('Resilient'), findsOneWidget);
    expect(find.text('/test/'), findsOneWidget);
    expect(find.text('definisi resilient'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
    expect(find.textContaining('She is resilient today.'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(find.text('noun'), findsNothing); // jenis kata tidak ditampilkan
  });

  testWidgets('kata tidak ditemukan: pesan kosong, tanpa tombol coba lagi',
      (tester) async {
    await _pump(
      tester,
      _FakeSource(
        (w) => Failure<VocabularyEntry>('Kata "$w" tidak ditemukan.'),
      ),
    );

    await _search(tester, 'zzzz');

    expect(find.text('Tidak ada kata yang sesuai'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('gangguan jaringan: pesan error, coba lagi berhasil',
      (tester) async {
    var offline = true;
    await _pump(
      tester,
      _FakeSource(
        (w) => offline
            ? Failure<VocabularyEntry>('Tidak ada koneksi internet.')
            : Success<VocabularyEntry>(_entry(w)),
      ),
    );

    await _search(tester, 'candid');
    expect(find.text('Tidak ada koneksi internet.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    offline = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Candid'), findsOneWidget);
  });

  testWidgets('mencari otomatis setelah berhenti mengetik (debounce)',
      (tester) async {
    final source = _FakeSource((w) => Success<VocabularyEntry>(_entry(w)));
    await _pump(tester, source);

    await tester.enterText(find.byType(TextField), 'candid');
    await tester.pump(const Duration(milliseconds: 100));
    expect(source.calls, isEmpty); // belum, masih menunggu

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(source.calls, ['candid']);
    expect(find.text('Candid'), findsOneWidget);
  });

  testWidgets('mengetuk kartu hasil membuka Detail Kata', (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));
    await _search(tester, 'resilient');

    await tester.tap(find.text('Resilient'));
    await tester.pumpAndSettle();

    expect(find.byType(WordDetailScreen), findsOneWidget);
  });

  testWidgets('tombol hapus mengosongkan kolom dan kembali ke awal',
      (tester) async {
    await _pump(tester, _FakeSource((w) => Success<VocabularyEntry>(_entry(w))));
    await _search(tester, 'resilient');

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Resilient'), findsNothing);
    expect(find.text('Tidak ada kata yang sesuai'), findsOneWidget);
  });
}