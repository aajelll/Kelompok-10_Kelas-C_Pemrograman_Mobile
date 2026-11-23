import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';

/// Nilai `data.target` pada pesan yang membuka layar kuis saat diketuk.
const String kQuizTarget = 'quiz';

/// Status izin notifikasi yang disederhanakan.
enum NotificationPermission { unknown, granted, denied }

/// Kontrak layanan notifikasi, agar logika di Provider bisa diuji tanpa
/// Firebase.
abstract interface class NotificationService {
  /// Menyiapkan notifikasi lokal dan mendengarkan pesan FCM. [onTarget] dipanggil
  /// saat notifikasi diketuk, dengan nilai `target` dari pesan (bisa null).
  Future<void> init({required void Function(String? target) onTarget});

  Future<NotificationPermission> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Future<void> deleteToken();
}

/// Handler pesan FCM saat aplikasi di background atau tertutup.
/// Harus fungsi top-level dan didaftarkan di main() sebelum runApp.
/// Catatan: hanya dipanggil untuk pesan data-only; pesan "notification"
/// ditampilkan oleh sistem Android.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) debugPrint('FCM (background) id: ${message.messageId}');
}

/// Implementasi dengan Firebase Cloud Messaging + notifikasi lokal.
class FcmNotificationService implements NotificationService {
  FcmNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localPlugin,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = localPlugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'voca_general';
  static const String _channelName = 'Notifikasi Voca';
  static const String _channelDescription =
      'Pesan dan pengingat belajar dari Voca';

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  void Function(String? target)? _onTarget;
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  @override
  Future<void> init({required void Function(String? target) onTarget}) async {
    _onTarget = onTarget;
    if (_initialized) return;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      // Notifikasi lokal diketuk saat aplikasi masih hidup.
      onDidReceiveNotificationResponse: (response) =>
          _onTarget?.call(response.payload),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

    await _onMessageSub?.cancel();
    await _openedSub?.cancel();

    // Pesan FCM saat aplikasi terbuka: tampilkan sendiri.
    _onMessageSub = FirebaseMessaging.onMessage.listen(_showForeground);

    // Notifikasi diketuk saat aplikasi di background.
    _openedSub = FirebaseMessaging.onMessageOpenedApp
        .listen((message) => _onTarget?.call(_targetOf(message)));

    // Aplikasi dibuka dari keadaan tertutup lewat notifikasi.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onTarget?.call(_targetOf(initial));

    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _onTarget?.call(launch!.notificationResponse?.payload);
    }

    _initialized = true;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final settings = await _messaging.requestPermission();
    final status = settings.authorizationStatus;
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      return NotificationPermission.granted;
    }
    if (status == AuthorizationStatus.denied) {
      return NotificationPermission.denied;
    }
    return NotificationPermission.unknown;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  String? _targetOf(RemoteMessage message) =>
      message.data['target']?.toString();

  Future<void> _showForeground(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: _targetOf(message),
    );
  }
}
