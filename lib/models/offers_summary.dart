/// The counts at the top of the panel's offer list.
class OffersSummary {
  const OffersSummary({
    required this.active,
    required this.endingSoon,
    this.clicks,
  });

  /// Shown in the app now, including those that end soon.
  final int active;
  final int endingSoon;

  /// All taps on the listed offers, or null before
  /// `supabase/offers_stats.sql` runs.
  final int? clicks;
}
