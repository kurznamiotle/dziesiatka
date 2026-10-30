import 'package:dziesiatka/models/fact.dart';

/// A place that facts' content comes from.
abstract interface class FactSource {
  /// Returns facts changed at or after [changedSince], or all of them when it
  /// is null. A source that cannot filter may return everything.
  Future<List<Fact>> loadFacts({DateTime? changedSince});
}
