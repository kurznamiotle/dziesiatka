/// The Supabase project the app downloads facts from. While either value is
/// null, the app uses only the facts bundled with it.
///
/// The publishable key is made to ship inside apps. The database rules in
/// `supabase/schema.sql` are what protect the data. A secret key must never be
/// put here.
abstract final class SupabaseConfig {
  static const String? url = null;
  static const String? publishableKey = null;
}
