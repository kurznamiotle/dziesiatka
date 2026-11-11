/// This user's answers to the quiz question of one fact. It stays on the
/// device, like the rest of the user's progress.
class QuizRecord {
  const QuizRecord({
    required this.answered,
    required this.correct,
    required this.wasLastCorrect,
    required this.lastAnsweredAt,
  });

  factory QuizRecord.fromJson(Map<String, dynamic> json) {
    final lastAnsweredAt = json['lastAnsweredAt'] as String?;
    return QuizRecord(
      answered: json['answered'] as int,
      correct: json['correct'] as int,
      wasLastCorrect: json['wasLastCorrect'] as bool,
      lastAnsweredAt: lastAnsweredAt == null
          ? null
          : DateTime.parse(lastAnsweredAt),
    );
  }

  /// The first answer to a question.
  factory QuizRecord.first({required bool isCorrect, required DateTime at}) {
    return const QuizRecord(
      answered: 0,
      correct: 0,
      wasLastCorrect: false,
      lastAnsweredAt: null,
    ).withAnswer(isCorrect: isCorrect, at: at);
  }

  /// How many times the question was answered, and how many of those were right.
  final int answered;
  final int correct;

  /// Whether the latest answer was right, so the fact counts as remembered.
  final bool wasLastCorrect;
  final DateTime? lastAnsweredAt;

  QuizRecord withAnswer({required bool isCorrect, required DateTime at}) {
    return QuizRecord(
      answered: answered + 1,
      correct: correct + (isCorrect ? 1 : 0),
      wasLastCorrect: isCorrect,
      lastAnsweredAt: at,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answered': answered,
      'correct': correct,
      'wasLastCorrect': wasLastCorrect,
      'lastAnsweredAt': lastAnsweredAt?.toIso8601String(),
    };
  }
}
