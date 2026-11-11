import 'dart:async';
import 'dart:math';

import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/models/celebration.dart';
import 'package:dziesiatka/models/daily_session.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/user_stats.dart';
import 'package:dziesiatka/services/achievements_service.dart';
import 'package:dziesiatka/services/app_links.dart';
import 'package:dziesiatka/services/daily_deck_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/haptics_service.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/services/quick_review_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:dziesiatka/services/reminder_service.dart';
import 'package:dziesiatka/services/stats_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:dziesiatka/views/achievements_screen.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/celebration_overlay.dart';
import 'package:dziesiatka/views/daily_quiz_screen.dart';
import 'package:dziesiatka/views/daily_review_screen.dart';
import 'package:dziesiatka/views/deck_finished_view.dart';
import 'package:dziesiatka/views/fact_card.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:dziesiatka/views/favorites_screen.dart';
import 'package:dziesiatka/views/quick_review_screen.dart';
import 'package:dziesiatka/views/settings_screen.dart';
import 'package:dziesiatka/views/user_stats_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _visibleCards = 3;
const _stackOffset = 14.0;
const _stackScaleStep = 0.05;
const _maxRotation = 0.2;
const _dismissThreshold = 0.3;
const _flingVelocity = 700.0;
const _flyOutDistance = 1.5;
const _dismissDuration = Duration(milliseconds: 240);
const _returnDuration = Duration(milliseconds: 200);
const _likeColor = Color(0xFF15803D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeService,
    this.factsService,
    this.reminderService,
    this.usageService,
    this.achievementsService = const AchievementsService(),
    this.linkService = const LinkService(),
    this.offersAppDownload = kIsWeb,
    this.now,
    this.random,
  });

  final ThemeService themeService;
  final FactsService? factsService;
  final ReminderService? reminderService;
  final UsageService? usageService;
  final AchievementsService achievementsService;
  final LinkService linkService;

  /// The web demo points to the app after a finished deck.
  final bool offersAppDownload;
  final DateTime Function()? now;
  final Random? random;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _factsService = widget.factsService ?? FactsService();
  late final _streakService = StreakService(now: widget.now);
  late final _quizHistory = QuizHistoryService(now: widget.now);
  late final _deckService = DailyDeckService(
    _factsService,
    _streakService,
    now: widget.now,
    random: widget.random,
  );
  late final _statsService = StatsService(
    _factsService,
    _streakService,
    _quizHistory,
  );
  late final _quickReview = QuickReviewService(
    _factsService,
    _quizHistory,
    now: widget.now,
    random: widget.random,
  );
  DailySession? _session;
  UserStats? _stats;

  /// Questions for the quick review, empty until something was read on an
  /// earlier day.
  List<Fact> _reviewFacts = const [];

  /// Quiz answers are saved without waiting, so stats wait for them here.
  Future<void> _answersSaved = Future.value();
  bool _loadFailed = false;
  _ShownCelebration? _celebration;

  /// The user has left the screen after the last card. It is not saved, so a
  /// restart shows that screen again before the quiz.
  bool _isQuizStarted = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      await _factsService.syncWithSeed();
      final session = await _deckService.loadToday();
      if (mounted) setState(() => _showSession(session));
      unawaited(_loadStats());
      unawaited(_downloadNewFacts());
      unawaited(_updateReminders(session));
      unawaited(_reportUsage());
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  /// Runs behind the scenes, so the deck never waits for the network. New facts
  /// reach the next deck, and a failed download is retried on the next start.
  Future<void> _downloadNewFacts() async {
    try {
      await _factsService.syncWithRemote();
    } catch (_) {}
  }

  void _showSession(DailySession session) {
    _session = session;
    if (!session.isQuizPending) _isQuizStarted = false;
  }

  /// Stats and the quick review are only extra, so a failure leaves them out.
  Future<void> _loadStats() async {
    try {
      await _answersSaved;
      final stats = await _statsService.load();
      final reviewFacts = await _quickReview.chooseFacts();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _reviewFacts = reviewFacts;
      });
    } catch (_) {}
  }

  Future<void> _openQuickReview() async {
    const HapticsService().cardAction();
    final message = await QuickReviewScreen.open(
      context,
      facts: _reviewFacts,
      reviewService: _quickReview,
    );
    await _loadStats();
    if (message == null || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startQuiz() {
    setState(() => _isQuizStarted = true);
  }

  Future<void> _reportUsage() async {
    final usage = widget.usageService;
    if (usage == null) return;

    final reminders = widget.reminderService;
    if (reminders != null && reminders.isSupported) {
      await usage.remindersState(isEnabled: await reminders.isEnabled());
    }
    await usage.recordToday();
  }

  Future<void> _updateReminders(DailySession session) async {
    await widget.reminderService?.update(isDayFinished: session.isDayFinished);
  }

  void _retryLoading() {
    setState(() => _loadFailed = false);
    _loadSession();
  }

  Future<void> _updateSession(Future<DailySession> Function() change) async {
    try {
      final wasDayFinished = _session?.isDayFinished ?? false;
      final session = await change();
      if (mounted) setState(() => _showSession(session));
      unawaited(_loadStats());
      if (!wasDayFinished && session.isDayFinished) {
        unawaited(_updateReminders(session));
        unawaited(_celebrate(session));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zapisać postępu.')),
      );
    }
  }

  /// Runs once per finished day, as the day stays finished after that.
  Future<void> _celebrate(DailySession session) async {
    final quizCorrect = session.deck.quizCorrect;
    final quizTotal = session.quizQuestions.length;
    var unlocked = const <Achievement>[];
    try {
      unlocked = await widget.achievementsService.recordDay(
        streak: session.streak,
        factsRead: session.factsRead,
        wasQuizPerfect: quizTotal > 0 && quizCorrect == quizTotal,
      );
    } catch (_) {
      // A lost achievement comes back with the next finished day.
    }
    unawaited(
      widget.usageService?.dayFinished(
        streak: session.streak,
        quizCorrect: quizCorrect,
        quizTotal: quizTotal,
      ),
    );
    if (!mounted) return;

    final celebration = Celebration.forDay(
      quizCorrect: quizCorrect,
      quizTotal: quizTotal,
      streak: session.streak,
    );
    if (celebration.intensity > 0) const HapticsService().celebration();
    setState(() => _celebration = _ShownCelebration(celebration, unlocked));
  }

  Future<void> _completeCard(Fact fact, {required bool liked}) {
    unawaited(widget.usageService?.cardCompleted(fact.id, liked: liked));
    return _updateSession(
      () => _deckService.completeCard(fact.id, liked: liked),
    );
  }

  Future<void> _undo() {
    const HapticsService().cardAction();
    return _updateSession(_deckService.undo);
  }

  void _recordAnswer(
    DailySession session,
    int question, {
    required bool isCorrect,
  }) {
    final factId = session.quizFacts[question].id;
    _answersSaved = _answersSaved
        .then((_) => _quizHistory.recordAnswer(factId, isCorrect: isCorrect))
        .catchError((Object _) {});
    unawaited(widget.usageService?.quizAnswered(factId, isCorrect: isCorrect));
  }

  void _finishQuiz(int correct) {
    _updateSession(() => _deckService.finishQuiz(correct));
  }

  void _addBonusCards() {
    const HapticsService().cardAction();
    unawaited(widget.usageService?.bonusRoundStarted());
    _updateSession(_deckService.addBonusCards);
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AchievementsScreen(achievementsService: widget.achievementsService),
      ),
    );
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritesScreen(factsService: _factsService),
      ),
    );
    await _loadSession();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          themeService: widget.themeService,
          factsService: _factsService,
          reminderService: widget.reminderService,
          usageService: widget.usageService,
        ),
      ),
    );
  }

  Future<void> _downloadApp() async {
    final opened = await widget.linkService.open(AppLinks.androidApp);
    if (opened || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nie udało się otworzyć linku.')),
    );
  }

  void _openReview(DailySession session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyReviewScreen(
          facts: session.facts,
          reviewFactIds: session.deck.reviewFactIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _celebration;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: _buildContent(),
            ),
          ),
          if (shown != null)
            CelebrationOverlay(
              celebration: shown.celebration,
              unlocked: shown.unlocked,
              onFinished: () => setState(() => _celebration = null),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loadFailed) {
      return _LoadError(onRetry: _retryLoading);
    }

    final session = _session;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressHeader(
          completed: session.completedCount,
          total: session.facts.length,
          streak: session.streak,
          onOpenAchievements: _openAchievements,
          onOpenFavorites: _openFavorites,
          onOpenSettings: _openSettings,
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildDeck(session)),
      ],
    );
  }

  Widget _buildDeck(DailySession session) {
    if (session.facts.isEmpty) {
      return const Center(child: Text('Brak ciekawostek.'));
    }

    if (session.isQuizPending && !_isQuizStarted) {
      return DeckFinishedView(onStartQuiz: _startQuiz, onUndo: _undo);
    }

    if (session.isQuizPending) {
      return DailyQuizScreen(
        questions: session.quizQuestions,
        facts: session.quizFacts,
        onAnswered: (question, {required isCorrect}) =>
            _recordAnswer(session, question, isCorrect: isCorrect),
        onFinished: _finishQuiz,
        onUndo: _undo,
      );
    }

    final remaining = session.remaining;
    if (remaining.isEmpty) {
      return _CompletionView(
        quizCorrect: session.deck.quizCorrect,
        quizTotal: session.quizQuestions.length,
        streak: session.streak,
        stats: _stats,
        timeUntilNextDeck: () => _deckService.timeUntilNextDeck(session),
        onNextDeckReady: _loadSession,
        onReview: () => _openReview(session),
        bonusCount: session.bonusCount,
        onAddBonus: _addBonusCards,
        quickReviewCount: _reviewFacts.length,
        onQuickReview: _openQuickReview,
        onDownloadApp: widget.offersAppDownload ? _downloadApp : null,
      );
    }

    return _CardDeck(
      facts: remaining,
      reviewFactIds: session.deck.reviewFactIds,
      canUndo: session.canUndo,
      onCompleted: _completeCard,
      onUndo: _undo,
      onFactOpened: (fact) =>
          unawaited(widget.usageService?.factOpened(fact.id)),
      onFactShared: (fact) =>
          unawaited(widget.usageService?.factShared(fact.id)),
    );
  }
}

