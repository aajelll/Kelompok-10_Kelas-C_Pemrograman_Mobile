import '../../../shared/models/vocabulary_entry.dart';
import '../../../shared/services/firestore_collection_service.dart';
import '../../../shared/services/firestore_paths.dart';

/// Kontrak penyimpanan favorit milik satu pengguna.
abstract interface class FavoritesStore {
  Stream<List<VocabularyEntry>> watchAll();
  Future<void> add(VocabularyEntry entry);
  Future<void> remove(String word);
}

/// Implementasi Firestore: users/{uid}/favorites/{kata huruf kecil}.
class FirestoreFavoritesStore implements FavoritesStore {
  FirestoreFavoritesStore(String uid)
      : _service = FirestoreCollectionService<VocabularyEntry>(
          collection: FirestorePaths.favorites(uid),
          fromMap: VocabularyEntry.fromMap,
          toMap: (entry) => entry.toMap(),
        );

  final FirestoreCollectionService<VocabularyEntry> _service;

  @override
  Stream<List<VocabularyEntry>> watchAll() => _service.watchAll();

  @override
  Future<void> add(VocabularyEntry entry) =>
      _service.set(_id(entry.word), entry);

  @override
  Future<void> remove(String word) => _service.delete(_id(word));

  String _id(String word) => word.trim().toLowerCase();
}