import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/offer_entry.dart';
import 'package:dziesiatka/models/offer_status.dart';
import 'package:dziesiatka/services/admin_offers_service.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:dziesiatka/views/admin/fact_picker_dialog.dart';
import 'package:dziesiatka/views/admin/offer_form_dialog.dart';
import 'package:dziesiatka/views/admin/partner_fact_dialog.dart';
import 'package:flutter/material.dart';

const _statusLabels = {
  OfferStatus.active: 'aktywne',
  OfferStatus.endingSoon: 'wygasa w 7 dni',
  OfferStatus.ended: 'wygasłe',
};

enum _KindFilter { all, partner, regular }

enum _Action { edit, publish, extend, delete }

/// All offers in one place: partner facts and regular facts with an offer.
class OffersPage extends StatefulWidget {
  const OffersPage({
    super.key,
    required this.facts,
    required this.factUsage,
    required this.adminService,
    required this.onChanged,
    this.offersService = const AdminOffersService(),
    this.now = DateTime.now,
  });

  /// All facts, partner ones included.
  final List<AdminFact> facts;
  final Map<String, FactUsage> factUsage;
  final AdminService adminService;
  final Future<void> Function() onChanged;
  final AdminOffersService offersService;
  final DateTime Function() now;

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  _KindFilter _kind = _KindFilter.all;
  OfferStatus? _status;
  bool _isBusy = false;

  /// Unknown with no facts at all, so the first partner fact can still try.
  bool get _hasKindColumn {
    return widget.facts.isEmpty ||
        widget.facts.any((fact) => fact.hasKindColumn);
  }

