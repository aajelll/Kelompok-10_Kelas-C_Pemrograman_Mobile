import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart' show kQuizTarget;

/// Kontrak penjadwal supaya ReminderProvider bisa dites tanpa plugin.
abstract class ReminderScheduler {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> schedule(int hour, int minute);
  Future<void> cancel();
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _notificationId = 1001;
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'voca_reminder',
    'Pengingat belajar',
    description: 'Pengingat harian untuk belajar kosakata',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    // PENTING: plugin TIDAK di-initialize di sini. FcmNotificationService.init
    // sudah melakukannya (beserta penanganan ketukan notifikasi); memanggil
    // initialize lagi akan menimpa penanganan ketukan itu.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(int hour, int minute) {
    return _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Waktunya belajar kosakata',
      body: 'Luangkan beberapa menit untuk latihan hari ini.',
      scheduledDate: nextOccurrence(hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      // Ketukan notifikasi membuka layar kuis (ditangani FcmNotificationService).
      payload: kQuizTarget,
      // Inexact: tidak butuh izin alarm tepat; bisa meleset beberapa menit.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: _notificationId);

  /// Waktu berikutnya jam:menit (hari ini bila belum lewat, selain itu besok).
  static tz.TZDateTime nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
    return date;
  }
}