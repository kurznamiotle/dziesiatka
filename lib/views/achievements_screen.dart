import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/services/achievements_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';

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
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final achievement in Achievement.all)
                    _AchievementTile(
                      achievement: achievement,
                      isUnlocked: unlocked.contains(achievement.id),
                    ),
                ],
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
