import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FactsService {
  static const _factsKey = 'facts';
  static const _seedAssetPath = 'assets/data/facts.json';

  /// Returns all facts, seeding local storage from the bundled asset on the
  /// first run. Later runs read only from storage, which keeps read state and
  /// user-added facts.
  Future<List<Fact>> getFacts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_factsKey);
    if (stored != null) {
      return _decode(stored);
    }

    final seed = await rootBundle.loadString(_seedAssetPath);
    final facts = _decode(seed);
    await _save(prefs, facts);
    return facts;
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await getFacts();
    final updated = [
      for (final fact in facts)
        if (fact.id == id) fact.copyWith(isRead: true) else fact,
    ];
    await _save(prefs, updated);
  }

  Future<Fact> addFact({
    required String title,
    required String content,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await getFacts();
    final now = DateTime.now().toUtc();
    final fact = Fact(
      id: 'user-${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      category: category,
      createdAt: now,
    );
    await _save(prefs, [...facts, fact]);
    return fact;
  }

  List<Fact> _decode(String source) {
    final items = jsonDecode(source) as List<dynamic>;
    return items
        .map((item) => Fact.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(SharedPreferences prefs, List<Fact> facts) async {
    final encoded = jsonEncode(facts.map((fact) => fact.toJson()).toList());
    await prefs.setString(_factsKey, encoded);
  }
}
