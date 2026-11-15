import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Voca')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Siap belajar kata baru hari ini?', style: text.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Text('Kata hari ini', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          // TODO Anggota 2: ganti isi kartu ini dengan data dari Free Dictionary API
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('resilient', style: text.headlineMedium)),
                    IconButton(
                      onPressed: () {}, // TODO Anggota 2: favorit / unfavorite
                      icon: const Icon(Icons.favorite_border),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                Text('/rɪˈzɪliənt/', style: text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                Text('adjective', style: text.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('Able to recover quickly from difficulties.',
                    style: text.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '"She is a resilient person."',
                  style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, // TODO Anggota 2: buka WordDetailScreen
                    child: const Text('Lihat detail'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {}, // TODO Anggota 2: pindah ke tab Cari
                  icon: const Icon(Icons.search),
                  label: const Text('Cari kata'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {}, // TODO Anggota 3: buka halaman kuis
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
}