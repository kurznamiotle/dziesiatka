import 'package:flutter/material.dart';

const _pageDuration = Duration(milliseconds: 240);
const _dotSize = 8.0;

const _pages = [
  _WelcomePage(
    icon: Icons.auto_awesome_rounded,
    title: 'Witaj w Dziesiątce!',
    text:
        'Codziennie czeka na Ciebie dziesięć ciekawostek. '
        'Wystarczy kilka minut dziennie.',
  ),
  _WelcomePage(
    icon: Icons.swipe_rounded,
    title: 'Przesuwaj karty',
    text:
        'W prawo, jeśli ciekawostka Ci się podoba. Trafi do ulubionych. '
        'W lewo, aby przejść dalej. Możesz też użyć przycisków pod kartą.',
  ),
  _WelcomePage(
    icon: Icons.menu_book_rounded,
    title: 'Dowiedz się więcej',
    text:
        'Karta to tylko początek. Pod przyciskiem '
        '„Dowiedz się więcej” znajdziesz całą historię i jej źródło.',
    note: 'Odpowiedzi do quizu często są widoczne dopiero tutaj.',
  ),
  _WelcomePage(
    icon: Icons.local_fire_department_rounded,
    title: 'Quiz i seria dni',
    text:
        'Po ostatniej karcie czeka krótki quiz. '
        'Kończ talię każdego dnia, a Twoja seria będzie rosnąć.',
  ),
];

/// Introduces the app, both on the first start and from the settings.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onFinished, this.onSkipped});

  final VoidCallback onFinished;

  /// Used instead of [onFinished] after "Pomiń" when given.
  final VoidCallback? onSkipped;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLastPage => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goForward() {
    if (_isLastPage) {
      widget.onFinished();
      return;
    }

    _controller.nextPage(duration: _pageDuration, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Keeps its space when hidden, so the page does not jump.
              Align(
                alignment: Alignment.centerRight,
                child: Visibility(
                  visible: !_isLastPage,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: TextButton(
                    onPressed: widget.onSkipped ?? widget.onFinished,
                    child: const Text('Pomiń'),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: _pages,
                ),
              ),
              const SizedBox(height: 16),
              _PageDots(current: _page, count: _pages.length),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _goForward,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_isLastPage ? 'Zaczynamy' : 'Dalej'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.icon,
    required this.title,
    required this.text,
    this.note,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = this.note;
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
              child: Icon(icon, size: 48, color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 18,
                height: 1.5,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Krok ${current + 1} z $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: _pageDuration,
              width: index == current ? _dotSize * 3 : _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: index == current
                    ? colors.primary
                    : colors.outlineVariant,
                borderRadius: BorderRadius.circular(_dotSize / 2),
              ),
            ),
        ],
      ),
    );
  }
}
