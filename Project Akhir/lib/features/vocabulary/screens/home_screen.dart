import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/word_card.dart';
import 'word_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ditunda sampai frame pertama selesai: Provider memanggil
    // notifyListeners(), yang tidak boleh terjadi saat widget dibangun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VocabularyProvider>().loadDaily();
    });
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = context.watch<AuthProvider>().displayName;
    final vocab = context.watch<VocabularyProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            Text(
              DateTime.now().dayAndMonth,
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              name.isEmpty ? 'Hi!' : 'Hi, $name!',
              style: text.headlineLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Siap belajar kata baru hari ini?',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildDaily(vocab),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => _open(const QuizScreen()),
              child: const Text('Mulai Kuis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaily(VocabularyProvider vocab) {
    switch (vocab.dailyStatus) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadStatus.error:
        return Column(
          children: [
            StateMessage(
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
              title: vocab.dailyError ?? 'Terjadi kesalahan.',
            ),
            OutlinedButton.icon(
              onPressed: vocab.loadDaily,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        );
      case LoadStatus.success:
        final entry = vocab.dailyEntry;
        if (entry == null) {
          return const StateMessage(
            icon: Icons.search_off_rounded,
            title: 'Kata hari ini tidak tersedia',
          );
        }
        return WordCard(
          entry: entry,
          onTap: () => _open(WordDetailScreen(word: entry.word)),
        );
    }
  }
}