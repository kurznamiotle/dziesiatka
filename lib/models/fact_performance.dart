import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_usage.dart';

/// A fact with the totals its readers left.
class FactPerformance {
  const FactPerformance({required this.fact, required this.usage});

  final AdminFact fact;
  final FactUsage usage;

  double? get likedPercent => _percent(usage.liked, usage.shown);

  double? get openedPercent => _percent(usage.opened, usage.shown);

  int get answers => usage.quizCorrect + usage.quizWrong;

  double? get quizPercent => _percent(usage.quizCorrect, answers);

  double? _percent(int part, int whole) {
    return whole == 0 ? null : 100 * part / whole;
  }
}
