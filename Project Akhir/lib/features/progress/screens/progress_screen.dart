import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/quiz_result.dart';
import '../../auth/widgets/logout_button.dart';
import '../../auth/widgets/profile_card.dart';
import '../../notification/widgets/reminder_tile.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../vocabulary/providers/favorites_provider.dart';
import '../../vocabulary/providers/vocabulary_provider.dart' show LoadStatus;
import '../providers/progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final favorites = context.watch<FavoritesProvider>();
    final progress = context.watch<ProgressProvider>();
    final last = progress.lastResult;

    // Tanda "-" selama data belum tersedia, supaya tidak tampil "0" palsu.
    final favoritesValue =
        favorites.status == LoadStatus.success ? '${favorites.count}' : '-';
    final completedValue = progress.status == LoadStatus.success
        ? '${progress.completedCount}'
        : '-';
    final lastValue =
        last == null ? '-' : '${last.score}/${last.totalQuestions}';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Progres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ===== 1. PROFIL (widget milik Anggota 1) =====
          const ProfileCard(),

          // ===== 2. PROGRES (milik Anggota 3) =====
          const SizedBox(height: AppSpacing.lg),
          Text('Progres belajar', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite,
                  value: favoritesValue,
                  label: 'Kata favorit',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.task_alt,
                  value: completedValue,
                  label: 'Kuis selesai',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  value: lastValue,
                  label: 'Skor terakhir',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuizScreen()),
            ),
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Mulai kuis'),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Pengingat belajar', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const ReminderTile(),

          const SizedBox(height: AppSpacing.lg),
          Text('Riwayat kuis', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _buildHistory(progress),

          // ===== 3. LOGOUT (widget milik Anggota 1) =====
          const SizedBox(height: AppSpacing.lg),
          const LogoutButton(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHistory(ProgressProvider progress) {
    switch (progress.status) {
      case LoadStatus.idle:
        return const StateMessage(
          icon: Icons.lock_outline,
          title: 'Masuk untuk melihat riwayat kuis',
        );
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadStatus.error:
        return Column(
          children: [
            StateMessage(
              icon: Icons.error_outline,
              color: AppColors.error,
              title: progress.error ?? 'Terjadi kesalahan.',
            ),
            OutlinedButton.icon(
              onPressed: progress.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        );
      case LoadStatus.success:
        final items = progress.recent;
        if (items.isEmpty) {
          return const StateMessage(
            icon: Icons.history,
            title: 'Belum ada kuis yang diselesaikan',
            subtitle: 'Kerjakan kuis pertamamu untuk melihat skor di sini.',
          );
        }
        return Column(
          children: [
            for (final result in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _HistoryItem(result: result),
              ),
          ],
        );
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: text.headlineMedium),
          Text(label, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = result.totalQuestions == 0
        ? 0
        : result.score * 100 ~/ result.totalQuestions;

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.score} / ${result.totalQuestions}',
                  style: text.titleMedium,
                ),
                Text(result.completedAt.displayDate, style: text.bodySmall),
              ],
            ),
          ),
          Text(
            '$percent%',
            style: text.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}