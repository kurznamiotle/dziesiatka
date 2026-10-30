import 'package:flutter/services.dart';

class HapticsService {
  const HapticsService();

  Future<void> cardAction() => HapticFeedback.lightImpact();

  Future<void> correctAnswer() => HapticFeedback.mediumImpact();

  Future<void> wrongAnswer() => HapticFeedback.heavyImpact();
}
