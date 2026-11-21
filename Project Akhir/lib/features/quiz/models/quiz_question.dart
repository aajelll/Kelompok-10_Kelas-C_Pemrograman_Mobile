import 'dart:math';

import '../../../shared/models/vocabulary_entry.dart';

/// Jumlah pilihan jawaban per soal (1 benar + 3 pengecoh).
const int kQuizOptionCount = 4;

/// Satu soal: "apa arti kata [word]?" dengan [options] berisi definisi.
/// Memakai [VocabularyEntry] yang sudah ada, tanpa model kosakata baru.
class QuizQuestion {
  const QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
  });

  final String word;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];
}

/// Definisi utama sebuah kata: arti pertama yang tidak kosong.
String? _primaryDefinition(VocabularyEntry entry) {
  for (final m in entry.meanings) {
    final definition = m.definition.trim();
    if (definition.isNotEmpty) return definition;
  }
  return null;
}

/// Menyusun soal dari [entries].
///
/// Aturan agar tidak ambigu:
/// - kata tanpa definisi dibuang,
/// - kata kembar dibuang,
/// - kata yang definisinya sama dengan kata lain dibuang,
/// sehingga tiap soal punya tepat satu jawaban benar.
/// Mengembalikan daftar kosong jika data yang layak kurang dari
/// [kQuizOptionCount].
List<QuizQuestion> buildQuizQuestions(
  List<VocabularyEntry> entries, {
  required int count,
  required Random random,
}) {
  final seenWords = <String>{};
  final seenDefinitions = <String>{};
  final usable = <({String word, String definition})>[];

  for (final entry in entries) {
    final definition = _primaryDefinition(entry);
    if (definition == null) continue;
    if (!seenWords.add(entry.word.toLowerCase())) continue;
    if (!seenDefinitions.add(definition.toLowerCase())) continue;
    usable.add((word: entry.word, definition: definition));
  }

  if (usable.length < kQuizOptionCount) return const [];

  usable.shuffle(random);
  final total = min(count, usable.length);
  final questions = <QuizQuestion>[];

  for (var i = 0; i < total; i++) {
    final target = usable[i];
    final distractors = usable.where((u) => u.word != target.word).toList()
      ..shuffle(random);
    final options = <String>[
      target.definition,
      ...distractors.take(kQuizOptionCount - 1).map((u) => u.definition),
    ]..shuffle(random);

    questions.add(QuizQuestion(
      word: target.word,
      options: options,
      correctIndex: options.indexOf(target.definition),
    ));
  }
  return questions;
}
