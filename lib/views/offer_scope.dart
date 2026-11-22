import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:flutter/widgets.dart';

/// Tells the cards and sheets below whether to show partner offers, and where
/// to report a tap on one. Without a scope, offers show and taps go nowhere.
class OfferScope extends InheritedWidget {
  const OfferScope({
    super.key,
    required this.isHidden,
    this.onOpened,
    this.now = DateTime.now,
    required super.child,
  });

  /// Dziesiątka+ hides offers.
  final bool isHidden;
  final void Function(String factId)? onOpened;
  final DateTime Function() now;

  static OfferScope? _of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OfferScope>();
  }

  /// The offer to show under [fact], or null if there is none, it has ended
  /// or the user has Dziesiątka+.
  static FactOffer? offerFor(BuildContext context, Fact fact) {
    final scope = _of(context);
    if (scope?.isHidden ?? false) return null;
    return fact.activeOfferOn((scope?.now ?? DateTime.now)());
  }

  static void reportOpened(BuildContext context, Fact fact) {
    context.getInheritedWidgetOfExactType<OfferScope>()?.onOpened?.call(
      fact.id,
    );
  }

  @override
  bool updateShouldNotify(OfferScope oldWidget) {
    return isHidden != oldWidget.isHidden || now != oldWidget.now;
  }
}
