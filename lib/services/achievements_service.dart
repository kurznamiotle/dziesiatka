import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/models/achievement_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsService {
  const AchievementsService();

  static const _unlockedKey = 'unlockedAchievements';
  static const _perfectQuizzesKey = 'perfectQuizCount';

  Future<Set<String>> getUnlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_unlockedKey) ?? const []).toSet();
  }

  /// Saves a finished day and returns only what it newly unlocked.
  Future<List<Achievement>> recordDay({
    required int streak,
    required int factsRead,
    required bool wasQuizPerfect,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final perfectQuizzes =
        (prefs.getInt(_perfectQuizzesKey) ?? 0) + (wasQuizPerfect ? 1 : 0);
    await prefs.setInt(_perfectQuizzesKey, perfectQuizzes);

    final progress = AchievementProgress(
      streak: streak,
      perfectQuizzes: perfectQuizzes,
      factsRead: factsRead,
    );
    final unlocked = await getUnlockedIds();
    final earned = Achievement.all
        .where((item) => !unlocked.contains(item.id))
        .where((item) => item.isReachedBy(progress))
        .toList();
    await prefs.setStringList(_unlockedKey, [
      ...unlocked,
      ...earned.map((item) => item.id),
    ]);
    return earned;
  }
}
