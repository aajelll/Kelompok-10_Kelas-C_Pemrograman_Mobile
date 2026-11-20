import 'dart:async';

import 'package:voca/features/vocabulary/services/favorites_store.dart';
import 'package:voca/shared/models/vocabulary_entry.dart';

VocabularyEntry fakeEntry(String word) => VocabularyEntry(
      word: word,
      meanings: [
        WordMeaning(partOfSpeech: 'noun', definition: 'definisi $word'),
      ],
    );

/// Penyimpanan palsu: tes mengisi data lewat [controller].
class FakeFavoritesStore implements FavoritesStore {
  final controller = StreamController<List<VocabularyEntry>>.broadcast();
  final List<String> added = [];
  final List<String> removed = [];
  bool failWrites = false;

  @override
  Stream<List<VocabularyEntry>> watchAll() => controller.stream;

  @override
  Future<void> add(VocabularyEntry entry) async {
    if (failWrites) throw Exception('gagal menulis');
    added.add(entry.word);
  }

  @override
  Future<void> remove(String word) async {
    if (failWrites) throw Exception('gagal menulis');
    removed.add(word);
  }
}