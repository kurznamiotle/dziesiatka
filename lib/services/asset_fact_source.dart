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
    // rootBundle.loadString hands larger files to a separate isolate, which this
    // small a file does not need and which never finishes in widget tests.
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final items = jsonDecode(utf8.decode(bytes)) as List;
    return items
        .map((item) => Fact.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
