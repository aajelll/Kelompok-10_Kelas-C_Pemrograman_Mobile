import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../providers/vocabulary_provider.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<VocabularyProvider>().search(_controller.text);
  }

  void _clear() {
    _controller.clear();
    context.read<VocabularyProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<VocabularyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Kata')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Cari kata bahasa Inggris',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Hapus',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildResult(vocab)),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(VocabularyProvider vocab) {
    switch (vocab.searchStatus) {
      case LoadStatus.idle:
        return const StateMessage(
          icon: Icons.menu_book_outlined,
          title: 'Mulai mencari kata',
          subtitle: 'Ketik kata lalu tekan tombol cari di keyboard.',
        );
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StateMessage(
                icon: Icons.error_outline,
                color: AppColors.error,
                title: vocab.searchError ?? 'Terjadi kesalahan.',
              ),
              OutlinedButton.icon(
                onPressed: () => vocab.search(vocab.query),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        final entry = vocab.searchResult;
        if (entry == null) {
          return const StateMessage(
            icon: Icons.search_off,
            title: 'Tidak ada hasil',
          );
        }
        return ListView(children: [_ResultCard(entry: entry)]);
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phonetic = entry.phonetic;
    final first = entry.meanings.isEmpty ? null : entry.meanings.first;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordDetailScreen(word: entry.word),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry.word, style: text.titleMedium))
              
            ],
          ),
          if (phonetic != null) Text(phonetic, style: text.bodySmall),
          if (first != null) ...[
            const SizedBox(height: AppSpacing.xs),
            if (first.partOfSpeech.isNotEmpty)
              Text(first.partOfSpeech, style: text.bodySmall),
            Text(first.definition, style: text.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Lihat detail',
              style: text.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}