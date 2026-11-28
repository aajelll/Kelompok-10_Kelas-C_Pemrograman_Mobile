import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_message.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/word_card.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _debounceDuration = Duration(milliseconds: 500);

  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Mencari otomatis setelah pengguna berhenti mengetik sebentar.
  void _onChanged(String value) {
    _debounce?.cancel();
    final vocab = context.read<VocabularyProvider>();
    if (value.trim().isEmpty) {
      vocab.clearSearch();
      return;
    }
    _debounce = Timer(_debounceDuration, () {
      if (mounted) vocab.search(value);
    });
  }

  void _submit(String value) {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    context.read<VocabularyProvider>().search(value);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<VocabularyProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final vocab = context.watch<VocabularyProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _submit,
                decoration: InputDecoration(
                  hintText: 'Cari kata',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: _clear,
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Hapus',
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildResult(vocab)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(VocabularyProvider vocab) {
    switch (vocab.searchStatus) {
      case LoadStatus.idle:
        return const _EmptySearch();
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        // Kata tidak ada di kamus: tampilan kosong yang sama dengan awal.
        if (vocab.searchNotFound) return const _EmptySearch();
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StateMessage(
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                title: vocab.searchError ?? 'Terjadi kesalahan.',
              ),
              OutlinedButton.icon(
                onPressed: () => vocab.search(vocab.query),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        final entry = vocab.searchResult;
        if (entry == null) return const _EmptySearch();
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            WordCard(
              entry: entry,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WordDetailScreen(word: entry.word),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const StateMessage(
      icon: Icons.search_off_rounded,
      title: 'Tidak ada kata yang sesuai',
      subtitle: 'Mulai mencari atau masukkan kata yang benar',
    );
  }
}