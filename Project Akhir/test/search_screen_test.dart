import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:voca/features/vocabulary/screens/search_screen.dart';
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
      create: (_) => VocabularyProvider(source),
      child: MaterialApp(theme: AppTheme.light, home: const SearchScreen()),
    );

Future<void> _search(WidgetTester tester, String word) async {
  await tester.enterText(find.byType(TextField), word);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('awalnya menampilkan ajakan mencari', (tester) async {
    await tester.pumpWidget(_app(_FakeSource((w) => Failure('tidak dipakai'))));

    expect(find.text('Mulai mencari kata'), findsOneWidget);
  });

  testWidgets('pencarian berhasil menampilkan kata dan artinya',
      (tester) async {
    final source = _FakeSource(
      (w) => Success<VocabularyEntry>(VocabularyEntry(
        word: w,
        phonetic: '/test/',
        meanings: [
          WordMeaning(partOfSpeech: 'adjective', definition: 'definisi $w'),
        ],
      )),
    );
    await tester.pumpWidget(_app(source));

    await _search(tester, 'Resilient');

    expect(find.text('resilient'), findsOneWidget);
    expect(find.text('definisi resilient'), findsOneWidget);
    expect(find.text('/test/'), findsOneWidget);
  });

  testWidgets('kata tidak ditemukan menampilkan pesan dan tombol coba lagi',
      (tester) async {
    final source = _FakeSource(
      (w) => Failure<VocabularyEntry>('Kata "$w" tidak ditemukan.'),
    );
    await tester.pumpWidget(_app(source));

    await _search(tester, 'zzzz');

    expect(find.text('Kata "zzzz" tidak ditemukan.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}