import 'dart:convert';

import 'package:dziesiatka/models/quiz_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps this user's quiz answers per fact. It never leaves the device.
class QuizHistoryService {
  QuizHistoryService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _historyKey = 'quizHistory';

  final DateTime Function() _now;

  /// The records by fact id.
  Future<Map<String, QuizRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  Future<void> recordAnswer(String factId, {required bool isCorrect}) async {
    final prefs = await SharedPreferences.getInstance();
    final records = _read(prefs);
    final known = records[factId];
    records[factId] = known == null
        ? QuizRecord.first(isCorrect: isCorrect, at: _now())
        : known.withAnswer(isCorrect: isCorrect, at: _now());
    await prefs.setString(
      _historyKey,
      jsonEncode({
        for (final MapEntry(key: id, value: record) in records.entries)
          id: record.toJson(),
      }),
    );
  }

  Map<String, QuizRecord> _read(SharedPreferences prefs) {
    final stored = prefs.getString(_historyKey);
    if (stored == null) return {};
    final items = jsonDecode(stored) as Map<String, dynamic>;
    return items.map(
      (id, item) =>
          MapEntry(id, QuizRecord.fromJson(item as Map<String, dynamic>)),
    );
  }
}
