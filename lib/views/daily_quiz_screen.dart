import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:dziesiatka/services/haptics_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';

/// Holds the buttons below the options, so the question does not jump when
/// they change after an answer.
const _actionsHeight = 112.0;
const _optionLetters = ['A', 'B', 'C'];
const _correctColor = Color(0xFF15803D);
const _wrongColor = Color(0xFFB91C1C);

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({
    super.key,
    required this.questions,
    required this.onFinished,
    this.onUndo,
    this.onAnswered,
    this.facts,
  });

  final List<QuizQuestion> questions;

  /// The facts behind [questions], in the same order. With them, an answered
  /// question offers the whole fact again.
  final List<Fact>? facts;
  final void Function(int correct) onFinished;

  /// Brings back the last card of the deck. Without it there is no undo.
  final VoidCallback? onUndo;

  /// Reports each answer by the position of its question.
  final void Function(int question, {required bool isCorrect})? onAnswered;

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  int _questionIndex = 0;
  int _correctCount = 0;
  int? _selectedOption;
  bool _isFinished = false;

  QuizQuestion get _question => widget.questions[_questionIndex];

  bool get _isLastQuestion => _questionIndex == widget.questions.length - 1;

  void _selectOption(int option) {
    if (_selectedOption != null) return;

    final isCorrect = option == _question.correctIndex;
    const haptics = HapticsService();
    isCorrect ? haptics.correctAnswer() : haptics.wrongAnswer();
    widget.onAnswered?.call(_questionIndex, isCorrect: isCorrect);

    setState(() {
      _selectedOption = option;
      if (isCorrect) _correctCount++;
    });
  }

  void _goToNextQuestion() {
    if (_isFinished) return;
    if (_isLastQuestion) {
      _isFinished = true;
      widget.onFinished(_correctCount);
      return;
    }

    setState(() {
      _questionIndex++;
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _question;
    final onUndo = widget.onUndo;
    final facts = widget.facts;
    final isAnswered = _selectedOption != null;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              'Pytanie ${_questionIndex + 1} / ${widget.questions.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              question.question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            for (final (index, option) in question.options.indexed)
              _QuizOption(
                label: '${_optionLetters[index]}. $option',
                state: _optionState(index),
                onTap: () => _selectOption(index),
              ),
            SizedBox(
              height: _actionsHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  if (isAnswered) ...[
                    FilledButton(
                      onPressed: _goToNextQuestion,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(_isLastQuestion ? 'Zobacz wynik' : 'Dalej'),
                    ),
                    if (facts != null)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => FactDetailsSheet.show(
                            context,
                            facts[_questionIndex],
                          ),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('Przypomnij sobie'),
                        ),
                      ),
                  ] else if (onUndo != null && _questionIndex == 0)
                    Center(
                      child: TextButton.icon(
                        onPressed: onUndo,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Cofnij ostatnią kartę'),
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

  _OptionState _optionState(int option) {
    final selected = _selectedOption;
    if (selected == null) return _OptionState.idle;
    if (option == _question.correctIndex) return _OptionState.correct;
    if (option == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaces>()!;
    final (background, foreground, icon) = switch (state) {
      _OptionState.idle => (surfaces.card, theme.colorScheme.onSurface, null),
      _OptionState.correct => (
        _correctColor,
        Colors.white,
        Icons.check_rounded,
      ),
      _OptionState.wrong => (_wrongColor, Colors.white, Icons.close_rounded),
      _OptionState.dimmed => (
        surfaces.card,
        theme.colorScheme.onSurfaceVariant,
        null,
      ),
    };

    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.6 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
