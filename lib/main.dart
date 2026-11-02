import 'dart:math';

import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/onboarding_service.dart';
import 'package:dziesiatka/services/reminder_service.dart';
import 'package:dziesiatka/services/supabase_fact_source.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/favorite_categories_screen.dart';
import 'package:dziesiatka/views/home_screen.dart';
import 'package:dziesiatka/views/phone_frame.dart';
import 'package:dziesiatka/views/usage_consent_dialog.dart';
import 'package:dziesiatka/views/welcome_screen.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loaded before the first frame, so the app never flashes the wrong theme.
  final themeService = ThemeService();
  await themeService.load();

  const onboardingService = OnboardingService();
  final showWelcome = await onboardingService.shouldShowWelcome();

  runApp(
    DziesiatkaApp(
      themeService: themeService,
      factsService: FactsService(remote: SupabaseFactSource.fromConfig()),
      reminderService: ReminderService(),
      usageService: UsageService.fromConfig(),
      showWelcome: showWelcome,
    ),
  );
}

class DziesiatkaApp extends StatelessWidget {
  const DziesiatkaApp({
    super.key,
    required this.themeService,
    this.factsService,
    this.reminderService,
    this.usageService,
    this.onboardingService = const OnboardingService(),
    this.showWelcome = false,
    this.now,
    this.random,
  });

  final ThemeService themeService;
  final FactsService? factsService;
  final ReminderService? reminderService;
  final UsageService? usageService;
  final OnboardingService onboardingService;
  final bool showWelcome;
  final DateTime Function()? now;
  final Random? random;

  Widget _buildHome() {
    return HomeScreen(
      themeService: themeService,
      factsService: factsService,
      reminderService: reminderService,
      usageService: usageService,
      now: now,
      random: random,
    );
  }

  void _openFavoriteCategories(BuildContext context, {required bool skipped}) {
    usageService?.instructionsLeft(skipped: skipped);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => FavoriteCategoriesScreen(
          factsService: factsService ?? FactsService(),
          onChosen: usageService?.categoriesChosen,
          onFinished: () => _finishWelcome(context),
        ),
      ),
    );
  }

  /// Asked here, once the user knows the app, and not on the first launch.
  Future<void> _askForNotifications() async {
    final reminders = reminderService;
    if (reminders == null || !reminders.isSupported) return;

    final isAllowed = await reminders.requestPermission();
    await usageService?.notificationsAnswered(isAllowed: isAllowed);
  }

  Future<void> _askForStatistics(BuildContext context) async {
    final usage = usageService;
    if (usage == null || !await usage.needsConsent() || !context.mounted) {
      return;
    }

    await usage.setEnabled(await UsageConsentDialog.show(context));
  }

  /// Marked only now, so leaving halfway shows the first-run screens again.
  Future<void> _finishWelcome(BuildContext context) async {
    onboardingService.markWelcomeSeen();
    _askForNotifications();
    await _askForStatistics(context);
    if (!context.mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => _buildHome()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) => MaterialApp(
        title: 'Dziesiątka',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeService.themeMode,
        // Above the navigator, so routes, dialogs and sheets stay in the frame.
        builder: (context, child) => PhoneFrame(child: child!),
        home: showWelcome
            ? Builder(
                builder: (context) => WelcomeScreen(
                  onFinished: () =>
                      _openFavoriteCategories(context, skipped: false),
                  onSkipped: () =>
                      _openFavoriteCategories(context, skipped: true),
                ),
              )
            : _buildHome(),
      ),
    );
  }
}
