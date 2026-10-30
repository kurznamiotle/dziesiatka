/// The Supabase project the app downloads facts from.
///
/// The publishable key is made to ship inside apps. The database rules in
/// `supabase/schema.sql` are what protect the data. A secret key must never be
/// put here.
abstract final class SupabaseConfig {
  static const url = 'https://mpsxxgvftpgepegnqnao.supabase.co';
  static const publishableKey =
      'sb_publishable_J1zvwa8XB64t2jjUSr1nOw_-rcIjzgS';
}
