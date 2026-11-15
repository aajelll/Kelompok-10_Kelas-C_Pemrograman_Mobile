import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../auth/widgets/logout_button.dart';
import '../../auth/widgets/profile_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // TODO Anggota 3: baca dan simpan pengaturan ini lewat Firestore + ReminderService
  bool _reminderOn = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Progres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ===== 1. PROFIL (widget milik Anggota 1) =====
          const ProfileCard(),

          // ===== 2. PROGRES (milik Anggota 3) =====
          const SizedBox(height: AppSpacing.lg),
          Text('Progres belajar', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          // TODO Anggota 3: angka-angka ini harus dari Firestore, bukan statis
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                    icon: Icons.favorite, value: '0', label: 'Kata favorit'),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                    icon: Icons.task_alt, value: '0', label: 'Kuis selesai'),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                    icon: Icons.emoji_events_outlined,
                    value: '-',
                    label: 'Skor terakhir'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () {}, // TODO Anggota 3: buka halaman kuis
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Mulai kuis'),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Pengingat belajar', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Ingatkan saya belajar'),
                  subtitle: const Text('Setiap hari'),
                  value: _reminderOn,
                  onChanged: (v) => setState(() => _reminderOn = v),
                ),
                ListTile(
                  enabled: _reminderOn,
                  title: const Text('Waktu pengingat'),
                  trailing: const Text('19:00'), // TODO Anggota 3: time picker
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Riwayat kuis', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          // TODO Anggota 3: tampilkan riwayat nyata; ini untuk kondisi kosong
          const StateMessage(
            icon: Icons.history,
            title: 'Belum ada kuis yang diselesaikan',
            subtitle: 'Kerjakan kuis pertamamu untuk melihat skor di sini.',
          ),

          // ===== 3. LOGOUT (widget milik Anggota 1) =====
          const SizedBox(height: AppSpacing.lg),
          const LogoutButton(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: text.headlineMedium),
          Text(label, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
