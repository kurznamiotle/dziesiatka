import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_record.dart';
import 'package:dziesiatka/models/user_stats.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:dziesiatka/services/streak_service.dart';

/// Counts the numbers shown under a finished deck, all from data on the device.
class StatsService {
  const StatsService(
    this._factsService,
    this._streakService,
    this._quizHistoryService,
  );

  final FactsService _factsService;
  final StreakService _streakService;
  final QuizHistoryService _quizHistoryService;

  Future<UserStats> load() async {
    return summarize(
      facts: await _factsService.getFacts(),
      records: await _quizHistoryService.getRecords(),
      completedDays: await _streakService.getCompletedDays(),
    );
  }

  /// Records of facts that are gone are left out, so every number refers to
  /// facts the user can still see.
  UserStats summarize({
    required List<Fact> facts,
    required Map<String, QuizRecord> records,
    required List<String> completedDays,
  }) {
    final known = [for (final fact in facts) ?records[fact.id]];
    final categories = {
      for (final fact in facts)
        if (!fact.isWithdrawn) fact.category,
    };
    final readCategories = {
      for (final fact in facts)
        if (fact.isRead && categories.contains(fact.category)) fact.category,
    };
    return UserStats(
      daysCompleted: completedDays.toSet().length,
      factsRead: facts.where((fact) => fact.isRead).length,
      factsRemembered: known.where((record) => record.wasLastCorrect).length,
      answersGiven: known.fold(0, (sum, record) => sum + record.answered),
      answersCorrect: known.fold(0, (sum, record) => sum + record.correct),
      favoriteCategory: _favoriteCategory(facts),
      factsLiked: facts.where((fact) => fact.isFavorite).length,
      categoriesRead: readCategories.length,
      categoriesTotal: categories.length,
    );
  }

  /// On a tie the category first in alphabetical order wins, so the tile does
  /// not change between visits.
  String? _favoriteCategory(List<Fact> facts) {
    final likes = <String, int>{};
    for (final fact in facts.where((fact) => fact.isFavorite)) {
      likes.update(fact.category, (count) => count + 1, ifAbsent: () => 1);
    }
    if (likes.isEmpty) return null;

    final ranked = likes.entries.toList()
      ..sort((first, second) {
        final byLikes = second.value.compareTo(first.value);
        return byLikes != 0 ? byLikes : first.key.compareTo(second.key);
      });
    return ranked.first.key;
  }
}