  bool get _hasOfferColumn {
    return widget.facts.isEmpty ||
        widget.facts.any((fact) => fact.hasOfferColumn);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() change) async {
    setState(() => _isBusy = true);
    try {
      await change();
      await widget.onChanged();
    } catch (_) {
      if (mounted) _showMessage('Nie udało się zapisać zmiany.');
    }
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _newPartnerFact() async {
    final fact = await PartnerFactDialog.show(
      context,
      AdminFact.partner(
        id: '',
        title: '',
        shortText: '',
        longText: '',
        sourceLabel: '',
        sourceUrl: null,
        offer: null,
      ),
    );
    if (fact == null) return;

    final id = widget.offersService.nextPartnerId(widget.facts);
    await _run(() => widget.adminService.insertFacts([fact.copyWith(id: id)]));
  }

  Future<void> _attachOffer() async {
    final fact = await FactPickerDialog.show(context, widget.facts);
    if (fact == null || !mounted) return;

    final offer = await OfferFormDialog.show(
      context,
      title: 'Polecenie: ${fact.title}',
    );
    if (offer == null) return;
    await _run(() => widget.adminService.updateOffers({fact.id: offer}));
  }

  Future<void> _edit(OfferEntry entry) async {
    final fact = entry.fact;
    if (fact.isPartner) {
      final edited = await PartnerFactDialog.show(context, fact);
      if (edited == null) return;
      await _run(() => widget.adminService.updateFact(edited));
      return;
    }

    final offer = await OfferFormDialog.show(
      context,
      title: 'Polecenie: ${fact.title}',
      offer: entry.offer,
    );
    if (offer == null) return;
    await _run(() => widget.adminService.updateOffers({fact.id: offer}));
  }

  Future<void> _extend(OfferEntry entry) {
    final offer = entry.offer.extendedOn(widget.now());
    return _run(() => widget.adminService.updateOffers({entry.fact.id: offer}));
  }

  /// A partner fact is withdrawn, not deleted, because the app learns only
  /// of changed rows. A regular fact only loses its offer.
  Future<void> _delete(OfferEntry entry) async {
    final fact = entry.fact;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć polecenie?'),
        content: Text(
          fact.isPartner
              ? 'Ciekawostka partnerska „${fact.title}” zniknie z aplikacji.'
              : 'Ciekawostka „${fact.title}” zostanie, ale bez polecenia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(
      () => fact.isPartner
          ? widget.adminService.setStatus([fact.id], AdminFact.withdrawn)
          : widget.adminService.removeOffer(fact.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.offersService;
    final entries = service.entries(
      widget.facts,
      widget.factUsage,
      widget.now(),
    );
    final summary = service.summarize(entries);
    final visible = entries.where((entry) {
      if (_status != null && entry.status != _status) return false;
      return switch (_kind) {
        _KindFilter.all => true,
        _KindFilter.partner => entry.fact.isPartner,
        _KindFilter.regular => !entry.fact.isPartner,
      };
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Counter(label: 'Aktywne', value: '${summary.active}'),
            _Counter(label: 'Wygasa w 7 dni', value: '${summary.endingSoon}'),
            _Counter(
              label: 'Kliknięcia łącznie',
              value: summary.clicks?.toString() ?? 'brak danych',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_hasKindColumn)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Ciekawostki partnerskie wymagają supabase/partner_facts.sql.',
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _isBusy || !_hasKindColumn ? null : _newPartnerFact,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nowa ciekawostka partnerska'),
            ),
            OutlinedButton.icon(
              onPressed: _isBusy || !_hasOfferColumn ? null : _attachOffer,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Dodaj polecenie do istniejącej ciekawostki'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<_KindFilter>(
              value: _kind,
              onChanged: (value) => setState(() => _kind = value!),
              items: const [
                DropdownMenuItem(
                  value: _KindFilter.all,
                  child: Text('Wszystkie rodzaje'),
                ),
                DropdownMenuItem(
                  value: _KindFilter.partner,
                  child: Text('Ciekawostki partnerskie'),
                ),
                DropdownMenuItem(
                  value: _KindFilter.regular,
                  child: Text('Zwykłe z poleceniem'),
                ),
              ],
            ),
            DropdownButton<OfferStatus?>(
              value: _status,
              onChanged: (value) => setState(() => _status = value),
              items: [
                const DropdownMenuItem(child: Text('Wszystkie statusy')),
                for (final MapEntry(key: status, value: label)
                    in _statusLabels.entries)
                  DropdownMenuItem(value: status, child: Text(label)),
              ],
            ),
            Text('Widocznych: ${visible.length}'),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              // First, so the actions stay in view on a narrow screen.
              DataColumn(label: Text('')),
              DataColumn(label: Text('Rodzaj')),
              DataColumn(label: Text('Tytuł')),
              DataColumn(label: Text('Produkt')),
              DataColumn(label: Text('Sklep')),
              DataColumn(label: Text('Ważne do')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Kliknięcia'), numeric: true),
            ],
            rows: [for (final entry in visible) _buildRow(entry)],
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(OfferEntry entry) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (entry.status) {
      OfferStatus.active => null,
      OfferStatus.endingSoon => colors.tertiary,
      OfferStatus.ended => colors.error,
    };
    return DataRow(
      cells: [
        DataCell(_buildMenu(entry)),
        DataCell(Text(entry.fact.isPartner ? 'partnerska' : 'zwykła')),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(entry.fact.title, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(entry.offer.product, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(entry.offer.shop)),
        DataCell(Text(entry.offer.until ?? 'bez końca')),
        DataCell(
          Text(
            // A draft from an import is not in the app yet, whatever its date.
            entry.fact.status == AdminFact.draft
                ? 'szkic'
                : _statusLabels[entry.status]!,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(Text(entry.clicks?.toString() ?? 'brak danych')),
      ],
    );
  }

  Widget _buildMenu(OfferEntry entry) {
    return PopupMenuButton<_Action>(
      tooltip: 'Działania',
      enabled: !_isBusy,
      onSelected: (action) => switch (action) {
        _Action.edit => _edit(entry),
        _Action.publish => _run(
          () => widget.adminService.setStatus([
            entry.fact.id,
          ], AdminFact.published),
        ),
        _Action.extend => _extend(entry),
        _Action.delete => _delete(entry),
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _Action.edit, child: Text('Edytuj')),
        if (entry.fact.status == AdminFact.draft)
          const PopupMenuItem(value: _Action.publish, child: Text('Opublikuj')),
        if (entry.offer.until != null)
          const PopupMenuItem(value: _Action.extend, child: Text('+30 dni')),
        const PopupMenuItem(value: _Action.delete, child: Text('Usuń')),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
