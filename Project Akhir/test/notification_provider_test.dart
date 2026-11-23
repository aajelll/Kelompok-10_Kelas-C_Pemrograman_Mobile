import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/notification/providers/notification_provider.dart';
import 'package:voca/features/notification/services/notification_service.dart';
import 'package:voca/features/notification/services/push_token_store.dart';

class _FakeService implements NotificationService {
  NotificationPermission permission = NotificationPermission.granted;
  String? token = 'token-1';
  int initCalls = 0;
  int permissionCalls = 0;
  int deleteCalls = 0;
  void Function(String? target)? onTarget;
  final refresh = StreamController<String>.broadcast();

  @override
  Future<void> init({required void Function(String? target) onTarget}) async {
    initCalls++;
    this.onTarget = onTarget;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    permissionCalls++;
    return permission;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<void> deleteToken() async => deleteCalls++;
}

class _FakeStore implements PushTokenStore {
  final List<(String, String)> saved = [];
  bool fail = false;

  @override
  Future<void> saveToken(String uid, String token) async {
    if (fail) throw Exception('gagal menyimpan');
    saved.add((uid, token));
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeService service;
  late _FakeStore store;
  late List<String> navigated;
  late NotificationProvider provider;

  setUp(() {
    service = _FakeService();
    store = _FakeStore();
    navigated = [];
    provider = NotificationProvider(
      service,
      tokenStore: store,
      onNavigate: navigated.add,
    );
  });

  tearDown(() => provider.dispose());

  test('login: siapkan layanan, minta izin, simpan token untuk UID itu',
      () async {
    provider.updateUser('u1');
    await _settle();

    expect(service.initCalls, 1);
    expect(service.permissionCalls, 1);
    expect(provider.permission, NotificationPermission.granted);
    expect(provider.token, 'token-1');
    expect(store.saved, [('u1', 'token-1')]);
  });

  test('UID yang sama dua kali tidak menyiapkan ulang', () async {
    provider.updateUser('u1');
    provider.updateUser('u1');
    await _settle();

    expect(service.permissionCalls, 1);
    expect(store.saved.length, 1);
  });

  test('izin ditolak: token tidak diambil dan tidak disimpan', () async {
    service.permission = NotificationPermission.denied;

    provider.updateUser('u1');
    await _settle();

    expect(provider.permission, NotificationPermission.denied);
    expect(provider.token, isNull);
    expect(store.saved, isEmpty);
  });

  test('token diperbarui oleh FCM: disimpan ulang', () async {
    provider.updateUser('u1');
    await _settle();

    service.refresh.add('token-2');
    await _settle();

    expect(provider.token, 'token-2');
    expect(store.saved, [('u1', 'token-1'), ('u1', 'token-2')]);
  });

  test('logout: token dibatalkan dan perubahan token sesudahnya diabaikan',
      () async {
    provider.updateUser('u1');
    await _settle();

    provider.updateUser(null);
    await _settle();
    service.refresh.add('token-x');
    await _settle();

    expect(service.deleteCalls, 1);
    expect(provider.token, isNull);
    expect(store.saved.length, 1);
  });

  test('ganti akun: token lama dibatalkan, token baru disimpan untuk akun baru',
      () async {
    provider.updateUser('A');
    await _settle();

    service.token = 'token-B';
    provider.updateUser('B');
    await _settle();

    expect(service.deleteCalls, 1);
    expect(service.initCalls, 1);
    expect(store.saved, [('A', 'token-1'), ('B', 'token-B')]);
  });

  test('gagal menyimpan token: error terisi dan tidak crash', () async {
    store.fail = true;

    provider.updateUser('u1');
    await _settle();

    expect(provider.error, isNotNull);
    expect(provider.token, isNull);
  });

  test('notifikasi kuis diketuk saat login: membuka target kuis', () async {
    provider.updateUser('u1');
    await _settle();

    service.onTarget!(kQuizTarget);

    expect(navigated, [kQuizTarget]);
  });

  test('target lain atau tanpa target diabaikan', () async {
    provider.updateUser('u1');
    await _settle();

    service.onTarget!('lainnya');
    service.onTarget!(null);

    expect(navigated, isEmpty);
  });

  test('notifikasi diketuk saat tidak login diabaikan', () async {
    provider.updateUser('u1');
    await _settle();
    provider.updateUser(null);

    service.onTarget!(kQuizTarget);

    expect(navigated, isEmpty);
  });
}
