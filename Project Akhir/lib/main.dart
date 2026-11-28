import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'features/notification/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Harus didaftarkan sebelum runApp agar pesan saat background diterima.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Data nama hari dan bulan bahasa Indonesia untuk DateFormat.
  await initializeDateFormatting('id_ID');
  runApp(const VocaApp());
}