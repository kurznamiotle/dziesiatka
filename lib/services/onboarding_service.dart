import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  const OnboardingService();

  static const _welcomeSeenKey = 'welcomeSeen';

  /// Whether the welcome screen is still ahead of this user. A storage failure
  /// answers no, so it can never stand between the user and the deck.
  Future<bool> shouldShowWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_welcomeSeenKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  /// A failed save only shows the welcome screen once more on the next start.
  Future<void> markWelcomeSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeSeenKey, true);
    } catch (_) {}
  }
}
