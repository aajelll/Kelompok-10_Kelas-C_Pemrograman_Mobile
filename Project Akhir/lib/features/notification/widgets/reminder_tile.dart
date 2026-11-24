import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_card.dart';
import '../providers/reminder_provider.dart';

/// Kartu pengaturan pengingat harian di layar Profil & Progres.
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key});

  @override
  Widget build(BuildContext context) {
    final reminder = context.watch<ReminderProvider>();
    final s = reminder.settings;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Ingatkan saya belajar'),
            subtitle: Text(
              s.enabled ? 'Setiap hari pukul ${s.timeLabel}' : 'Nonaktif',
            ),
            value: s.enabled,
            onChanged: reminder.busy ? null : reminder.setEnabled,
          ),
          ListTile(
            enabled: s.enabled && !reminder.busy,
            title: const Text('Waktu pengingat'),
            trailing: Text(s.timeLabel),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
              );
              if (picked != null) {
                await reminder.setTime(picked.hour, picked.minute);
              }
            },
          ),
          if (reminder.permissionDenied)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Izin notifikasi ditolak. Aktifkan di Pengaturan > Aplikasi > '
                'Voca > Notifikasi, lalu coba lagi.',
              ),
            ),
          if (reminder.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Gagal: ${reminder.error}'),
            ),
        ],
      ),
    );
  }
}