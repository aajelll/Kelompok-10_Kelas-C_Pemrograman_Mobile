import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResult {
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'score': score,
        'totalQuestions': totalQuestions,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  factory QuizResult.fromMap(Map<String, dynamic> m) => QuizResult(
        score: m['score'] as int,
        totalQuestions: m['totalQuestions'] as int,
        completedAt: (m['completedAt'] as Timestamp).toDate(),
      );
}