class _ShownCelebration {
  const _ShownCelebration(this.celebration, this.unlocked);

  final Celebration celebration;
  final List<Achievement> unlocked;
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.completed,
    required this.total,
    required this.streak,
    required this.onOpenAchievements,
    required this.onOpenFavorites,
    required this.onOpenSettings,
  });

  final int completed;
  final int total;
  final int streak;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dziesiątka',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Osiągnięcia',
              onPressed: onOpenAchievements,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: mutedColor,
              icon: const Icon(Icons.emoji_events_outlined),
            ),
            IconButton(
              tooltip: 'Ulubione',
              onPressed: onOpenFavorites,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: mutedColor,
              icon: const Icon(Icons.favorite_border_rounded),
            ),
            IconButton(
              tooltip: 'Ustawienia',
              onPressed: onOpenSettings,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: mutedColor,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                '$completed / $total ukończone',
                style: theme.textTheme.labelLarge?.copyWith(color: mutedColor),
              ),
            ),
            _StreakBadge(streak: streak),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total == 0 ? 0 : completed / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

String _streakLabel(int streak) {
  return streak == 1 ? 'Seria: 1 dzień' : 'Seria: $streak dni';
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = streak > 0
        ? theme.extension<AppSurfaces>()!.streak
        : theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: _streakLabel(streak),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 18, color: color),
          Text(
            '$streak',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDeck extends StatefulWidget {
  const _CardDeck({
    required this.facts,
    required this.reviewFactIds,
    required this.canUndo,
    required this.onCompleted,
    required this.onUndo,
    required this.onFactOpened,
    required this.onFactShared,
  });

  final List<Fact> facts;
  final List<String> reviewFactIds;
  final bool canUndo;
  final Future<void> Function(Fact fact, {required bool liked}) onCompleted;
  final Future<void> Function() onUndo;
  final void Function(Fact fact) onFactOpened;
  final void Function(Fact fact) onFactShared;

  @override
  State<_CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<_CardDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dragOffset = AnimationController.unbounded(
    vsync: this,
  );
  double _deckWidth = 0;
  bool _isAnimating = false;

  @override
  void dispose() {
    _dragOffset.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!_isAnimating) _dragOffset.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isAnimating) _dragOffset.value += details.primaryDelta!;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.primaryVelocity ?? 0;
    final offset = _dragOffset.value;
    if (velocity.abs() >= _flingVelocity) {
      _dismiss(velocity.sign);
    } else if (offset.abs() >= _deckWidth * _dismissThreshold) {
      _dismiss(offset.sign);
    } else {
      _returnToCenter();
    }
  }

  void _returnToCenter() {
    if (_isAnimating) return;
    _dragOffset.animateTo(0, duration: _returnDuration, curve: Curves.easeOut);
  }

  Future<void> _dismiss(double direction) async {
    if (_isAnimating) return;
    _isAnimating = true;
    const HapticsService().cardAction();

    await _dragOffset.animateTo(
      direction * _deckWidth * _flyOutDistance,
      duration: _dismissDuration,
      curve: Curves.easeIn,
    );
    if (!mounted) return;

    // The card stays off-screen until the parent drops it from the deck, so
    // resetting the offset never flashes it back in the center.
    await widget.onCompleted(widget.facts.first, liked: direction > 0);
    if (!mounted) return;

    _dragOffset.value = 0;
    _isAnimating = false;
  }

  Future<void> _undo() async {
    if (_isAnimating) return;
    _isAnimating = true;

    await widget.onUndo();
    if (!mounted) return;

    // The restored card is on top by the next frame and slides in from here.
    _dragOffset.value = -_deckWidth * _flyOutDistance;
    await _dragOffset.animateTo(
      0,
      duration: _dismissDuration,
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: _stackOffset * 3),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                onHorizontalDragCancel: _returnToCenter,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _deckWidth = constraints.maxWidth;
                    // Built once and reused on every animation frame, so a
                    // drag moves the cards without rebuilding them.
                    final cards = _buildCards();
                    return AnimatedBuilder(
                      animation: _dragOffset,
                      builder: (context, _) => _buildStack(cards),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _dismiss(-1),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Dalej'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Cofnij',
              onPressed: widget.canUndo ? _undo : null,
              style: IconButton.styleFrom(minimumSize: const Size.square(56)),
              icon: const Icon(Icons.undo_rounded),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _dismiss(1),
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('Polub'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Only the cards that can be seen, front first. Each repaints separately,
  /// so moving one keeps the others' shadows and text cached.
  List<Widget> _buildCards() {
    return [
      for (final fact in widget.facts.take(_visibleCards))
        RepaintBoundary(
          child: FactCard(
            fact: fact,
            isReview: widget.reviewFactIds.contains(fact.id),
            onExpand: () {
              widget.onFactOpened(fact);
              FactDetailsSheet.show(context, fact);
            },
            onShare: () => widget.onFactShared(fact),
          ),
        ),
    ];
  }

  Widget _buildStack(List<Widget> cards) {
    final offset = _dragOffset.value;
    // 0 at rest, 1 once the top card is far enough to dismiss. Cards below move
    // up one slot along this value, so the deck lines up when the top card goes.
    final progress = _deckWidth == 0
        ? 0.0
        : (offset.abs() / (_deckWidth * _dismissThreshold)).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (var index = cards.length - 1; index >= 0; index--)
          _buildStackedCard(index, cards[index], offset, progress),
      ],
    );
  }

  Widget _buildStackedCard(
    int index,
    Widget card,
    double offset,
    double progress,
  ) {
    final isTop = index == 0;
    final depth = isTop ? 0.0 : index - progress;

    return Transform.translate(
      key: ValueKey(widget.facts[index].id),
      offset: Offset(isTop ? offset : 0, depth * _stackOffset),
      child: Transform.rotate(
        angle: isTop && _deckWidth > 0 ? offset / _deckWidth * _maxRotation : 0,
        child: Transform.scale(
          alignment: Alignment.bottomCenter,
          scale: 1 - depth * _stackScaleStep,
          child: IgnorePointer(
            ignoring: !isTop,
            child: ExcludeSemantics(
              excluding: !isTop,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  card,
                  // On the left, because a right swipe moves the right side
                  // of the card off the screen.
                  if (isTop && offset > 0)
                    Positioned(
                      top: 72,
                      left: 28,
                      child: Opacity(
                        opacity: progress,
                        child: const _LikeLabel(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LikeLabel extends StatelessWidget {
  const _LikeLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _likeColor,
        borderRadius: BorderRadius.circular(999),
        // Keeps the label visible on the green banner of the animal category.
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            const Icon(Icons.favorite_rounded, size: 20, color: Colors.white),
            Text(
              'Lubię to',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.quizCorrect,
    required this.quizTotal,
    required this.streak,
    required this.stats,
    required this.timeUntilNextDeck,
    required this.onNextDeckReady,
    required this.onReview,
    required this.bonusCount,
    required this.onAddBonus,
    required this.quickReviewCount,
    required this.onQuickReview,
    required this.onDownloadApp,
  });

  final int? quizCorrect;
  final int quizTotal;
  final int streak;
  final UserStats? stats;
  final Duration Function() timeUntilNextDeck;
  final VoidCallback onNextDeckReady;
  final VoidCallback onReview;
  final int bonusCount;
  final VoidCallback onAddBonus;
  final int quickReviewCount;
  final VoidCallback onQuickReview;
  final VoidCallback? onDownloadApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaces = theme.extension<AppSurfaces>()!;
    final correct = quizCorrect;
    final stats = this.stats;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 36,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gratulacje!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dzisiejsza talia jest ukończona.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (correct != null) ...[
              const SizedBox(height: 20),
              Text(
                '$correct/$quizTotal poprawne!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 22,
                  color: surfaces.streak,
                ),
                Text(
                  _streakLabel(streak),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: surfaces.streak,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 24),
              UserStatsView(stats: stats),
            ],
            const SizedBox(height: 20),
            _NextDeckCountdown(
              timeRemaining: timeUntilNextDeck,
              onFinished: onNextDeckReady,
            ),
            const SizedBox(height: 28),
            _ActionGrid(
              actions: [
                if (bonusCount > 0)
                  _ActionTile(
                    icon: Icons.add_rounded,
                    title: 'Jeszcze $bonusCount',
                    subtitle: 'nowe ciekawostki',
                    isPrimary: true,
                    onTap: onAddBonus,
                  ),
                if (quickReviewCount > 0)
                  _ActionTile(
                    icon: Icons.bolt_rounded,
                    title: 'Szybka powtórka',
                    subtitle: _quickReviewLabel(quickReviewCount),
                    onTap: onQuickReview,
                  ),
                _ActionTile(
                  icon: Icons.replay_rounded,
                  title: 'Powtórz dzisiejszą talię',
                  onTap: onReview,
                ),
              ],
            ),
            if (onDownloadApp != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onDownloadApp,
                icon: const Icon(Icons.android_rounded),
                label: const Text('Pobierz na Androida'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _quickReviewLabel(int count) {
  final questions = count == 1 ? 'pytanie' : 'pytania';
  return '$count $questions z poprzednich dni';
}

/// Lays the actions out two in a row. An odd last one takes the whole row.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (var start = 0; start < actions.length; start += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                for (final action in actions.skip(start).take(2))
                  Expanded(child: action),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Filled with the main color, for the action most people take next.
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaces = theme.extension<AppSurfaces>()!;
    final foreground = isPrimary ? colors.onPrimary : colors.onSurface;
    final muted = isPrimary ? colors.onPrimary : colors.onSurfaceVariant;
    final subtitle = this.subtitle;
    return Material(
      color: isPrimary ? colors.primary : surfaces.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPrimary ? BorderSide.none : BorderSide(color: surfaces.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Icon(icon, color: isPrimary ? colors.onPrimary : colors.primary),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextDeckCountdown extends StatefulWidget {
  const _NextDeckCountdown({
    required this.timeRemaining,
    required this.onFinished,
  });

  final Duration Function() timeRemaining;
  final VoidCallback onFinished;

  @override
  State<_NextDeckCountdown> createState() => _NextDeckCountdownState();
}

class _NextDeckCountdownState extends State<_NextDeckCountdown> {
  late Duration _remaining = widget.timeRemaining();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final remaining = widget.timeRemaining();
    if (remaining > Duration.zero) {
      setState(() => _remaining = remaining);
      return;
    }

    _timer?.cancel();
    widget.onFinished();
  }

  String get _formatted {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = twoDigits(_remaining.inHours);
    final minutes = twoDigits(_remaining.inMinutes % 60);
    final seconds = twoDigits(_remaining.inSeconds % 60);
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Następna dziesiątka za: $_formatted',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nie udało się wczytać ciekawostek.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }
}
