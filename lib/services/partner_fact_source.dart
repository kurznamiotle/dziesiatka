import 'package:dziesiatka/models/fact.dart';

/// A place that partner facts come from, apart from the regular ones, so
/// older versions of the app reading the regular facts never see them.
abstract interface class PartnerFactSource {
  /// Every partner fact that can be shown now. A fact missing from the list
  /// has been withdrawn or has ended. Null means the source has no partner
  /// facts at all, such as before `supabase/partner_facts.sql` runs.
  Future<List<Fact>?> loadPartnerFacts();
}
