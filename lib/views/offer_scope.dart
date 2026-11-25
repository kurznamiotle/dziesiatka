import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:flutter/widgets.dart';

/// Tells the cards and sheets below the time that decides whether an offer
/// has ended, and where to report a tap on one. Without a scope, the clock is
/// the device's and taps go nowhere.
class OfferScope extends InheritedWidget {
  const OfferScope({
    super.key,
    this.onOpened,
    this.now = DateTime.now,
    required super.child,
  });

  final void Function(String factId)? onOpened;
  final DateTime Function() now;

  static OfferScope? _of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OfferScope>();
  }

  /// The offer to show under [fact], or null if there is none or it has
  /// ended.
  static FactOffer? offerFor(BuildContext context, Fact fact) {
    final scope = _of(context);
    return fact.activeOfferOn((scope?.now ?? DateTime.now)());
  }

  /// False for a partner card whose offer has ended, which then disappears
  /// everywhere, liked or not.
  static bool isShown(BuildContext context, Fact fact) {
    final scope = _of(context);
    return fact.isShownOn((scope?.now ?? DateTime.now)());
  }

  static void reportOpened(BuildContext context, Fact fact) {
    context.getInheritedWidgetOfExactType<OfferScope>()?.onOpened?.call(
      fact.id,
    );
  }

  @override
  bool updateShouldNotify(OfferScope oldWidget) {
    return now != oldWidget.now;
  }
}
