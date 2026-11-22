import 'package:dziesiatka/models/daily_deck.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-line invitation to tip, shown on a single day once the streak
/// reaches [minStreak]. Closing it or tipping ends it for good.
class TipInviteService {
  const TipInviteService({DateTime Function()? now}) : _now = now;

  static const minStreak = 7;
  static const _dayKey = 'tipInviteDay';
  static const _closedKey = 'tipInviteClosed';

  final DateTime Function()? _now;

  /// Says whether to show it today, and claims today the first time, so a
  /// later day never shows it again.
  Future<bool> claimForToday({
    required int streak,
    required bool hasTips,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_closedKey) ?? false) return false;

    final today = DailyDeck.dateKey((_now ?? DateTime.now)());
    final shownOn = prefs.getString(_dayKey);
    if (shownOn != null) return shownOn == today && hasTips;
    if (!hasTips || streak < minStreak) return false;

    await prefs.setString(_dayKey, today);
    return true;
  }

  Future<void> close() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_closedKey, true);
  }
}
