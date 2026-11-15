import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Kata')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cari kata bahasa Inggris',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) {
              // TODO Anggota 2: panggil VocabularyProvider.search(...)
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Contoh tampilan hasil (sementara)', style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),

          // TODO Anggota 2: ganti dengan hasil nyata dari API, lengkap dengan
          // state loading / error / kosong (pakai StateMessage)
          AppCard(
            onTap: () {}, // TODO Anggota 2: buka WordDetailScreen
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ambiguous', style: text.titleMedium),
                      Text('/æmˈbɪɡjuəs/', style: text.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Open to more than one interpretation.',
                          style: text.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {}, // TODO Anggota 2: favorit / unfavorite
                  icon: const Icon(Icons.favorite_border),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}