import 'package:flutter_test/flutter_test.dart';
import 'package:voca/features/notification/providers/reminder_provider.dart';
import 'package:voca/features/notification/services/reminder_scheduler.dart';
import 'package:voca/features/notification/services/reminder_store.dart';

class FakeScheduler implements ReminderScheduler {
  bool granted = true;
  final scheduled = <String>[];
  int cancelCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> schedule(int hour, int minute) async =>
      scheduled.add('$hour:$minute');

  @override
  Future<void> cancel() async => cancelCount++;
}

class FakeStore implements ReminderStore {
  final data = <String, ReminderSettings>{};

  @override
  Future<ReminderSettings> load(String uid) async =>
      data[uid] ?? const ReminderSettings();

  @override
  Future<void> save(String uid, ReminderSettings s) async => data[uid] = s;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeScheduler scheduler;
  late FakeStore store;
  late ReminderProvider provider;

  setUp(() {
    scheduler = FakeScheduler();
    store = FakeStore();
    provider = ReminderProvider(scheduler, store);
  });

  tearDown(() => provider.dispose());

  test('default: nonaktif pukul 19:00 dan tidak menjadwalkan apa pun', () async {
    provider.updateUser('u1');
    await settle();
    expect(provider.enabled, isFalse);
    expect(provider.settings.timeLabel, '19:00');
    expect(scheduler.scheduled, isEmpty);
  });

  test('aktifkan: izin diminta, dijadwalkan, dan disimpan', () async {
    provider.updateUser('u1');
    await settle();
    await provider.setEnabled(true);
    expect(provider.enabled, isTrue);
    expect(scheduler.scheduled, ['19:0']);
    expect(store.data['u1']!.enabled, isTrue);
  });

  test('izin ditolak: tidak dijadwalkan dan tidak diaktifkan', () async {
    scheduler.granted = false;
    provider.updateUser('u1');
    await settle();
    await provider.setEnabled(true);
    expect(provider.permissionDenied, isTrue);
    expect(provider.enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(store.data['u1'], isNull);
  });

  test('nonaktifkan: jadwal dibatalkan', () async {
    provider.updateUser('u1');
    await settle();
    await provider.setEnabled(true);
    await provider.setEnabled(false);
    expect(provider.enabled, isFalse);
    expect(scheduler.cancelCount, 1);
    expect(store.data['u1']!.enabled, isFalse);
  });

  test('ubah jam saat aktif: dijadwalkan ulang', () async {
    provider.updateUser('u1');
    await settle();
    await provider.setEnabled(true);
    await provider.setTime(7, 30);
    expect(scheduler.scheduled.last, '7:30');
    expect(store.data['u1']!.timeLabel, '07:30');
  });

  test('ubah jam saat nonaktif: hanya disimpan, tidak dijadwalkan', () async {
    provider.updateUser('u1');
    await settle();
    await provider.setTime(8, 5);
    expect(scheduler.scheduled, isEmpty);
    expect(store.data['u1']!.timeLabel, '08:05');
  });

  test('login dengan pengaturan aktif: dijadwalkan ulang otomatis', () async {
    store.data['u1'] =
        const ReminderSettings(enabled: true, hour: 6, minute: 15);
    provider.updateUser('u1');
    await settle();
    expect(provider.enabled, isTrue);
    expect(scheduler.scheduled, ['6:15']);
  });

  test('logout: jadwal dibatalkan dan pengaturan direset', () async {
    store.data['u1'] = const ReminderSettings(enabled: true);
    provider.updateUser('u1');
    await settle();
    provider.updateUser(null);
    await settle();
    expect(scheduler.cancelCount, 1);
    expect(provider.enabled, isFalse);
  });
}
