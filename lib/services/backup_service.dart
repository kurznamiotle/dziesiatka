import 'dart:convert';

import 'package:dziesiatka/models/database_snapshot.dart';
import 'package:dziesiatka/services/categories_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter/services.dart';

class BackupService {
  BackupService(this._factsService, this._categoriesService);

  final FactsService _factsService;
  final CategoriesService _categoriesService;

  Future<String> exportJson() async {
    final snapshot = DatabaseSnapshot(
      categories: await _categoriesService.getCategories(),
      facts: await _factsService.getFacts(),
    );
    return const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
  }

  /// Validates [source] without changing stored data. Throws a
  /// [FormatException] with a user-facing message when it is not a valid export.
  DatabaseSnapshot parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('To nie jest poprawny JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Oczekiwano obiektu z eksportu bazy.');
    }
    return DatabaseSnapshot.fromJson(decoded);
  }

  Future<void> restore(DatabaseSnapshot snapshot) async {
    await _factsService.replaceFacts(snapshot.facts);
    await _categoriesService.replaceCategories(snapshot.categories);
  }

  Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }

  Future<String?> readClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
