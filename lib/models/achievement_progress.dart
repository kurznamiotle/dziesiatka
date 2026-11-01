/// The numbers that achievements are measured against.
class AchievementProgress {
  const AchievementProgress({
    required this.streak,
    required this.perfectQuizzes,
    required this.factsRead,
  });

  final int streak;
  final int perfectQuizzes;
  final int factsRead;
}
