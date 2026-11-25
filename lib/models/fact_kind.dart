/// What a fact is for. A partner fact is a separate card written around a
/// product, such as a book, with a true fact and a source like any other, but
/// always marked as a partner card. See `supabase/partner_facts.sql`.
enum FactKind {
  regular,
  partner;

  /// The fixed category of every partner fact. Shown in place of a category,
  /// so older versions of the app that do not know [FactKind] still label it.
  static const partnerCategory = 'Ciekawostka partnerska';

  /// Anything unknown, or no value before the migration runs, is [regular].
  static FactKind fromName(Object? name) {
    return name == partner.name ? partner : regular;
  }
}
