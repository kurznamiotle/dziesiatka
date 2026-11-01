import 'dart:math';

import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/onboarding_service.dart';
import 'package:dziesiatka/services/reminder_service.dart';
import 'package:dziesiatka/services/supabase_fact_source.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/home_screen.dart';
import 'package:dziesiatka/views/phone_frame.dart';
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

  void _finishWelcome(BuildContext context) {
    onboardingService.markWelcomeSeen();
    // Asked here, once the user knows the app, and not on the first launch.
    reminderService?.requestPermission();
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
                builder: (context) =>
                    WelcomeScreen(onFinished: () => _finishWelcome(context)),
              )
            : _buildHome(),
      ),
    );
  }
}
