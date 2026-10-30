import 'package:dziesiatka/services/theme_service.dart';
import 'package:flutter/material.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final (icon, tooltip) = switch (themeService.themeMode) {
          ThemeMode.system => (
            Icons.brightness_auto_rounded,
            'Motyw: zgodny z systemem',
          ),
          ThemeMode.light => (Icons.light_mode_rounded, 'Motyw: jasny'),
          ThemeMode.dark => (Icons.dark_mode_rounded, 'Motyw: ciemny'),
        };
        return IconButton(
          tooltip: tooltip,
          onPressed: themeService.cycleThemeMode,
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          icon: Icon(icon),
        );
      },
    );
  }
}
