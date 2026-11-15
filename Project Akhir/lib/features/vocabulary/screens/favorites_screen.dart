import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // TODO Anggota 2: hapus daftar statis ini, ganti dengan stream favorit dari Firestore
  static const _sample = [
    ('resilient', 'Able to recover quickly from difficulties.'),
    ('ambiguous', 'Open to more than one interpretation.'),
    ('diligent', 'Having or showing care in one\'s work.'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // TODO Anggota 2: jika kosong, tampilkan StateMessage ("Belum ada kata favorit")
    return Scaffold(
      appBar: AppBar(title: const Text('Kata Favorit')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _sample.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (word, meaning) = _sample[i];
          return AppCard(
            onTap: () {}, // TODO Anggota 2: buka WordDetailScreen
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word, style: text.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(meaning, style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {}, // TODO Anggota 2: hapus dari favorit
                  icon: const Icon(Icons.favorite),
                  color: AppColors.primary,
                  tooltip: 'Hapus dari favorit',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
