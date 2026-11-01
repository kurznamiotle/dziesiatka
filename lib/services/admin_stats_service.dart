import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/category_performance.dart';
import 'package:dziesiatka/models/fact_performance.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/usage_row.dart';
import 'package:dziesiatka/models/usage_summary.dart';

/// Turns raw statistics into the numbers shown in the admin panel.
class AdminStatsService {
  const AdminStatsService();

  /// New facts a day: a deck without its one review.
  static const _newFactsPerDay = 9;

  /// Below this, a single reader decides a whole percentage.
  static const minShownForRanking = 5;
  static const minAnswersForQuizCheck = 5;
  static const _tooHardPercent = 35;
  static const _tooEasyPercent = 100;

  UsageSummary summarize(List<UsageRow> rows, {required DateTime today}) {
    final firstDays = <String, DateTime>{};
    for (final row in rows) {
      final first = firstDays[row.installId];
      if (first == null || row.day.isBefore(first)) {
        firstDays[row.installId] = row.day;
      }
    }
    final seen = {for (final row in rows) _key(row.installId, row.day)};

    final firstRows = rows.where((row) => row.day == firstDays[row.installId]);
    final quizTotal = rows.fold(0, (sum, row) => sum + (row.quizTotal ?? 0));
    final quizCorrect = rows.fold(
      0,
      (sum, row) => sum + (row.quizCorrect ?? 0),
    );

    return UsageSummary(
      days: _dailyUsage(rows),
      installs: firstDays.length,
      returnedAfterDay: _returnedAfter(1, firstDays, seen, today),
      returnedAfterWeek: _returnedAfter(7, firstDays, seen, today),
      quizCorrectPercent: quizTotal == 0 ? null : 100 * quizCorrect / quizTotal,
      bonusRounds: rows.fold(0, (sum, row) => sum + row.bonusRounds),
      finishedInstructions: _count(
        rows,
        (row) => row.instructions == 'finished',
      ),
      skippedInstructions: _count(rows, (row) => row.instructions == 'skipped'),
      choseAllCategories: _count(rows, (row) => row.choseAllCategories == true),
      choseFavorites: _count(rows, (row) => row.choseAllCategories == false),
      allowedNotifications: _count(
        rows,
        (row) => row.notificationsAllowed == true,
      ),
      deniedNotifications: _count(
        rows,
        (row) => row.notificationsAllowed == false,
      ),
      finishedFirstDeck: _count(firstRows, (row) => row.deckFinished),
    );
  }

  int _count(Iterable<UsageRow> rows, bool Function(UsageRow row) test) {
    return rows.where(test).length;
  }

  String _key(String installId, DateTime day) {
    return '$installId ${day.toIso8601String()}';
  }

  /// Counts only installs old enough to have had the chance to come back.
  double? _returnedAfter(
    int days,
    Map<String, DateTime> firstDays,
    Set<String> seen,
    DateTime today,
  ) {
    var eligible = 0;
    var returned = 0;
    firstDays.forEach((installId, first) {
      final target = first.add(Duration(days: days));
      if (target.isAfter(today)) return;
      eligible++;
      if (seen.contains(_key(installId, target))) returned++;
    });
    return eligible == 0 ? null : 100 * returned / eligible;
  }

  List<DailyUsage> _dailyUsage(List<UsageRow> rows) {
    final byDay = <DateTime, List<UsageRow>>{};
    for (final row in rows) {
      byDay.putIfAbsent(row.day, () => []).add(row);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days)
        DailyUsage(
          day: day,
          activeUsers: byDay[day]!.length,
          finishedDeck: _count(byDay[day]!, (row) => row.deckFinished),
          averageCards:
              byDay[day]!.fold(0, (sum, row) => sum + row.cardsCompleted) /
              byDay[day]!.length,
        ),
    ];
  }

  /// Facts with results, best liked first.
  List<FactPerformance> rankFacts(
    List<AdminFact> facts,
    Map<String, FactUsage> usage,
  ) {
    final ranked = [
      for (final fact in facts)
        if ((usage[fact.id]?.shown ?? 0) >= minShownForRanking)
          FactPerformance(fact: fact, usage: usage[fact.id]!),
    ];
    return ranked..sort((a, b) => b.likedPercent!.compareTo(a.likedPercent!));
  }

  /// Questions almost nobody gets right, or that nobody ever gets wrong. The
  /// first suggests a mistake or a trick, the second gives the answer away.
  List<FactPerformance> suspiciousQuestions(
    List<AdminFact> facts,
    Map<String, FactUsage> usage,
  ) {
    final suspicious =
        [
          for (final fact in facts)
            if (usage[fact.id] != null)
              FactPerformance(fact: fact, usage: usage[fact.id]!),
        ].where((item) => item.answers >= minAnswersForQuizCheck).where((item) {
          final percent = item.quizPercent!;
          return percent < _tooHardPercent || percent >= _tooEasyPercent;
        }).toList();
    return suspicious..sort((a, b) => a.quizPercent!.compareTo(b.quizPercent!));
  }

  /// Fewest days left first, as that is what needs attention.
  List<CategoryPerformance> categories(
    List<AdminFact> facts,
    Map<String, FactUsage> usage,
    Set<String> names,
  ) {
    final result = [
      for (final name in names)
        _category(
          name,
          facts.where((fact) => fact.category == name).toList(),
          usage,
          categoryCount: names.length,
        ),
    ];
    return result..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  }

  CategoryPerformance _category(
    String name,
    List<AdminFact> facts,
    Map<String, FactUsage> usage, {
    required int categoryCount,
  }) {
    final published = facts
        .where((fact) => fact.status == AdminFact.published)
        .length;
    final total = facts.fold(
      const FactUsage(),
      (sum, fact) => sum + (usage[fact.id] ?? const FactUsage()),
    );
    return CategoryPerformance(
      category: name,
      published: published,
      drafts: facts.where((fact) => fact.status == AdminFact.draft).length,
      daysLeft: published * categoryCount ~/ _newFactsPerDay,
      shown: total.shown,
      liked: total.liked,
      opened: total.opened,
    );
  }
}
