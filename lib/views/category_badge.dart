import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:dziesiatka/views/pill_badge.dart';
import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.solid = false});

  final String category;

  /// Uses an opaque background, for placing the badge on a category gradient.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = CategoryStyle.of(category, theme.brightness);
    return PillBadge(
      icon: style.icon,
      label: category,
      color: style.color,
      background: solid
          ? theme.extension<AppSurfaces>()!.card
          : style.background,
    );
  }
}
