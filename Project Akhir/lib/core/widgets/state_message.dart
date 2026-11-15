import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pesan untuk kondisi kosong / error / info (ikon + judul + keterangan).
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color ?? AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!, style: text.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}