import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/fact_source.dart';
import 'package:flutter/services.dart';

/// The facts bundled with the app, so it works on first start without a network.
class AssetFactSource implements FactSource {
  const AssetFactSource();

  static const _assetPath = 'assets/data/facts.json';

  @override
  Future<List<Fact>> loadFacts({DateTime? changedSince}) async {
    final items = jsonDecode(await rootBundle.loadString(_assetPath)) as List;
    return items
        .map((item) => Fact.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
