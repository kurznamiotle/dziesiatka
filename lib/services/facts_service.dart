import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_state.dart';
import 'package:dziesiatka/services/asset_fact_source.dart';
import 'package:dziesiatka/services/fact_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps facts' content and the user's state under separate keys. Content can
/// then be replaced from any source without touching the user's progress, and
/// saving progress does not rewrite all the content.
class FactsService {
  FactsService({FactSource seed = const AssetFactSource(), FactSource? remote})
    : _seed = seed,
      _remote = remote;

  static const _contentKey = 'factContent';
  static const _statesKey = 'factStates';
  static const _syncedAtKey = 'factsSyncedAt';

  /// Held content and state together before they were separated.
  static const _legacyKey = 'facts';

  final FactSource _seed;
  final FactSource? _remote;

  /// Adds the bundled facts to storage. Copies that came from the server stay
  /// when they are newer.
  Future<List<Fact>> syncWithSeed() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyFacts(prefs);

    final merged = _merged(
      _readContent(prefs) ?? const [],
      await _seed.loadFacts(),
    );
    await _saveContent(prefs, merged);
    return _withStates(merged, _readStates(prefs));
  }

  /// Downloads what changed since the last download. It does nothing without a
  /// remote source and throws if the download fails.
  Future<void> syncWithRemote() async {
    final remote = _remote;
    if (remote == null) return;

    final prefs = await SharedPreferences.getInstance();
    final syncedAt = prefs.getString(_syncedAtKey);
    final changed = await remote.loadFacts(
      changedSince: syncedAt == null ? null : DateTime.parse(syncedAt),
    );
    if (changed.isEmpty) return;

    await _saveContent(
      prefs,
      _merged(_readContent(prefs) ?? const [], changed),
    );
    final latest = changed
        .map((fact) => fact.updatedAt)
        .reduce((first, second) => first.isAfter(second) ? first : second);
    await prefs.setString(_syncedAtKey, latest.toIso8601String());
  }

  Future<List<Fact>> getFacts() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyFacts(prefs);

    final content = _readContent(prefs);
    if (content == null) return syncWithSeed();
    return _withStates(content, _readStates(prefs));
  }

  /// The categories of facts still in circulation, in alphabetical order.
  Future<List<String>> getCategories() async {
    final facts = await getFacts();
    final categories = facts
        .where((fact) => !fact.isWithdrawn)
        .map((fact) => fact.category)
        .toSet();
    return categories.toList()..sort();
  }

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final states = _readStates(prefs);
    final state = states[id] ?? const FactState();
    states[id] = FactState(
      isRead: state.isRead,
      isFavorite: !state.isFavorite,
      lastReadAt: state.lastReadAt,
    );
    await _saveStates(prefs, states);
  }

  Future<void> setCardState(
    String id, {
    required bool isRead,
    required bool isFavorite,
    required DateTime? lastReadAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final states = _readStates(prefs);
    states[id] = FactState(
      isRead: isRead,
      isFavorite: isFavorite,
      lastReadAt: lastReadAt,
    );
    await _saveStates(prefs, states);
  }

  /// Keeps the stored order and adds new facts at the end. On a tie the
  /// incoming copy wins, so a fix in the bundled facts reaches older installs.
  List<Fact> _merged(List<Fact> stored, List<Fact> incoming) {
    final byId = {for (final fact in stored) fact.id: fact};
    for (final fact in incoming) {
      final known = byId[fact.id];
      if (known == null || !fact.updatedAt.isBefore(known.updatedAt)) {
        byId[fact.id] = fact;
      }
    }
    return byId.values.toList();
  }

  List<Fact> _withStates(List<Fact> content, Map<String, FactState> states) {
    return [
      for (final fact in content)
        fact.withState(states[fact.id] ?? const FactState()),
    ];
  }

  /// Moves data saved by older versions of the app to the current keys.
  Future<void> _migrateLegacyFacts(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyKey);
    if (legacy == null) return;

    final items = (jsonDecode(legacy) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    await _saveContent(prefs, items.map(Fact.fromJson).toList());
    await _saveStates(prefs, {
      for (final item in items) item['id'] as String: FactState.fromJson(item),
    });
    await prefs.remove(_legacyKey);
  }

  List<Fact>? _readContent(SharedPreferences prefs) {
    final stored = prefs.getString(_contentKey);
    if (stored == null) return null;
    return (jsonDecode(stored) as List<dynamic>)
        .map((item) => Fact.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, FactState> _readStates(SharedPreferences prefs) {
    final stored = prefs.getString(_statesKey);
    if (stored == null) return {};
    final items = jsonDecode(stored) as Map<String, dynamic>;
    return items.map(
      (id, item) =>
          MapEntry(id, FactState.fromJson(item as Map<String, dynamic>)),
    );
  }

  Future<void> _saveContent(SharedPreferences prefs, List<Fact> facts) async {
    final encoded = jsonEncode(facts.map((fact) => fact.toJson()).toList());
    await prefs.setString(_contentKey, encoded);
  }

  Future<void> _saveStates(
    SharedPreferences prefs,
    Map<String, FactState> states,
  ) async {
    await prefs.setString(
      _statesKey,
      jsonEncode({
        for (final MapEntry(key: id, value: state) in states.entries)
          if (!state.isDefault) id: state.toJson(),
      }),
    );
  }
}
