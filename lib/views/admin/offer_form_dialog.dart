import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:flutter/material.dart';

const _dialogWidth = 480.0;

/// The four fields of an offer, shared by the partner fact form and the
/// offer form.
class OfferFields {
  OfferFields([FactOffer? offer])
    : product = TextEditingController(text: offer?.product),
      shop = TextEditingController(text: offer?.shop),
      url = TextEditingController(text: offer?.url),
      until = TextEditingController(text: offer?.until);

  final TextEditingController product;
  final TextEditingController shop;
  final TextEditingController url;
  final TextEditingController until;

  List<TextEditingController> get all => [product, shop, url, until];

  /// Null when all fields are empty.
  FactOffer? read() {
    return AdminFact.offerFromColumns({
      'offer_product': product.text,
      'offer_shop': shop.text,
      'offer_url': url.text,
      'offer_until': until.text,
    });
  }

  void dispose() {
    for (final controller in all) {
      controller.dispose();
    }
  }

  List<Widget> build({ValueChanged<String>? onChanged}) {
    Widget field(
      TextEditingController controller,
      String label, {
      int? maxLength,
      String? hint,
    }) {
      return TextField(
        controller: controller,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      );
    }

    return [
      field(product, 'Produkt', maxLength: FactOffer.maxProductLength),
      field(shop, 'Sklep', maxLength: FactOffer.maxShopLength),
      field(url, 'Link (https)', hint: 'https://…'),
      field(until, 'Ważne do (opcjonalnie)', hint: 'RRRR-MM-DD'),
    ];
  }
}

/// Sets the offer of a regular fact. Returns the offer, or null if the
/// dialog was closed.
class OfferFormDialog extends StatefulWidget {
  const OfferFormDialog({super.key, required this.title, this.offer});

  final String title;
  final FactOffer? offer;

  static Future<FactOffer?> show(
    BuildContext context, {
    required String title,
    FactOffer? offer,
  }) {
    return showDialog<FactOffer>(
      context: context,
      builder: (_) => OfferFormDialog(title: title, offer: offer),
    );
  }

  @override
  State<OfferFormDialog> createState() => _OfferFormDialogState();
}

class _OfferFormDialogState extends State<OfferFormDialog> {
  late final _fields = OfferFields(widget.offer);
  List<String> _errors = const [];

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  void _save() {
    final offer = _fields.read();
    final errors = offer == null
        ? const ['Podaj produkt, sklep i link.']
        : offer.validationErrors();
    if (errors.isEmpty) {
      Navigator.of(context).pop(offer);
    } else {
      setState(() => _errors = errors);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: _dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              const SizedBox(height: 4),
              ..._fields.build(),
              for (final error in _errors)
                Text(error, style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _save, child: const Text('Zapisz')),
      ],
    );
  }
}
