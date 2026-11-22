import 'dart:async';

import 'package:dziesiatka/models/app_accent.dart';
import 'package:dziesiatka/models/celebration.dart';
import 'package:dziesiatka/models/purchase_outcome.dart';
import 'package:dziesiatka/services/purchase_service.dart';
import 'package:dziesiatka/views/celebration_overlay.dart';
import 'package:flutter/material.dart';

/// What Dziesiątka+ gives, with the price from the store.
class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key, required this.purchaseService});

  final PurchaseService purchaseService;

  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  StreamSubscription<PurchaseOutcome>? _outcomes;

  @override
  void initState() {
    super.initState();
    _outcomes = widget.purchaseService.outcomes.listen(_onOutcome);
  }

  @override
  void dispose() {
    _outcomes?.cancel();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _onOutcome(PurchaseOutcome outcome) {
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.plusPurchased:
        CelebrationOverlay.show(context, Celebration.forPlus());
      case PurchaseOutcome.plusRestored:
        _showMessage('Przywrócono Dziesiątkę+.');
      case PurchaseOutcome.plusPending:
        _showMessage(
          'Płatność czeka na potwierdzenie. Dziesiątka+ włączy się sama, '
          'gdy sklep ją potwierdzi.',
        );
      case PurchaseOutcome.failed:
        _showMessage('Nie udało się. Spróbuj ponownie za chwilę.');
      case PurchaseOutcome.tipThanks || PurchaseOutcome.tipPending:
        break;
    }
  }

  Future<void> _restore() async {
    _showMessage('Sprawdzamy zakupy w sklepie…');
    await widget.purchaseService.restore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dziesiątka+')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.purchaseService,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final purchases = widget.purchaseService;
    final product = purchases.plusProduct;
    final extraAccents = AppAccent.values
        .where((accent) => accent.needsPlus)
        .map((accent) => accent.label)
        .join(', ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Icon(Icons.workspace_premium_rounded, size: 56, color: colors.primary),
        const SizedBox(height: 12),
        Text(
          purchases.hasPlus
              ? 'Masz Dziesiątkę+. Dziękujemy!'
              : 'Jeden zakup, na zawsze',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dziesiątka+ wspiera rozwój aplikacji i nowe ciekawostki. '
          'Bez subskrypcji.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        const _Benefit(
          icon: Icons.link_off_rounded,
          title: 'Bez poleceń partnerskich',
          text: 'Same ciekawostki, bez linków do produktów pod nimi.',
        ),
        _Benefit(
          icon: Icons.palette_outlined,
          title: 'Więcej kolorów',
          text:
              'Akcenty $extraAccents. Wybierzesz je w ustawieniach, '
              'w sekcji Wygląd.',
        ),
        const _Benefit(
          icon: Icons.upcoming_outlined,
          title: 'Kolejne funkcje bez dopłat',
          text:
              'Archiwum dni i zamrożenie serii dojdą w następnych wersjach, '
              'w ramach tego samego zakupu.',
        ),
        const SizedBox(height: 24),
        if (!purchases.hasPlus && product != null)
          FilledButton(
            onPressed: purchases.isPlusPending ? null : purchases.buyPlus,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(
              purchases.isPlusPending
                  ? 'Płatność czeka na potwierdzenie'
                  : 'Kup za ${product.price}',
            ),
          ),
        if (!purchases.hasPlus)
          TextButton(onPressed: _restore, child: const Text('Przywróć zakup')),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(text),
    );
  }
}
