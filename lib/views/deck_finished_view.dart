import 'package:flutter/material.dart';

/// Shown between the last card and the quiz, so the last card can still be
/// brought back. The quiz starts by itself after [countdown], unless the system
/// asks for reduced motion, in which case it waits for a tap.
class DeckFinishedView extends StatefulWidget {
  const DeckFinishedView({
    super.key,
    required this.onStartQuiz,
    required this.onUndo,
    this.countdown = const Duration(seconds: 3),
  });

  final VoidCallback onStartQuiz;
  final VoidCallback onUndo;
  final Duration countdown;

  @override
  State<DeckFinishedView> createState() => _DeckFinishedViewState();
}

class _DeckFinishedViewState extends State<DeckFinishedView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.countdown,
  )..addStatusListener(_onProgressStatus);

  /// Set once the user has decided, so nothing restarts the countdown later.
  bool _isDone = false;
  bool? _waitsForTap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final waitsForTap = MediaQuery.disableAnimationsOf(context);
    if (waitsForTap == _waitsForTap) return;
    _waitsForTap = waitsForTap;
    _restartCountdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Time in the background must not count, so the countdown starts over.
    _restartCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    super.dispose();
  }

  bool get _isInForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  void _restartCountdown() {
    _progress.reset();
    if (_isDone || _waitsForTap == true || !_isInForeground) return;
    _progress.forward();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _startQuiz();
  }

  void _startQuiz() {
    if (_isDone) return;
    _isDone = true;
    _progress.stop();
    widget.onStartQuiz();
  }

  void _undo() {
    if (_isDone) return;
    _isDone = true;
    _progress.stop();
    widget.onUndo();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.style_rounded, size: 56, color: colors.primary),
            const SizedBox(height: 20),
            Text(
              'Wszystkie karty za Tobą!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teraz krótki quiz z dzisiejszych ciekawostek.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => _CountdownButton(
                progress: _progress.value,
                onPressed: _startQuiz,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _undo,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Cofnij'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A large button that fills from the left while the countdown runs.
class _CountdownButton extends StatelessWidget {
  const _CountdownButton({required this.progress, required this.onPressed});

  final double progress;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: ColoredBox(
                  color: colors.onPrimary.withValues(alpha: 0.22),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text(
                      'Przejdź do quizu',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: colors.onPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
