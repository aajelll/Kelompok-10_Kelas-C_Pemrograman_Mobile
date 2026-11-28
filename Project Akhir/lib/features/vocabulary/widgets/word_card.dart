import 'package:flutter/material.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/highlighted_text.dart';
import '../../../core/widgets/inset_box.dart';
import '../../../shared/models/vocabulary_entry.dart';
import 'favorite_button.dart';

/// Kartu satu kata: kata, bintang favorit, fonetik, arti, dan contoh.
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.entry,
    this.onTap,
    this.showExample = true,
  });

  final VocabularyEntry entry;
  final VoidCallback? onTap;

  /// False untuk tampilan ringkas (mis. daftar favorit yang belum dibuka).
  final bool showExample;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phonetic = entry.phonetic;
    final definition =
        entry.meanings.isEmpty ? null : entry.meanings.first.definition;
    final example = entry.examples.isEmpty ? null : entry.examples.first;

    return AppCard(
      onTap: onTap,
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
          if (showExample && example != null) ...[
            const SizedBox(height: AppSpacing.md),
            InsetBox(
              label: 'Example',
              child: HighlightedText(text: example, keyword: entry.word),
            ),
          ],
        ],
      ),
    );
  }
}