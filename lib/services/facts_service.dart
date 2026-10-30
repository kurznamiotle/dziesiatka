import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FactsService {
  static const _factsKey = 'facts';
  static const _seedAssetPath = 'assets/data/facts.json';

  /// Adds facts from the bundled asset that storage does not have yet, matched
  /// by id. Stored facts stay untouched, which keeps read and favorite state.
  Future<List<Fact>> syncWithSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _readStored(prefs);
    final seed = _decode(await rootBundle.loadString(_seedAssetPath));

    final storedIds = {...?stored?.map((fact) => fact.id)};
    final newFacts = seed.where((fact) => !storedIds.contains(fact.id));
    if (stored != null && newFacts.isEmpty) return stored;

    final merged = [...?stored, ...newFacts];
    await _save(prefs, merged);
    return merged;
  }

  Future<List<Fact>> getFacts() async {
    final prefs = await SharedPreferences.getInstance();
    return _readStored(prefs) ?? syncWithSeed();
  }

  Future<void> markAsRead(String id) {
    return _updateFact(id, (fact) => fact.copyWith(isRead: true));
  }

  Future<void> toggleFavorite(String id) {
    return _updateFact(
      id,
      (fact) => fact.copyWith(isFavorite: !fact.isFavorite),
    );
  }

  Future<void> setCardState(
    String id, {
    required bool isRead,
    required bool isFavorite,
  }) {
    return _updateFact(
      id,
      (fact) => fact.copyWith(isRead: isRead, isFavorite: isFavorite),
    );
  }

  Future<Fact> addFact({
    required String title,
    required String category,
    required String shortText,
    required String longText,
    required String source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await getFacts();
    final now = DateTime.now().toUtc();
    final fact = Fact(
      id: 'user-${now.microsecondsSinceEpoch}',
      title: title,
      category: category,
      shortText: shortText,
      longText: longText,
      source: source,
      createdAt: now,
    );
    await _save(prefs, [...facts, fact]);
    return fact;
  }

  Future<void> replaceFacts(List<Fact> facts) async {
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs, facts);
  }

  Future<void> _updateFact(String id, Fact Function(Fact fact) change) async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await getFacts();
    final updated = [
      for (final fact in facts)
        if (fact.id == id) change(fact) else fact,
    ];
    await _save(prefs, updated);
  }

  List<Fact>? _readStored(SharedPreferences prefs) {
    final stored = prefs.getString(_factsKey);
    return stored == null ? null : _decode(stored);
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
