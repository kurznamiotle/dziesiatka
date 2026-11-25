import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/offer_status.dart';

/// One offer in the panel's list: a partner fact or a regular fact with an
/// offer attached.
class OfferEntry {
  const OfferEntry({
    required this.fact,
    required this.offer,
    required this.status,
    this.clicks,
  });

  final AdminFact fact;
  final FactOffer offer;
  final OfferStatus status;

  /// Taps counted by `supabase/offers_stats.sql`, or null before it runs.
  final int? clicks;
}
