import 'package:dziesiatka/models/daily_deck.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  StreakService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _countKey = 'streakCount';
  static const _lastCompletedKey = 'streakLastCompleted';

  /// Every finished day as `yyyy-mm-dd`. Older versions kept only the streak.
  static const _daysKey = 'streakDays';

  final DateTime Function() _now;

  /// Returns the running streak, which is 0 once a whole day has been missed.
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompleted = prefs.getString(_lastCompletedKey);
    if (lastCompleted == null || _daysSince(lastCompleted) > 1) return 0;
    return prefs.getInt(_countKey) ?? 0;
  }

  /// All days with a finished deck, oldest first.
  Future<List<String>> getCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    return _readDays(prefs);
  }

  /// Counts today as completed. Calling it again on the same day does nothing.
  Future<void> recordCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final days = _readDays(prefs);
    final today = DailyDeck.dateKey(_now());
    if (!days.contains(today)) {
      await prefs.setStringList(_daysKey, [...days, today]);
    }

    final lastCompleted = prefs.getString(_lastCompletedKey);
    final daysSince = lastCompleted == null ? null : _daysSince(lastCompleted);
    if (daysSince == 0) return;

    final count = daysSince == 1 ? (prefs.getInt(_countKey) ?? 0) + 1 : 1;
    await prefs.setInt(_countKey, count);
    await prefs.setString(_lastCompletedKey, today);
  }

  /// Versions before the list kept only the last streak, so its days are the
  /// least that is known to be finished.
  List<String> _readDays(SharedPreferences prefs) {
    final stored = prefs.getStringList(_daysKey);
    if (stored != null) return stored;

    final lastCompleted = prefs.getString(_lastCompletedKey);
    if (lastCompleted == null) return [];
    final last = DateTime.parse(lastCompleted);
    final count = prefs.getInt(_countKey) ?? 1;
    return [
      for (var back = count - 1; back >= 0; back--)
        DailyDeck.dateKey(DateTime(last.year, last.month, last.day - back)),
    ];
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
