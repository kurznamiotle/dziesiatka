import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:flutter/material.dart';

class FactCard extends StatelessWidget {
  const FactCard({super.key, required this.fact, required this.onExpand});

  final Fact fact;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaces = theme.extension<AppSurfaces>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: surfaces.border),
        boxShadow: [
          BoxShadow(
            color: surfaces.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryBadge(category: fact.category),
            const SizedBox(height: 24),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fact.title,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fact.shortText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 18,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onExpand,
              icon: const Icon(Icons.expand_less_rounded),
              label: const Text('Dowiedz się więcej'),
            ),
          ],
        ),
      ),
    );
  }
}
