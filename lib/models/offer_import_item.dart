import 'package:dziesiatka/models/fact_offer.dart';

/// One row of a CSV file that sets the offer of an existing fact.
class OfferImportItem {
  const OfferImportItem({
    required this.factId,
    required this.title,
    required this.offer,
    this.errors = const [],
  });

  final String factId;

  /// The fact's title in the panel, or the id if no fact has it.
  final String title;
  final FactOffer offer;

  /// Reasons it cannot be saved.
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}
