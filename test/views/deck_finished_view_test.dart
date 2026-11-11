import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/deck_finished_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int startCount;
  late int undoCount;

  Future<void> pumpView(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    startCount = 0;
    undoCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: DeckFinishedView(
              onStartQuiz: () => startCount++,
              onUndo: () => undoCount++,
            ),
          ),
        ),
      ),
    );
  }

  double fill(WidgetTester tester) {
    return tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;
  }

  testWidgets('starts the quiz by itself after 3 seconds', (tester) async {
    await pumpView(tester);

    await tester.pump(const Duration(milliseconds: 2900));
    expect(startCount, 0);

    await tester.pump(const Duration(milliseconds: 200));
    expect(startCount, 1);
  });

  testWidgets('the countdown fills the button', (tester) async {
    await pumpView(tester);
    await tester.pump();
    expect(fill(tester), 0);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(fill(tester), closeTo(0.5, 0.05));
  });

  testWidgets('a tap starts the quiz at once and only once', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Przejdź do quizu'));
    await tester.pump(const Duration(seconds: 5));

    expect(startCount, 1);
  });

  testWidgets('undo stops the countdown', (tester) async {
    await pumpView(tester);
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Cofnij'));
    await tester.pump(const Duration(seconds: 5));

    expect(undoCount, 1);
    expect(startCount, 0);
  });

  testWidgets('waits for a tap when animations are reduced', (tester) async {
    await pumpView(tester, disableAnimations: true);

    await tester.pump(const Duration(seconds: 10));
    expect(startCount, 0);

    await tester.tap(find.text('Przejdź do quizu'));
    expect(startCount, 1);
  });

  testWidgets('does not count down in the background and starts over', (
    tester,
  ) async {
    await pumpView(tester);
    await tester.pump(const Duration(seconds: 2));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(startCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(startCount, 0);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(startCount, 1);
  });
}
