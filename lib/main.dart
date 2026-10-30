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

  runApp(DziesiatkaApp(themeService: themeService));
}

class DziesiatkaApp extends StatelessWidget {
  const DziesiatkaApp({super.key, required this.themeService});

  final ThemeService themeService;

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
        home: HomeScreen(themeService: themeService),
      ),
    );
  }
}
