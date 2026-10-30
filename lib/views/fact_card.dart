import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:dziesiatka/views/pill_badge.dart';
import 'package:flutter/material.dart';

/// Below this height, such as on a phone in landscape, the card tightens up.
const _compactHeight = 240.0;

class FactCard extends StatelessWidget {
  const FactCard({
    super.key,
    required this.fact,
    required this.onExpand,
    this.isReview = false,
  });

  final Fact fact;
  final VoidCallback onExpand;
  final bool isReview;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<AppSurfaces>()!;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < _compactHeight;
          return Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 28),
            child: _buildContent(context, isCompact: isCompact),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CategoryBadge(category: fact.category),
            if (isReview)
              PillBadge(
                icon: Icons.refresh_rounded,
                label: 'Powtórka',
                color: colors.onSecondaryContainer,
                background: colors.secondaryContainer,
              ),
          ],
        ),
        SizedBox(height: isCompact ? 8 : 24),
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
        SizedBox(height: isCompact ? 4 : 12),
        TextButton.icon(
          onPressed: onExpand,
          icon: const Icon(Icons.expand_less_rounded),
          label: const Text('Dowiedz się więcej'),
        ),
      ],
    );
  }
}
