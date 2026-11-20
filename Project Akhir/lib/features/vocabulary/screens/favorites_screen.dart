import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../providers/favorites_provider.dart';
import '../providers/vocabulary_provider.dart' show LoadStatus;
import 'word_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _remove(BuildContext context, VocabularyEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<FavoritesProvider>().toggle(entry);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kata Favorit')),
      body: _buildBody(context, favorites),
    );
  }

  Widget _buildBody(BuildContext context, FavoritesProvider favorites) {
    switch (favorites.status) {
      case LoadStatus.idle:
        return const StateMessage(
          icon: Icons.lock_outline,
          title: 'Masuk untuk melihat kata favorit',
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
                title: favorites.error ?? 'Terjadi kesalahan.',
              ),
              OutlinedButton.icon(
                onPressed: favorites.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        if (favorites.items.isEmpty) {
          return const StateMessage(
            icon: Icons.favorite_border,
            title: 'Belum ada kata favorit',
            subtitle: 'Ketuk ikon hati pada sebuah kata untuk menyimpannya.',
          );
        }
        return _buildList(context, favorites.items);
    }
  }

  Widget _buildList(BuildContext context, List<VocabularyEntry> items) {
    final text = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final entry = items[i];
        final first = entry.meanings.isEmpty ? null : entry.meanings.first;

        return AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WordDetailScreen(word: entry.word),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.word, style: text.titleMedium),
                    if (first != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(first.definition, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _remove(context, entry),
                icon: const Icon(Icons.favorite),
                color: AppColors.primary,
                tooltip: 'Hapus dari favorit',
              ),
            ],
          ),
        );
      },
    );
  }
}