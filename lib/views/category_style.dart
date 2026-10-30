import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle({required this.icon, required this.color});

  factory CategoryStyle.of(String category) {
    return _styles[category] ?? _customCategoryStyle;
  }

  static const _customCategoryStyle = CategoryStyle(
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF475569),
  );

  static const _styles = {
    'Kosmos': CategoryStyle(
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF3730A3),
    ),
    'Zwierzęta': CategoryStyle(
      icon: Icons.pets_rounded,
      color: Color(0xFF166534),
    ),
    'Historia': CategoryStyle(
      icon: Icons.account_balance_rounded,
      color: Color(0xFF92400E),
    ),
    'Psychologia': CategoryStyle(
      icon: Icons.psychology_rounded,
      color: Color(0xFF9D174D),
    ),
    'Technologia': CategoryStyle(
      icon: Icons.memory_rounded,
      color: Color(0xFF115E59),
    ),
  };

  final IconData icon;
  final Color color;

  Color get background => color.withValues(alpha: 0.12);
}
