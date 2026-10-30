import 'package:dziesiatka/views/category_style.dart';
import 'package:dziesiatka/views/pill_badge.dart';
import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category, Theme.of(context).brightness);
    return PillBadge(
      icon: style.icon,
      label: category,
      color: style.color,
      background: style.background,
    );
  }
}
