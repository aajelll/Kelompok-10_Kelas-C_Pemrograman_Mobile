import '../models/result.dart';
import '../models/vocabulary_entry.dart';

abstract class VocabularySource {
  Future<Result<VocabularyEntry>> fetchWord(String word);
}