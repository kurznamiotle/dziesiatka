import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FactsService {
  static const _factsKey = 'facts';
  static const _seedAssetPath = 'assets/data/facts.json';

  /// Merges the bundled asset into storage by id: new facts are added and
  /// known ones get the asset's content, while reading and favorite state stay.
  Future<List<Fact>> syncWithSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _readStored(prefs) ?? const [];
    final seed = _decode(await rootBundle.loadString(_seedAssetPath));

    final storedById = {for (final fact in stored) fact.id: fact};
    final seedIds = seed.map((fact) => fact.id).toSet();
    final merged = [
      for (final fact in seed) _withStoredState(fact, storedById[fact.id]),
      ...stored.where((fact) => !seedIds.contains(fact.id)),
    ];

    await _save(prefs, merged);
    return merged;
  }

  Future<List<Fact>> getFacts() async {
    final prefs = await SharedPreferences.getInstance();
    return _readStored(prefs) ?? syncWithSeed();
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
    required DateTime? lastReadAt,
  }) {
    return _updateFact(
      id,
      (fact) => fact.withCardState(
        isRead: isRead,
        isFavorite: isFavorite,
        lastReadAt: lastReadAt,
      ),
    );
  }

  Fact _withStoredState(Fact seedFact, Fact? stored) {
    if (stored == null) return seedFact;
    return seedFact.withCardState(
      isRead: stored.isRead,
      isFavorite: stored.isFavorite,
      lastReadAt: stored.lastReadAt,
    );
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
