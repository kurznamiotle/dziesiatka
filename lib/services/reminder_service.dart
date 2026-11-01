import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/services/local_reminder_scheduler.dart';
import 'package:dziesiatka/services/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plans the evening reminder. It must be planned in advance, because it has
/// to fire on the days the app is never opened, and it is removed from today
/// once the deck is finished.
class ReminderService {
  ReminderService({ReminderScheduler? scheduler, DateTime Function()? now})
    : _scheduler = scheduler ?? LocalReminderScheduler(),
      _now = now ?? DateTime.now;

  static const reminderHour = 18;
  static const daysAhead = 14;
  static const _enabledKey = 'remindersEnabled';

  final ReminderScheduler _scheduler;
  final DateTime Function() _now;
  bool _isDayFinished = false;
  String? _lastPlan;

  bool get isSupported => _scheduler.isSupported;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Asks for the system permission. A refusal only means no reminders.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final isAllowed = await _scheduler.requestPermission();
      _lastPlan = null;
      await update(isDayFinished: _isDayFinished);
      return isAllowed;
    } catch (_) {
      return false;
    }
  }

  /// Returns the resulting state, which stays off without the permission.
  Future<bool> setEnabled(bool isEnabled) async {
    final isAllowed = !isEnabled || await requestPermission();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, isEnabled && isAllowed);
    _lastPlan = null;
    await update(isDayFinished: _isDayFinished);
    return isEnabled && isAllowed;
  }

  /// Brings the planned reminders in line with today's progress. Reminders are
  /// a convenience, so a failure here must never reach the deck.
  Future<void> update({required bool isDayFinished}) async {
    _isDayFinished = isDayFinished;
    if (!isSupported) return;

    try {
      final today = DailyDeck.dateKey(_now());
      final isEnabled = await this.isEnabled();
      final plan = '$today $isDayFinished $isEnabled';
      if (plan == _lastPlan) return;

      await _scheduler.replaceAll(isEnabled ? _plannedTimes() : const []);
      _lastPlan = plan;
    } catch (_) {}
  }

  List<DateTime> _plannedTimes() {
    final now = _now();
    final isTodayOpen =
        !_isDayFinished &&
        now.isBefore(DateTime(now.year, now.month, now.day, reminderHour));
    final firstDay = isTodayOpen ? 0 : 1;
    return [
      for (var day = firstDay; day < firstDay + daysAhead; day++)
        DateTime(now.year, now.month, now.day + day, reminderHour),
    ];
  }
}
