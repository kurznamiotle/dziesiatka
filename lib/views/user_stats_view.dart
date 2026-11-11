import 'package:dziesiatka/models/user_stats.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';

/// "Twoje statystyki": four tiles under a finished deck.
class UserStatsView extends StatelessWidget {
  const UserStatsView({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = stats.accuracyPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Text(
          'Twoje statystyki',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        _TileRow(
          first: _StatTile(
            icon: Icons.calendar_month_rounded,
            value: '${stats.daysCompleted}',
            label: 'Dni z Dziesiątką',
          ),
          second: _StatTile(
            icon: Icons.menu_book_rounded,
            value: '${stats.factsRead}',
            label: 'Przeczytane ciekawostki',
          ),
        ),
        _TileRow(
          first: _StatTile(
            icon: Icons.psychology_rounded,
            value: '${stats.factsRemembered}',
            label: 'Zapamiętane',
            caption: accuracy == null
                ? 'Odpowiedz w quizie'
                : '$accuracy% trafnych odpowiedzi',
          ),
          second: _StatTile(
            icon: Icons.favorite_rounded,
            value: stats.favoriteCategory ?? '–',
            label: 'Ulubiona kategoria',
            isTextValue: true,
          ),
        ),
      ],
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Expanded(child: first),
          Expanded(child: second),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.caption,
    this.isTextValue = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? caption;

  /// A word rather than a number, set smaller so a long name fits.
  final bool isTextValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaces = theme.extension<AppSurfaces>()!;
    final caption = this.caption;
    final valueStyle = isTextValue
        ? theme.textTheme.titleMedium
        : theme.textTheme.headlineSmall;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaces.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaces.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (caption != null)
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
