import 'dart:math';

import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/supabase_fact_source.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/home_screen.dart';
import 'package:dziesiatka/views/phone_frame.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loaded before the first frame, so the app never flashes the wrong theme.
  final themeService = ThemeService();
  await themeService.load();

  runApp(
    DziesiatkaApp(
      themeService: themeService,
      factsService: FactsService(remote: SupabaseFactSource.fromConfig()),
    ),
  );
}

class DziesiatkaApp extends StatelessWidget {
  const DziesiatkaApp({
    super.key,
    required this.themeService,
    this.factsService,
    this.now,
    this.random,
  });

  final ThemeService themeService;
  final FactsService? factsService;
  final DateTime Function()? now;
  final Random? random;

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
        home: HomeScreen(
          themeService: themeService,
          factsService: factsService,
          now: now,
          random: random,
        ),
      ),
    );
  }
}
