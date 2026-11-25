import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/services/admin_offers_service.dart';
import 'package:flutter/material.dart';

const _dialogWidth = 560.0;
const _listHeight = 420.0;

/// Finds a regular fact without an offer. Returns it, or null if the dialog
/// was closed.
class FactPickerDialog extends StatefulWidget {
  const FactPickerDialog({
    super.key,
    required this.facts,
    this.offersService = const AdminOffersService(),
  });

  final List<AdminFact> facts;
  final AdminOffersService offersService;

  static Future<AdminFact?> show(BuildContext context, List<AdminFact> facts) {
    return showDialog<AdminFact>(
      context: context,
      builder: (_) => FactPickerDialog(facts: facts),
    );
  }

  @override
  State<FactPickerDialog> createState() => _FactPickerDialogState();
}

class _FactPickerDialogState extends State<FactPickerDialog> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.offersService.withoutOffer(widget.facts, _search.text);
    return AlertDialog(
      title: const Text('Dodaj polecenie do ciekawostki'),
      content: SizedBox(
        width: _dialogWidth,
        height: _listHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Szukaj ciekawostki bez polecenia',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            Text('Znalezione: ${found.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: found.length,
                itemBuilder: (context, index) {
                  final fact = found[index];
                  return ListTile(
                    title: Text(fact.title),
                    subtitle: Text('${fact.category} · ${fact.id}'),
                    onTap: () => Navigator.of(context).pop(fact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
      ],
    );
  }
}
