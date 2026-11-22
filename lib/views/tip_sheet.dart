import 'package:dziesiatka/services/purchase_service.dart';
import 'package:flutter/material.dart';

const _tipNames = {
  'napiwek_maly': 'Mała kawa',
  'napiwek_sredni': 'Duża kawa',
  'napiwek_duzy': 'Kawa z ciastkiem',
};

/// Lets the user pick a tip from the ones the store returned. The payment
/// goes only through the store.
class TipSheet extends StatelessWidget {
  const TipSheet({super.key, required this.purchaseService});

  final PurchaseService purchaseService;

  static Future<void> show(BuildContext context, PurchaseService purchases) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          SafeArea(top: false, child: TipSheet(purchaseService: purchases)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Postaw kawę twórcy ☕',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Napiwek nic nie odblokowuje. Pomaga pisać nowe ciekawostki.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final tip in purchaseService.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  purchaseService.buyTip(tip.id);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text('${_tipNames[tip.id] ?? tip.title} · ${tip.price}'),
              ),
            ),
        ],
      ),
    );
  }
}
