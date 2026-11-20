import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/vocabulary/providers/favorites_provider.dart';
import 'package:voca/features/vocabulary/providers/vocabulary_provider.dart';

import 'helpers/fake_favorites_store.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeFavoritesStore store;
  late List<String> requestedUids;
  late FavoritesProvider provider;

  setUp(() {
    store = FakeFavoritesStore();
    requestedUids = [];
    provider = FavoritesProvider(storeFactory: (uid) {
      requestedUids.add(uid);
      return store;
    });
  });

  tearDown(() => provider.dispose());

  test('tanpa login: idle dan toggle meminta masuk', () async {
    expect(provider.status, LoadStatus.idle);
    expect(provider.count, 0);

    final error = await provider.toggle(fakeEntry('candid'));

    expect(error, contains('masuk'));
  });

  test('login: loading lalu data tampil terurut abjad', () async {
    provider.updateUser('u1');
    expect(provider.status, LoadStatus.loading);
    expect(requestedUids, ['u1']);

    store.controller.add([fakeEntry('vivid'), fakeEntry('candid')]);
    await _settle();

    expect(provider.status, LoadStatus.success);
    expect(provider.items.map((e) => e.word), ['candid', 'vivid']);
    expect(provider.count, 2);
  });

  test('isFavorite tidak peka huruf besar-kecil', () async {
    provider.updateUser('u1');
    store.controller.add([fakeEntry('candid')]);
    await _settle();

    expect(provider.isFavorite('CANDID'), isTrue);
    expect(provider.isFavorite(' candid '), isTrue);
    expect(provider.isFavorite('vivid'), isFalse);
  });

  test('toggle menambah jika belum favorit, menghapus jika sudah', () async {
    provider.updateUser('u1');
    store.controller.add([fakeEntry('candid')]);
    await _settle();

    expect(await provider.toggle(fakeEntry('candid')), isNull);
    expect(store.removed, ['candid']);
    expect(store.added, isEmpty);

    expect(await provider.toggle(fakeEntry('vivid')), isNull);
    expect(store.added, ['vivid']);
  });

  test('gagal menulis mengembalikan pesan error', () async {
    provider.updateUser('u1');
    store.failWrites = true;

    final error = await provider.toggle(fakeEntry('candid'));

    expect(error, contains('Gagal'));
  });

  test('error stream menghasilkan status error, retry memuat ulang',
      () async {
    provider.updateUser('u1');
    store.controller.addError(Exception('permission-denied'));
    await _settle();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isNotNull);

    provider.retry();

    expect(provider.status, LoadStatus.loading);
    expect(requestedUids, ['u1', 'u1']);
  });

  test('ganti akun: data akun lama hilang dan tidak bocor ke akun baru',
      () async {
    final stores = {'A': FakeFavoritesStore(), 'B': FakeFavoritesStore()};
    final p = FavoritesProvider(storeFactory: (uid) => stores[uid]!);

    p.updateUser('A');
    stores['A']!.controller.add([fakeEntry('candid')]);
    await _settle();
    expect(p.items.length, 1);

    p.updateUser(null); // logout
    expect(p.items, isEmpty);
    expect(p.status, LoadStatus.idle);

    p.updateUser('B'); // login akun lain
    expect(p.items, isEmpty);

    // Stream akun A sudah dibatalkan: kiriman lamanya tidak boleh masuk.
    stores['A']!.controller.add([fakeEntry('stale')]);
    await _settle();
    expect(p.items, isEmpty);

    stores['B']!.controller.add([fakeEntry('vivid')]);
    await _settle();
    expect(p.items.single.word, 'vivid');

    p.dispose();
  });
}