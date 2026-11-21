import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

/// Layar kuis: memuat soal, menampilkan satu soal per layar, lalu
/// menampilkan [QuizResultScreen] setelah soal terakhir dijawab.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  /// Supaya hasil kuis lama tidak sempat terlihat sebelum sesi baru dimulai.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _started = true);
      context.read<QuizProvider>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    if (_started && quiz.phase == QuizPhase.finished) {
      return const QuizResultScreen();
    }

    final Widget body;
    if (!_started) {
      body = const _LoadingView();
    } else {
      switch (quiz.phase) {
        case QuizPhase.inProgress:
          body = _QuestionView(quiz: quiz);
        case QuizPhase.error:
          body = _ErrorView(message: quiz.error, onRetry: quiz.start);
        case QuizPhase.idle:
        case QuizPhase.loading:
        case QuizPhase.finished:
          body = const _LoadingView();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kuis')),
      body: SafeArea(child: body),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Menyiapkan soal...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StateMessage(
            icon: Icons.error_outline,
            title: 'Kuis belum bisa dimuat',
            subtitle: message,
            color: AppColors.error,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.quiz});

  final QuizProvider quiz;

  @override
  Widget build(BuildContext context) {
    final question = quiz.currentQuestion;
    if (question == null) return const _LoadingView();

    final text = Theme.of(context).textTheme;
    final selected = quiz.selectedIndex;
    final answered = quiz.isAnswered;
    final number = quiz.currentIndex + 1;
    final total = quiz.totalQuestions;
    final isCorrect = answered && selected == question.correctIndex;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Soal $number dari $total', style: text.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: number / total,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apa arti kata ini?', style: text.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(question.word, style: text.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < question.options.length; i++) ...[
                _OptionTile(
                  letter: String.fromCharCode(65 + i),
                  label: question.options[i],
                  state: _stateFor(i, question.correctIndex, selected),
                  onTap: answered ? null : () => quiz.select(i),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (answered)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    isCorrect
                        ? 'Benar!'
                        : 'Kurang tepat. Jawaban yang benar ditandai hijau.',
                    style: text.titleMedium?.copyWith(
                      color: isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton(
            onPressed: answered
                ? () {
                    quiz.next();
                  }
                : null,
            child: Text(quiz.isLastQuestion ? 'Lihat hasil' : 'Lanjut'),
          ),
        ),
      ],
    );
  }

  _OptionState _stateFor(int index, int correctIndex, int? selected) {
    if (selected == null) return _OptionState.idle;
    if (index == correctIndex) return _OptionState.correct;
    if (index == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    var border = const Color(0xFFE2E8F0);
    var fill = AppColors.surface;
    var accent = AppColors.primary;
    IconData? icon;
    var borderWidth = 1.0;

    if (state == _OptionState.correct) {
      border = AppColors.success;
      fill = const Color(0xFFDCFCE7);
      accent = AppColors.success;
      icon = Icons.check_circle;
      borderWidth = 2;
    } else if (state == _OptionState.wrong) {
      border = AppColors.error;
      fill = const Color(0xFFFEE2E2);
      accent = AppColors.error;
      icon = Icons.cancel;
      borderWidth = 2;
    } else if (state == _OptionState.dimmed) {
      accent = AppColors.textSecondary;
    }

    final dimmed = state == _OptionState.dimmed;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: borderWidth),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(letter, style: text.titleMedium?.copyWith(color: accent)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    color: dimmed ? AppColors.textSecondary : null,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
