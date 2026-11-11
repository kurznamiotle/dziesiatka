import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/models/achievement_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unlocked achievements and the counts that the facts cannot tell, such as
/// perfect quizzes and shares. All of it stays on the device, whether or not
/// the user agreed to anonymous statistics.
class AchievementsService {
  const AchievementsService();

  static const _unlockedKey = 'unlockedAchievements';
  static const _perfectQuizzesKey = 'perfectQuizCount';
  static const _reviewsKey = 'reviewCount';
  static const _perfectReviewsKey = 'perfectReviewCount';
  static const _sharesKey = 'shareCount';

  Future<Set<String>> getUnlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_unlockedKey) ?? const []).toSet();
  }

  /// Counts the quiz of a finished day. Called once per day.
  Future<void> recordQuiz({required bool wasPerfect}) async {
    if (wasPerfect) await _increment(_perfectQuizzesKey);
  }

  Future<void> recordReview({required bool wasPerfect}) async {
    await _increment(_reviewsKey);
    if (wasPerfect) await _increment(_perfectReviewsKey);
  }

  Future<void> recordShare() => _increment(_sharesKey);

  /// The counts kept here, as a progress with everything else at 0.
  Future<AchievementProgress> getCounts() async {
    final prefs = await SharedPreferences.getInstance();
    return AchievementProgress(
      perfectQuizzes: prefs.getInt(_perfectQuizzesKey) ?? 0,
      reviews: prefs.getInt(_reviewsKey) ?? 0,
      perfectReviews: prefs.getInt(_perfectReviewsKey) ?? 0,
      shares: prefs.getInt(_sharesKey) ?? 0,
    );
  }

  /// Saves every achievement that [progress] reaches and returns only those
  /// that were not unlocked before. The first check after an update unlocks
  /// what the user had already reached.
  Future<List<Achievement>> checkProgress(AchievementProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = (prefs.getStringList(_unlockedKey) ?? const []).toSet();
    final earned = Achievement.all
        .where((item) => !unlocked.contains(item.id))
        .where((item) => item.isReachedBy(progress))
        .toList();
    if (earned.isEmpty) return earned;

    await prefs.setStringList(_unlockedKey, [
      ...unlocked,
      ...earned.map((item) => item.id),
    ]);
    return earned;
  }

  Future<void> _increment(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }
}
