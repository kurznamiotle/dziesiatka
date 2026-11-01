/// What the end of a day deserves. The [intensity] grows with the quiz score
/// and with streak milestones, from 0 for a calm finish to [maxIntensity].
class Celebration {
  const Celebration({
    required this.headline,
    required this.intensity,
    this.message,
  });

  /// Reads a finished day. [quizTotal] is 0 for a deck without questions.
  factory Celebration.forDay({
    required int? quizCorrect,
    required int quizTotal,
    required int streak,
  }) {
    final correct = quizCorrect ?? 0;
    final isPerfect = quizTotal > 0 && correct == quizTotal;
    final isGood = correct * 2 >= quizTotal && quizTotal > 0;
    final scorePoints = isPerfect ? 2 : (isGood ? 1 : 0);

    final isMilestone = streakMilestones.contains(streak);
    final milestonePoints = !isMilestone ? 0 : (streak >= 25 ? 2 : 1);

    return Celebration(
      headline: isPerfect ? 'WOW!' : (isGood ? 'Super!' : 'Dobra robota!'),
      intensity: (scorePoints + milestonePoints).clamp(0, maxIntensity),
      message: isMilestone ? 'Seria $streak dni! Tak trzymać!' : null,
    );
  }

  static const maxIntensity = 3;
  static const streakMilestones = {5, 10, 25, 50, 100};

  final String headline;
  final int intensity;
  final String? message;
}
