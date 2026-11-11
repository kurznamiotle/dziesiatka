import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/services/achievements_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';

/// The screen's sections, each with the kinds it holds in order.
const _sections = [
  ('Regularność', [AchievementKind.streak, AchievementKind.daysTotal]),
  (
    'Czytanie',
    [
      AchievementKind.factsRead,
      AchievementKind.categoriesRead,
      AchievementKind.favorites,
    ],
  ),
  (
    'Quizy i pamięć',
    [
      AchievementKind.perfectQuizzes,
      AchievementKind.remembered,
      AchievementKind.reviews,
      AchievementKind.perfectReviews,
    ],
  ),
  ('Dzielenie się', [AchievementKind.shares]),
];

/// The achievements of [kinds], grouped by kind in that order and from the
/// nearest goal to the farthest within a kind.
List<Achievement> _achievementsOf(List<AchievementKind> kinds) {
  return [
    for (final kind in kinds)
      ...Achievement.all.where((item) => item.kind == kind).toList()
        ..sort((first, second) => first.goal.compareTo(second.goal)),
  ];
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({
    super.key,
    this.achievementsService = const AchievementsService(),
  });

  final AchievementsService achievementsService;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Set<String>? _unlocked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await widget.achievementsService.getUnlockedIds();
    if (mounted) setState(() => _unlocked = unlocked);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;
    return Scaffold(
      appBar: AppBar(title: const Text('Osiągnięcia')),
      body: SafeArea(
        child: unlocked == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _Summary(
                    unlocked: Achievement.all
                        .where((item) => unlocked.contains(item.id))
                        .length,
                    total: Achievement.all.length,
                  ),
                  for (final (title, kinds) in _sections) ...[
                    _SectionHeader(title: title),
                    for (final achievement in _achievementsOf(kinds))
                      _AchievementTile(
                        achievement: achievement,
                        isUnlocked: unlocked.contains(achievement.id),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            'Odblokowane: $unlocked / $total',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          LinearProgressIndicator(
            value: total == 0 ? 0 : unlocked / total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isUnlocked});

  final Achievement achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUnlocked
        ? theme.extension<AppSurfaces>()!.streak
        : theme.colorScheme.onSurfaceVariant;
    return Opacity(
      opacity: isUnlocked ? 1 : 0.6,
      child: ListTile(
        leading: Icon(
          isUnlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
          color: color,
        ),
        title: Text(achievement.title),
        subtitle: Text(achievement.description),
        trailing: isUnlocked ? const Icon(Icons.check_rounded) : null,
      ),
    );
  }
}
