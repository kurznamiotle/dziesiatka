import 'dart:math';

import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/models/celebration.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';

const _particleCounts = [20, 60, 120, 220];
const _headlineSizes = [40.0, 56.0, 72.0, 88.0];
const _durations = [
  Duration(milliseconds: 2200),
  Duration(milliseconds: 2800),
  Duration(milliseconds: 3400),
  Duration(milliseconds: 4000),
];
const _durationWithAchievement = Duration(milliseconds: 4500);
const _particleColors = [
  Color(0xFF4F46E5),
  Color(0xFFDB2777),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF0EA5E9),
  Color(0xFFEF4444),
];

/// Bursts over the finished day and removes itself. It never takes a touch, so
/// nobody has to wait for it to end.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.celebration,
    required this.unlocked,
    required this.onFinished,
  });

  final Celebration celebration;
  final List<Achievement> unlocked;
  final VoidCallback onFinished;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late final List<_Particle> _particles;
  late final Animation<double> _fadeOut;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    final intensity = widget.celebration.intensity;
    final random = Random();
    _particles = [
      for (var i = 0; i < _particleCounts[intensity]; i++)
        _Particle.random(random, intensity),
    ];
    _progress = AnimationController(
      vsync: this,
      duration: widget.unlocked.isEmpty
          ? _durations[intensity]
          : _durationWithAchievement,
    );
    _fadeOut = ReverseAnimation(
      CurvedAnimation(parent: _progress, curve: const Interval(0.85, 1)),
    );
    _pop = CurvedAnimation(
      parent: _progress,
      curve: const Interval(0, 0.25, curve: Curves.elasticOut),
    );
    _progress.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showParticles = !MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      child: FadeTransition(
        opacity: _fadeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.82),
            ),
            if (showParticles)
              CustomPaint(painter: _ParticlePainter(_particles, _progress)),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ScaleTransition(scale: _pop, child: _buildMessage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    final theme = Theme.of(context);
    final celebration = widget.celebration;
    final message = celebration.message;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            celebration.headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: _headlineSizes[celebration.intensity],
              fontWeight: FontWeight.w900,
            ),
          ),
          if (message != null)
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.extension<AppSurfaces>()!.streak,
                fontWeight: FontWeight.w800,
              ),
            ),
          for (final achievement in widget.unlocked)
            _UnlockedBanner(achievement: achievement),
        ],
      ),
    );
  }
}

class _UnlockedBanner extends StatelessWidget {
  const _UnlockedBanner({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: colors.onSecondaryContainer,
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nowe osiągnięcie: ${achievement.title}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One piece of confetti, with its path given as fractions of the screen so
/// the burst fits any size.
class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  factory _Particle.random(Random random, int intensity) {
    return _Particle(
      angle: random.nextDouble() * 2 * pi,
      speed: (0.3 + random.nextDouble() * 0.7) * (0.6 + intensity * 0.2),
      spin: (random.nextDouble() - 0.5) * 20,
      size: 5 + random.nextDouble() * (5 + intensity * 2),
      color: _particleColors[random.nextInt(_particleColors.length)],
    );
  }

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.progress) : super(repaint: progress);

  static const _gravity = 1.1;

  final List<_Particle> particles;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final time = progress.value;
    // Fast at first and slower later, as if held back by the air.
    final travel = Curves.easeOutCubic.transform(time);
    final paint = Paint();
    for (final particle in particles) {
      final x = 0.5 + cos(particle.angle) * particle.speed * travel * 0.8;
      final y =
          0.45 +
          sin(particle.angle) * particle.speed * travel * 0.5 +
          _gravity * time * time * 0.5;

      paint.color = particle.color;
      canvas
        ..save()
        ..translate(x * size.width, y * size.height)
        ..rotate(particle.spin * time)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => false;
}
