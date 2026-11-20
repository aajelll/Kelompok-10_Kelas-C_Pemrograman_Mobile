import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home_shell.dart';
import 'features/vocabulary/providers/vocabulary_provider.dart';
import 'features/vocabulary/services/dictionary_api_service.dart';

class VocaApp extends StatelessWidget {
  const VocaApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => VocabularyProvider(DictionaryApiService()),
          ),
        ],
        child: MaterialApp(
          title: 'Voca',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeShell(),
        ),
      );
}