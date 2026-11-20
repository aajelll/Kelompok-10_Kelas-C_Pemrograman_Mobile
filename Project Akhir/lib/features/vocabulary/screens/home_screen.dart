import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../providers/vocabulary_provider.dart';
import 'search_screen.dart';
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
    final vocab = context.watch<VocabularyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Voca')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Siap belajar kata baru hari ini?', style: text.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Text('Kata hari ini', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _buildDaily(vocab),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _open(const SearchScreen()),
                  icon: const Icon(Icons.search),
                  label: const Text('Cari kata'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _open(const QuizScreen()),
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Mulai kuis'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaily(VocabularyProvider vocab) {
    switch (vocab.dailyStatus) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const AppCard(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      case LoadStatus.error:
        return AppCard(
          child: Column(
            children: [
              StateMessage(
                icon: Icons.error_outline,
                color: AppColors.error,
                title: vocab.dailyError ?? 'Terjadi kesalahan.',
              ),
              OutlinedButton.icon(
                onPressed: () => vocab.loadDaily(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        final entry = vocab.dailyEntry;
        if (entry == null) {
          return const AppCard(
            child: StateMessage(
              icon: Icons.search_off,
              title: 'Kata hari ini tidak tersedia',
            ),
          );
        }
        return _DailyCard(
          entry: entry,
          onDetail: () => _open(WordDetailScreen(word: entry.word)),
        );
    }
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.entry, required this.onDetail});

  final VocabularyEntry entry;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phonetic = entry.phonetic;
    final first = entry.meanings.isEmpty ? null : entry.meanings.first;
    final example = first?.example;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.word, style: text.headlineMedium),
          if (phonetic != null) Text(phonetic, style: text.bodySmall),
          if (first != null) ...[
            const SizedBox(height: AppSpacing.md),
            if (first.partOfSpeech.isNotEmpty)
              Text(first.partOfSpeech, style: text.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(first.definition, style: text.bodyMedium),
          ],
          if (example != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '"$example"',
              style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDetail,
              child: const Text('Lihat detail'),
            ),
          ),
        ],
      ),
    );
  }
}