import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/services/favorites_store.dart';
import 'package:voca/features/vocabulary/widgets/word_card.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';

class _FakeStore implements FavoritesStore {
  final controller = StreamController<List<VocabularyEntry>>.broadcast();
  final List<String> added = [];

  @override
  Stream<List<VocabularyEntry>> watchAll() => controller.stream;

  @override
  Future<void> add(VocabularyEntry entry) async => added.add(entry.word);

  @override
  Future<void> remove(String word) async {}
}

const _entry = VocabularyEntry(
  word: 'candid',
  phonetic: '/ˈkændɪd/',
  meanings: [WordMeaning(partOfSpeech: 'adjective', definition: 'Honest.')],
  examples: ['He is candid about it.'],
);

Future<_FakeStore> _pump(
  WidgetTester tester, {
  VocabularyEntry entry = _entry,
  bool showExample = true,
}) async {
  final store = _FakeStore();
  final provider = FavoritesProvider(storeFactory: (_) => store)
    ..updateUser('u1');
  addTearDown(provider.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WordCard(entry: entry, showExample: showExample),
        ),
      ),
    ),
  );
  store.controller.add([]);
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('menampilkan kata (huruf awal besar), fonetik, arti, contoh',
      (tester) async {
    await _pump(tester);

    expect(find.text('Candid'), findsOneWidget);
    expect(find.text('/ˈkændɪd/'), findsOneWidget);
    expect(find.text('Honest.'), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
    expect(find.textContaining('He is candid about it.'), findsOneWidget);
  });

  testWidgets('tanpa contoh atau showExample false: kotak Example tersembunyi',
      (tester) async {
    await _pump(tester, showExample: false);
    expect(find.text('Example'), findsNothing);

    await _pump(
      tester,
      entry: const VocabularyEntry(
        word: 'candid',
        meanings: [WordMeaning(partOfSpeech: '', definition: 'Honest.')],
      ),
    );
    expect(find.text('Example'), findsNothing);
    expect(find.text('/ˈkændɪd/'), findsNothing);
  });

  testWidgets('bintang: abu-abu saat belum favorit, mengetuk menambahkannya',
      (tester) async {
    final store = await _pump(tester);

    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pump();

    expect(store.added, ['candid']);
  });

  testWidgets('bintang terisi saat kata sudah favorit', (tester) async {
    final store = await _pump(tester);

    store.controller.add([_entry]);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
  });
}