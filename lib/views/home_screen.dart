import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/admin_screen.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';

const _visibleCards = 4;
const _stackOffset = 14.0;
const _stackScaleStep = 0.05;
const _maxRotation = 0.2;
const _dismissThreshold = 0.3;
const _flingVelocity = 700.0;
const _dismissDuration = Duration(milliseconds: 240);
const _returnDuration = Duration(milliseconds: 200);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = FactsService();
  List<Fact>? _facts;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  Future<void> _loadFacts() async {
    try {
      final facts = await _service.getFacts();
      if (mounted) setState(() => _facts = facts);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _retryLoading() {
    setState(() => _loadFailed = false);
    _loadFacts();
  }

  Future<void> _updateFacts(Future<void> Function() change) async {
    try {
      await change();
      final facts = await _service.getFacts();
      if (mounted) setState(() => _facts = facts);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zapisać postępu.')),
      );
    }
  }

  Future<void> _openAdminPanel() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminScreen()));
    await _loadFacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loadFailed) {
      return _LoadError(onRetry: _retryLoading);
    }

    final facts = _facts;
    if (facts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final unread = facts.where((fact) => !fact.isRead).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressHeader(
          completed: facts.length - unread.length,
          total: facts.length,
          onOpenAdminPanel: _openAdminPanel,
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildDeck(facts, unread)),
      ],
    );
  }

  Widget _buildDeck(List<Fact> facts, List<Fact> unread) {
    if (facts.isEmpty) {
      return const Center(
        child: Text(
          'Brak ciekawostek. Dodaj pierwszą w panelu twórcy.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (unread.isEmpty) {
      return _CompletionView(
        onReset: () => _updateFacts(_service.resetReadState),
      );
    }

    return _CardDeck(
      facts: unread,
      onDismissed: (fact) => _updateFacts(() => _service.markAsRead(fact.id)),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.completed,
    required this.total,
    required this.onOpenAdminPanel,
  });

  final int completed;
  final int total;
  final VoidCallback onOpenAdminPanel;

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
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    'Dziesiątka',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$completed / $total ukończone',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Panel twórcy',
              onPressed: onOpenAdminPanel,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              color: mutedColor,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: total == 0 ? 0 : completed / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

class _CardDeck extends StatefulWidget {
  const _CardDeck({required this.facts, required this.onDismissed});

  final List<Fact> facts;
  final Future<void> Function(Fact fact) onDismissed;

  @override
  State<_CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<_CardDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dragOffset = AnimationController.unbounded(
    vsync: this,
  );
  double _deckWidth = 0;
  bool _isDismissing = false;

  @override
  void dispose() {
    _dragOffset.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!_isDismissing) _dragOffset.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDismissing) _dragOffset.value += details.primaryDelta!;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDismissing) return;

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
    if (_isDismissing) return;
    _dragOffset.animateTo(0, duration: _returnDuration, curve: Curves.easeOut);
  }

  Future<void> _dismiss(double direction) async {
    if (_isDismissing) return;
    _isDismissing = true;

    await _dragOffset.animateTo(
      direction * _deckWidth * 1.5,
      duration: _dismissDuration,
      curve: Curves.easeIn,
    );
    if (!mounted) return;

    // The card stays off-screen until the parent drops it from the deck, so
    // resetting the offset never flashes it back in the center.
    await widget.onDismissed(widget.facts.first);
    if (!mounted) return;

    _dragOffset.value = 0;
    _isDismissing = false;
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
                    return AnimatedBuilder(
                      animation: _dragOffset,
                      builder: (context, _) => _buildStack(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _dismiss(-1),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Odrzuć'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _dismiss(1),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Następna'),
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

  Widget _buildStack() {
    final offset = _dragOffset.value;
    // 0 at rest, 1 once the top card is far enough to dismiss. Cards below move
    // up one slot along this value, so the deck lines up when the top card goes.
    final progress = _deckWidth == 0
        ? 0.0
        : (offset.abs() / (_deckWidth * _dismissThreshold)).clamp(0.0, 1.0);
    final count = widget.facts.length.clamp(0, _visibleCards);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (var index = count - 1; index >= 0; index--)
          _buildStackedCard(index, offset, progress),
      ],
    );
  }

  Widget _buildStackedCard(int index, double offset, double progress) {
    final isTop = index == 0;
    final depth = isTop ? 0.0 : index - progress;
    final fact = widget.facts[index];

    return Transform.translate(
      key: ValueKey(fact.id),
      offset: Offset(isTop ? offset : 0, depth * _stackOffset),
      child: Transform.rotate(
        angle: isTop && _deckWidth > 0 ? offset / _deckWidth * _maxRotation : 0,
        child: Transform.scale(
          alignment: Alignment.bottomCenter,
          scale: 1 - depth * _stackScaleStep,
          child: Opacity(
            opacity: (_visibleCards - 1 - depth).clamp(0.0, 1.0),
            child: IgnorePointer(
              ignoring: !isTop,
              child: ExcludeSemantics(
                excluding: !isTop,
                child: _FactCard(
                  fact: fact,
                  onExpand: () => FactDetailsSheet.show(context, fact),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact, required this.onExpand});

  final Fact fact;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 48,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Gratulacje!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Wszystkie ciekawostki zostały przejrzane.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Zresetuj postęp'),
            ),
          ],
        ),
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
