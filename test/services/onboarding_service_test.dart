import 'package:dziesiatka/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a new user sees the welcome screen', () async {
    expect(await const OnboardingService().shouldShowWelcome(), isTrue);
  });

  test('the welcome screen does not come back once seen', () async {
    await const OnboardingService().markWelcomeSeen();

    expect(await const OnboardingService().shouldShowWelcome(), isFalse);
  });
}
