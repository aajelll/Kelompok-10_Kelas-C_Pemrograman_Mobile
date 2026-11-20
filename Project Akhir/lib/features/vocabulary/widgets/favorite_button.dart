import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../providers/favorites_provider.dart';

/// Tombol hati: tambah / hapus [entry] dari favorit.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(entry.word);

    return IconButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final error = await favorites.toggle(entry);
        if (error != null) {
          messenger.showSnackBar(SnackBar(content: Text(error)));
        }
      },
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: AppColors.primary,
      tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
    );
  }
}