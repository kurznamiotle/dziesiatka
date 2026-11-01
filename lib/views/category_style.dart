import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle._({
    required this.icon,
    required this.color,
    required this.background,
    required this.gradient,
  });

  factory CategoryStyle.of(String category, Brightness brightness) {
    final palette = _palettes[category] ?? _customCategoryPalette;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? palette.darkColor : palette.lightColor;
    return CategoryStyle._(
      icon: palette.icon,
      color: color,
      background: color.withValues(alpha: isDark ? 0.16 : 0.12),
      gradient: palette.gradient,
    );
  }

  static const _customCategoryPalette = _CategoryPalette(
    icon: Icons.auto_awesome_rounded,
    lightColor: Color(0xFF475569),
    darkColor: Color(0xFFCBD5E1),
    gradient: [Color(0xFF334155), Color(0xFF475569)],
  );

  static const _palettes = {
    'Kosmos': _CategoryPalette(
      icon: Icons.rocket_launch_rounded,
      lightColor: Color(0xFF3730A3),
      darkColor: Color(0xFFA5B4FC),
      gradient: [Color(0xFF3730A3), Color(0xFF6D28D9)],
    ),
    'Zwierzęta': _CategoryPalette(
      icon: Icons.pets_rounded,
      lightColor: Color(0xFF166534),
      darkColor: Color(0xFF86EFAC),
      gradient: [Color(0xFF14532D), Color(0xFF15803D)],
    ),
    'Historia': _CategoryPalette(
      icon: Icons.account_balance_rounded,
      lightColor: Color(0xFF92400E),
      darkColor: Color(0xFFFCD34D),
      gradient: [Color(0xFF78350F), Color(0xFFB45309)],
    ),
    'Psychologia': _CategoryPalette(
      icon: Icons.psychology_rounded,
      lightColor: Color(0xFF9D174D),
      darkColor: Color(0xFFF9A8D4),
      gradient: [Color(0xFF831843), Color(0xFFBE185D)],
    ),
    'Technologia': _CategoryPalette(
      icon: Icons.memory_rounded,
      lightColor: Color(0xFF115E59),
      darkColor: Color(0xFF5EEAD4),
      gradient: [Color(0xFF134E4A), Color(0xFF0F766E)],
    ),
    'Popkultura & Gry': _CategoryPalette(
      icon: Icons.sports_esports_rounded,
      lightColor: Color(0xFF86198F),
      darkColor: Color(0xFFF0ABFC),
      gradient: [Color(0xFF701A75), Color(0xFFA21CAF)],
    ),
    'Biznes & Pieniądze': _CategoryPalette(
      icon: Icons.payments_rounded,
      lightColor: Color(0xFF3F6212),
      darkColor: Color(0xFFBEF264),
      gradient: [Color(0xFF365314), Color(0xFF4D7C0F)],
    ),
    'Zagadki Codzienności': _CategoryPalette(
      icon: Icons.lightbulb_rounded,
      lightColor: Color(0xFF854D0E),
      darkColor: Color(0xFFFDE047),
      gradient: [Color(0xFF713F12), Color(0xFFA16207)],
    ),
    'Ciało & Jedzenie': _CategoryPalette(
      icon: Icons.restaurant_rounded,
      lightColor: Color(0xFFB91C1C),
      darkColor: Color(0xFFFCA5A5),
      gradient: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
    ),
    'Geografia & Miejsca': _CategoryPalette(
      icon: Icons.public_rounded,
      lightColor: Color(0xFF075985),
      darkColor: Color(0xFF7DD3FC),
      gradient: [Color(0xFF0C4A6E), Color(0xFF0369A1)],
    ),
    'Absurdy Prawa': _CategoryPalette(
      icon: Icons.gavel_rounded,
      lightColor: Color(0xFF7C2D12),
      darkColor: Color(0xFFFDBA74),
      gradient: [Color(0xFF7C2D12), Color(0xFFC2410C)],
    ),
    'Język & Symbole': _CategoryPalette(
      icon: Icons.translate_rounded,
      lightColor: Color(0xFF5B21B6),
      darkColor: Color(0xFFC4B5FD),
      gradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    ),
  };

  final IconData icon;
  final Color color;
  final Color background;

  /// Dark enough for white text, and the same in both themes, so a shared
  /// image looks identical whichever theme it was made in.
  final List<Color> gradient;
}

class _CategoryPalette {
  const _CategoryPalette({
    required this.icon,
    required this.lightColor,
    required this.darkColor,
    required this.gradient,
  });

  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  final List<Color> gradient;
}
