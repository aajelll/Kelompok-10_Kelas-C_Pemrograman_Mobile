import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Judul halaman dengan tombol kembali, untuk halaman yang dibuka dari
/// halaman lain (tanpa bar navigasi bawah).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}