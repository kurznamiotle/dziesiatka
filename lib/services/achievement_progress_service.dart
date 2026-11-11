import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/models/achievement_progress.dart';
import 'package:dziesiatka/services/achievements_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:dziesiatka/services/stats_service.dart';
import 'package:dziesiatka/services/streak_service.dart';

/// Gathers the progress from where it is kept: the numbers about facts from
/// [StatsService], so they match the stats screen, and the counts from
/// [AchievementsService].
class AchievementProgressService {
  const AchievementProgressService(
    this._statsService,
    this._streakService,
    this._achievementsService,
  );

  /// Reads everything from this device's storage.
  factory AchievementProgressService.local({
    FactsService? factsService,
    AchievementsService achievementsService = const AchievementsService(),
    DateTime Function()? now,
  }) {
    final streakService = StreakService(now: now);
    return AchievementProgressService(
      StatsService(
        factsService ?? FactsService(),
        streakService,
        QuizHistoryService(now: now),
      ),
      streakService,
      achievementsService,
    );
  }

  final StatsService _statsService;
  final StreakService _streakService;
  final AchievementsService _achievementsService;

  Future<AchievementProgress> load() async {
    final stats = await _statsService.load();
    final counts = await _achievementsService.getCounts();
    return AchievementProgress(
      streak: await _streakService.getCurrentStreak(),
      daysTotal: stats.daysCompleted,
      factsRead: stats.factsRead,
      categoriesRead: stats.categoriesRead,
      categoriesTotal: stats.categoriesTotal,
      favorites: stats.factsLiked,
      perfectQuizzes: counts.perfectQuizzes,
      remembered: stats.factsRemembered,
      reviews: counts.reviews,
      perfectReviews: counts.perfectReviews,
      shares: counts.shares,
    );
  }

  /// Checks the current progress and returns what it newly unlocked.
  Future<List<Achievement>> unlockNew() async {
    return _achievementsService.checkProgress(await load());
  }
}
