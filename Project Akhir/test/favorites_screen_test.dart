import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voca/core/theme/app_theme.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/screens/favorites_screen.dart';

import 'helpers/fake_favorites_store.dart';

Widget _app(FavoritesProvider provider) => ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const FavoritesScreen()),
    );

void main() {
  late FakeFavoritesStore store;
  late FavoritesProvider provider;

  setUp(() {
    store = FakeFavoritesStore();
    provider = FavoritesProvider(storeFactory: (_) => store)..updateUser('u1');
  });

  tearDown(() => provider.dispose());

  testWidgets('menampilkan loading sebelum data tiba', (tester) async {
    await tester.pumpWidget(_app(provider));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('daftar kosong menampilkan pesan belum ada favorit',
      (tester) async {
    await tester.pumpWidget(_app(provider));
    store.controller.add([]);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada kata favorit'), findsOneWidget);
  });

  testWidgets('menampilkan kata favorit dan menghapusnya lewat ikon hati',
      (tester) async {
    await tester.pumpWidget(_app(provider));
    store.controller.add([fakeEntry('resilient')]);
    await tester.pumpAndSettle();

    expect(find.text('resilient'), findsOneWidget);
    expect(find.text('definisi resilient'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(store.removed, ['resilient']);
  });

  testWidgets('error menampilkan pesan dan tombol coba lagi', (tester) async {
    await tester.pumpWidget(_app(provider));
    store.controller.addError(Exception('permission-denied'));
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);
  });
}