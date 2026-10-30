import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle._({
    required this.icon,
    required this.color,
    required this.background,
  });

  factory CategoryStyle.of(String category, Brightness brightness) {
    final palette = _palettes[category] ?? _customCategoryPalette;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? palette.darkColor : palette.lightColor;
    return CategoryStyle._(
      icon: palette.icon,
      color: color,
      background: color.withValues(alpha: isDark ? 0.16 : 0.12),
    );
  }

  static const _customCategoryPalette = _CategoryPalette(
    icon: Icons.auto_awesome_rounded,
    lightColor: Color(0xFF475569),
    darkColor: Color(0xFFCBD5E1),
  );

  static const _palettes = {
    'Kosmos': _CategoryPalette(
      icon: Icons.rocket_launch_rounded,
      lightColor: Color(0xFF3730A3),
      darkColor: Color(0xFFA5B4FC),
    ),
    'Zwierzęta': _CategoryPalette(
      icon: Icons.pets_rounded,
      lightColor: Color(0xFF166534),
      darkColor: Color(0xFF86EFAC),
    ),
    'Historia': _CategoryPalette(
      icon: Icons.account_balance_rounded,
      lightColor: Color(0xFF92400E),
      darkColor: Color(0xFFFCD34D),
    ),
    'Psychologia': _CategoryPalette(
      icon: Icons.psychology_rounded,
      lightColor: Color(0xFF9D174D),
      darkColor: Color(0xFFF9A8D4),
    ),
    'Technologia': _CategoryPalette(
      icon: Icons.memory_rounded,
      lightColor: Color(0xFF115E59),
      darkColor: Color(0xFF5EEAD4),
    ),
  };

  final IconData icon;
  final Color color;
  final Color background;
}

class _CategoryPalette {
  const _CategoryPalette({
    required this.icon,
    required this.lightColor,
    required this.darkColor,
  });

  final IconData icon;
  final Color lightColor;
  final Color darkColor;
}
