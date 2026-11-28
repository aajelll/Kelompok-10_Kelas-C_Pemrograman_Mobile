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
    final tint = color ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: tint),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: text.bodyMedium, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}