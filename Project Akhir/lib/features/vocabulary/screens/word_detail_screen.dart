import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../providers/vocabulary_provider.dart';

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
      _started = true;
      context.read<VocabularyProvider>().loadDetail(widget.word);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<VocabularyProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.word)),
      body: _buildBody(vocab),
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
              icon: Icons.error_outline,
              color: AppColors.error,
              title: vocab.detailError ?? 'Terjadi kesalahan.',
            ),
            OutlinedButton.icon(
              onPressed: () => vocab.loadDetail(widget.word),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final text = Theme.of(context).textTheme;
    final phonetic = entry.phonetic;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(entry.word, style: text.headlineMedium))
                
                ],
              ),
              if (phonetic != null) Text(phonetic, style: text.bodySmall),
              ..._meaningWidgets(text, entry.meanings),
            ],
          ),
        ),
      ],
    );
  }

  /// Menampilkan arti; judul jenis kata muncul sekali per kelompok.
  List<Widget> _meaningWidgets(TextTheme text, List<WordMeaning> meanings) {
    final widgets = <Widget>[];
    String? lastPartOfSpeech;

    for (final m in meanings) {
      if (m.partOfSpeech != lastPartOfSpeech) {
        widgets.add(const SizedBox(height: AppSpacing.md));
        if (m.partOfSpeech.isNotEmpty) {
          widgets.add(Text(
            m.partOfSpeech,
            style: text.titleMedium?.copyWith(
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ));
        }
        lastPartOfSpeech = m.partOfSpeech;
      }

      widgets.add(const SizedBox(height: AppSpacing.xs));
      widgets.add(Text(m.definition, style: text.bodyMedium));

      final example = m.example;
      if (example != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            '"$example"',
            style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ));
      }
    }
    return widgets;
  }
}