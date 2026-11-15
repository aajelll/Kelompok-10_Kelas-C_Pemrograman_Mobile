import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home_shell.dart';

class VocaApp extends StatelessWidget {
  const VocaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Voca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeShell(),
      );
}