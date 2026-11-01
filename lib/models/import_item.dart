import 'package:dziesiatka/models/admin_fact.dart';

/// One position of an imported file with what the check found.
class ImportItem {
  const ImportItem({
    required this.fact,
    this.errors = const [],
    this.duplicateOf,
  });

  final AdminFact fact;

  /// Reasons it cannot be saved.
  final List<String> errors;

  /// The title of a similar fact. It can still be saved, as a draft.
  final String? duplicateOf;

  bool get isValid => errors.isEmpty;
}
