import 'dart:async';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/quick_review_service.dart';
import 'package:dziesiatka/views/daily_quiz_screen.dart';
import 'package:flutter/material.dart';

/// A short quiz about facts from earlier days. It closes with the number of
/// correct answers.
class QuickReviewScreen extends StatelessWidget {
  const QuickReviewScreen({
    super.key,
    required this.facts,
    required this.reviewService,
  });

  /// Opens the review and returns the number of correct answers, or null
  /// when the user leaves early.
  static Future<int?> open(
    BuildContext context, {
    required List<Fact> facts,
    required QuickReviewService reviewService,
  }) {
    return Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) =>
            QuickReviewScreen(facts: facts, reviewService: reviewService),
      ),
    );
  }

  static String resultMessage(int correct, int total) {
    final comment = correct * 2 >= total
        ? 'pamięć działa!'
        : 'następnym razem pójdzie lepiej!';
    return '$correct/$total – $comment';
  }

  final List<Fact> facts;
  final QuickReviewService reviewService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Szybka powtórka')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: DailyQuizScreen(
            questions: [for (final fact in facts) fact.quiz!],
            facts: facts,
            onAnswered: (question, {required isCorrect}) => unawaited(
              reviewService.recordAnswer(
                facts[question].id,
                isCorrect: isCorrect,
              ),
            ),
            onFinished: (correct) => Navigator.of(context).pop(correct),
          ),
        ),
      ),
    );
  }
}
