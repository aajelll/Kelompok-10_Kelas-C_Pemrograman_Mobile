import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/vocabulary_entry.dart';
import '../providers/favorites_provider.dart';

/// Tombol bintang: tambah / hapus [entry] dari favorit.
/// Abu-abu saat belum favorit, biru (warna utama) saat sudah.
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
      icon: Icon(
        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
        size: 30,
      ),
      color: isFavorite ? AppColors.primary : AppColors.textSecondary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      tooltip: isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
    );
  }
}