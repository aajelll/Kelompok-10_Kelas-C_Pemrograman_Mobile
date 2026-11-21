import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home_shell.dart';
import 'features/quiz/providers/quiz_provider.dart';
import 'features/quiz/services/quiz_result_repository.dart';
import 'features/vocabulary/providers/favorites_provider.dart';
import 'features/vocabulary/providers/vocabulary_provider.dart';
import 'features/vocabulary/services/dictionary_api_service.dart';

class VocaApp extends StatelessWidget {
  const VocaApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => VocabularyProvider(DictionaryApiService()),
          ),
          // Harus setelah AuthProvider: ikut berganti saat UID berubah.
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
        ],
        child: MaterialApp(
          title: 'Voca',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
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