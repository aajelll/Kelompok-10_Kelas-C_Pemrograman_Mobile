import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kotak di dalam kartu dengan label kecil, mis. "Example" atau "Synonyms".
class InsetBox extends StatelessWidget {
  const InsetBox({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}