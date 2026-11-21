import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_message.dart';
import '../../../shared/models/quiz_result.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/logout_button.dart';
import '../../auth/widgets/profile_card.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../quiz/services/quiz_result_repository.dart';
import '../../vocabulary/providers/favorites_provider.dart';

/// Jumlah riwayat kuis yang ditampilkan di layar ini.
const int _kMaxHistoryItems = 10;

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // TODO Anggota 3 (langkah notifikasi): simpan pengaturan ini lewat
  // Firestore dan layanan pengingat.
  bool _reminderOn = true;

  // Riwayat kuis milik akun yang sedang masuk, diperbarui otomatis.
  StreamSubscription<List<QuizResult>>? _historySub;
  String? _historyUid;
  List<QuizResult> _history = const [];
  bool _historyLoaded = false;
  String? _historyError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenHistory(context.watch<AuthProvider>().uid);
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }

  /// Berlangganan riwayat kuis untuk [uid]. Dipanggil ulang saat akun berganti.
  void _listenHistory(String? uid) {
    if (uid == _historyUid) return;
    _historySub?.cancel();
    _historySub = null;
    _historyUid = uid;
    _history = const [];
    _historyLoaded = false;
    _historyError = null;
    if (uid == null) return;

    _historySub = FirestoreQuizResultRepository(uid).watchAll().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _history = list;
          _historyLoaded = true;
          _historyError = null;
        });
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() {
          _historyLoaded = true;
          _historyError = 'Periksa koneksi lalu buka ulang halaman ini.';
        });
      },
    );
  }

  void _openQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final favoriteCount = context.watch<FavoritesProvider>().count;

    final historyReady = _historyLoaded && _historyError == null;
    final quizCount = historyReady ? '${_history.length}' : '-';
    final lastScore = historyReady && _history.isNotEmpty
        ? '${_history.first.score}/${_history.first.totalQuestions}'
        : '-';

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
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite,
                  value: '$favoriteCount',
                  label: 'Kata favorit',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.task_alt,
                  value: quizCount,
                  label: 'Kuis selesai',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_outlined,
                  value: lastScore,
                  label: 'Skor terakhir',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _openQuiz,
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
                  trailing: const Text('19:00'), // TODO: time picker
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Riwayat kuis', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _buildHistory(),

          // ===== 3. LOGOUT (widget milik Anggota 1) =====
          const SizedBox(height: AppSpacing.lg),
          const LogoutButton(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_historyError != null) {
      return StateMessage(
        icon: Icons.error_outline,
        title: 'Riwayat kuis belum bisa dimuat',
        subtitle: _historyError,
        color: AppColors.error,
      );
    }
    if (!_historyLoaded) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_history.isEmpty) {
      return const StateMessage(
        icon: Icons.history,
        title: 'Belum ada kuis yang diselesaikan',
        subtitle: 'Kerjakan kuis pertamamu untuk melihat skor di sini.',
      );
    }

    final shown = _history.take(_kMaxHistoryItems).toList();
    return Column(
      children: [
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _HistoryTile(result: item),
          ),
      ],
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = result.totalQuestions;
    final percent = total == 0 ? 0 : (result.score * 100 / total).round();

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skor ${result.score} / ${result.totalQuestions}',
                  style: text.titleMedium,
                ),
                Text(_formatDate(result.completedAt), style: text.bodySmall),
              ],
            ),
          ),
          Text(
            '$percent%',
            style: text.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Format sederhana: 22/11/2026 01:30 (waktu setempat).
String _formatDate(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}
