import 'package:dziesiatka/models/daily_deck.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  StreakService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _countKey = 'streakCount';
  static const _lastCompletedKey = 'streakLastCompleted';

  final DateTime Function() _now;

  /// Returns the running streak, which is 0 once a whole day has been missed.
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompleted = prefs.getString(_lastCompletedKey);
    if (lastCompleted == null || _daysSince(lastCompleted) > 1) return 0;
    return prefs.getInt(_countKey) ?? 0;
  }

  /// Counts today as completed. Calling it again on the same day does nothing.
  Future<void> recordCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompleted = prefs.getString(_lastCompletedKey);
    final daysSince = lastCompleted == null ? null : _daysSince(lastCompleted);
    if (daysSince == 0) return;

    final count = daysSince == 1 ? (prefs.getInt(_countKey) ?? 0) + 1 : 1;
    await prefs.setInt(_countKey, count);
    await prefs.setString(_lastCompletedKey, DailyDeck.dateKey(_now()));
  }

  /// Compares calendar days in UTC, so a daylight saving change cannot turn a
  /// day into 23 hours and hide a gap.
  int _daysSince(String dateKey) {
    final date = DateTime.parse(dateKey);
    final today = _now();
    return DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
  }
}
