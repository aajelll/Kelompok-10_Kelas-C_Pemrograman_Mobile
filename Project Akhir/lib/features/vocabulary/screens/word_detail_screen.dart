import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/highlighted_text.dart';
import '../../../core/widgets/inset_box.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/favorite_button.dart';

/// Detail satu kata. Argumen: kata yang ingin ditampilkan.
class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, required this.word});

  final String word;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  // Mencegah data kata sebelumnya tampil sekilas sebelum load dimulai.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _started = true);
      context.read<VocabularyProvider>().loadDetail(widget.word);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<VocabularyProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Detail Kata'),
            Expanded(child: _buildBody(vocab)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(VocabularyProvider vocab) {
    if (!_started || vocab.detailStatus == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final entry = vocab.detailEntry;
    if (vocab.detailStatus == LoadStatus.error || entry == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateMessage(
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
              title: vocab.detailError ?? 'Terjadi kesalahan.',
            ),
            OutlinedButton.icon(
              onPressed: () => vocab.loadDetail(widget.word),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [_DetailCard(entry: entry)],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phonetic = entry.phonetic;
    final definition =
        entry.meanings.isEmpty ? null : entry.meanings.first.definition;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(entry.word.capitalized, style: text.headlineMedium),
              ),
              FavoriteButton(entry: entry),
            ],
          ),
          if (phonetic != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              phonetic,
              style: text.bodyLarge?.copyWith(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (definition != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(definition, style: text.bodyMedium),
          ],
          if (entry.examples.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            InsetBox(
              label: 'Examples',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entry.examples.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : AppSpacing.md,
                      ),
                      child: HighlightedText(
                        text: entry.examples[i],
                        keyword: entry.word,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (entry.synonyms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            InsetBox(
              label: 'Synonyms',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entry.synonyms.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : AppSpacing.md,
                      ),
                      child: Text(entry.synonyms[i], style: text.bodyMedium),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}