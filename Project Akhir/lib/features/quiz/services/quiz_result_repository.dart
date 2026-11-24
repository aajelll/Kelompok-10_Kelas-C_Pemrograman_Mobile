import '../../../shared/models/quiz_result.dart';
import '../../../shared/services/firestore_collection_service.dart';
import '../../../shared/services/firestore_paths.dart';

/// Kontrak penyimpanan hasil kuis milik satu pengguna.
abstract interface class QuizResultRepository {
  Stream<List<QuizResult>> watchAll();
  Future<void> save(QuizResult result);
}

/// Lokasi: users/{uid}/quizResults/{id}.
class FirestoreQuizResultRepository implements QuizResultRepository {
  FirestoreQuizResultRepository(String uid)
      : _service = FirestoreCollectionService<QuizResult>(
          collection: FirestorePaths.quizResults(uid),
          fromMap: QuizResult.fromMap,
          toMap: (result) => result.toMap(),
        );

  final FirestoreCollectionService<QuizResult> _service;

  /// Riwayat kuis, terbaru di atas.
  @override
  Stream<List<QuizResult>> watchAll() =>
      _service.watchAll(orderBy: 'completedAt', descending: true);

  /// ID dokumen diturunkan dari waktu selesai, bukan acak. Alasannya: kalau
  /// penyimpanan lambat lalu pengguna menekan "coba lagi", hasil yang sama
  /// menimpa dokumen yang sama, jadi tidak muncul riwayat ganda.
  @override
  Future<void> save(QuizResult result) => _service.set(
        result.completedAt.microsecondsSinceEpoch.toString(),
        result,
      );
}
