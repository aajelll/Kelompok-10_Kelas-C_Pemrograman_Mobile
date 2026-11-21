import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../providers/quiz_provider.dart';

/// Hasil kuis: skor, status penyimpanan ke Firestore, ulangi atau kembali.
/// Ditampilkan oleh [QuizScreen] saat kuis selesai.
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final result = quiz.result;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Kuis')),
      body: SafeArea(
        child: result == null
            ? const StateMessage(
                icon: Icons.info_outline,
                title: 'Belum ada hasil kuis',
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(
                          _headline(result.score, result.totalQuestions),
                          style: text.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${result.score} / ${result.totalQuestions}',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text('jawaban benar', style: text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SaveStatusView(quiz: quiz),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () {
                      quiz.start();
                    },
                    child: const Text('Ulangi kuis'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
      ),
    );
  }

  String _headline(int score, int total) {
    if (total == 0) return 'Kuis selesai';
    final ratio = score / total;
    if (ratio >= 0.8) return 'Luar biasa!';
    if (ratio >= 0.5) return 'Bagus, terus berlatih!';
    return 'Ayo coba lagi!';
  }
}

class _SaveStatusView extends StatelessWidget {
  const _SaveStatusView({required this.quiz});

  final QuizProvider quiz;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    switch (quiz.saveStatus) {
      case SaveStatus.idle:
      case SaveStatus.saving:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Menyimpan hasil...', style: text.bodySmall),
          ],
        );
      case SaveStatus.saved:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 18, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text('Hasil tersimpan', style: text.bodySmall),
          ],
        );
      case SaveStatus.error:
        return Column(
          children: [
            Text(
              quiz.saveError ?? 'Hasil belum tersimpan.',
              style: text.bodySmall?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                quiz.retrySave();
              },
              child: const Text('Coba simpan lagi'),
            ),
          ],
        );
    }
  }
}
