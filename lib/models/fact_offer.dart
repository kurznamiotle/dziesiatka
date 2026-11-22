/// A partner product recommended under a fact, such as a book about space
/// under a fact about Venus. The link earns a commission, so the app marks it
/// as a partner link. See `supabase/offers.sql`.
class FactOffer {
  const FactOffer({
    required this.product,
    required this.shop,
    required this.url,
    this.until,
  });

  /// Reads the stored shape, or returns null for anything else, so a bad
  /// offer only hides itself and never stops the fact from loading.
  static FactOffer? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final product = json['product'];
    final shop = json['shop'];
    final url = json['url'];
    final until = json['until'];
    if (product is! String || shop is! String || url is! String) return null;
    if (until != null && until is! String) return null;
    return FactOffer(
      product: product,
      shop: shop,
      url: url,
      until: until as String?,
    );
  }

  static const maxProductLength = 80;
  static const maxShopLength = 40;
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final String product;
  final String shop;
  final String url;

  /// The last day the offer is shown, as `YYYY-MM-DD`, or null for no end.
  final String? until;

  /// The day [until] names, or null without one or with a wrong one.
  DateTime? get untilDate {
    final until = this.until;
    if (until == null || !_datePattern.hasMatch(until)) return null;
    final date = DateTime.tryParse(until);
    // DateTime.parse rolls 2026-02-30 over to March, so it must round-trip.
    if (date == null || _dateKey(date) != until) return null;
    return date;
  }

  /// Shown through the whole of the [until] day, in the user's time.
  bool isActiveOn(DateTime moment) {
    final until = this.until;
    if (until == null) return true;
    final last = untilDate;
    if (last == null) return false;
    final local = moment.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    return !today.isAfter(last);
  }

  /// The same rules as the database check in `supabase/offers.sql`.
  List<String> validationErrors() {
    final product = this.product.trim();
    final shop = this.shop.trim();
    final until = this.until;
    return [
      if (product.isEmpty) 'Brak nazwy produktu w poleceniu.',
      if (product.length > maxProductLength)
        'Nazwa produktu ma ${product.length} znaków, limit to '
            '$maxProductLength.',
      if (shop.isEmpty) 'Brak nazwy sklepu w poleceniu.',
      if (shop.length > maxShopLength)
        'Nazwa sklepu ma ${shop.length} znaków, limit to $maxShopLength.',
      if (!url.trim().startsWith('https://') ||
          (Uri.tryParse(url.trim())?.host.isEmpty ?? true))
        'Link polecenia musi zaczynać się od https://.',
      if (until != null && untilDate == null)
        'Data „ważne do” musi mieć postać RRRR-MM-DD.',
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.trim(),
      'shop': shop.trim(),
      'url': url.trim(),
      'until': ?until,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is FactOffer &&
        other.product == product &&
        other.shop == shop &&
        other.url == url &&
        other.until == until;
  }

  @override
  int get hashCode => Object.hash(product, shop, url, until);

  static String _dateKey(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
        '${two(date.day)}';
  }
}
