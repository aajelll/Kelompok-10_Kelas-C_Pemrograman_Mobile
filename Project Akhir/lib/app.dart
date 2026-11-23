import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home_shell.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/notification/providers/reminder_provider.dart';
import 'features/notification/services/notification_service.dart';
import 'features/notification/services/reminder_scheduler.dart';
import 'features/notification/services/reminder_store.dart';
import 'features/progress/providers/progress_provider.dart';
import 'features/quiz/providers/quiz_provider.dart';
import 'features/quiz/screens/quiz_screen.dart';
import 'features/quiz/services/quiz_result_repository.dart';
import 'features/vocabulary/providers/favorites_provider.dart';
import 'features/vocabulary/providers/vocabulary_provider.dart';
import 'features/vocabulary/services/dictionary_api_service.dart';

/// Kunci navigator global: dipakai membuka layar dari ketukan notifikasi.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void _openFromNotification(String target) {
  if (target != kQuizTarget) return;
  appNavigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => const QuizScreen()),
  );
}

class VocaApp extends StatelessWidget {
  const VocaApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => VocabularyProvider(DictionaryApiService()),
          ),
          // Proxy di bawah ini harus setelah AuthProvider: ikut berganti saat
          // UID berubah.
          ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
            create: (_) => FavoritesProvider(),
            update: (_, auth, favorites) => favorites!..updateUser(auth.uid),
          ),
          ChangeNotifierProxyProvider<AuthProvider, QuizProvider>(
            create: (_) => QuizProvider(
              DictionaryApiService(),
              storeFactory: FirestoreQuizResultRepository.new,
            ),
            update: (_, auth, quiz) => quiz!..updateUser(auth.uid),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ProgressProvider>(
            create: (_) => ProgressProvider(),
            update: (_, auth, progress) => progress!..updateUser(auth.uid),
          ),
          ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
            // Harus aktif sejak login, bukan baru saat pertama kali dibaca.
            lazy: false,
            create: (_) => NotificationProvider(
              FcmNotificationService(),
              onNavigate: _openFromNotification,
            ),
            update: (_, auth, notifications) =>
                notifications!..updateUser(auth.uid),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ReminderProvider>(
            // Menjadwalkan ulang pengingat harian begitu user login.
            lazy: false,
            create: (_) => ReminderProvider(
              LocalReminderScheduler(),
              FirestoreReminderStore(),
            ),
            update: (_, auth, reminder) => reminder!..updateUser(auth.uid),
          ),
        ],
        child: MaterialApp(
          title: 'Voca',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          navigatorKey: appNavigatorKey,
          home: const _AuthGate(),
        ),
      );
}

/// Menampilkan layar login atau HomeShell sesuai status login.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}