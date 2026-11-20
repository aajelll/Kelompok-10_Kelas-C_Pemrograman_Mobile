import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

/// Kartu profil pengguna: avatar inisial, nama, email.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // TODO Anggota 1: ambil dari AuthProvider (displayName & email dari Firebase Auth)
    const name = 'Nama Pengguna';
    const email = 'email@contoh.com';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(email, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}