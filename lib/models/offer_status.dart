/// Where an offer stands, as the panel lists it.
enum OfferStatus {
  active,

  /// Still shown, but its last day is at most [endingSoonDays] away.
  endingSoon,
  ended;

  static const endingSoonDays = 7;
}
