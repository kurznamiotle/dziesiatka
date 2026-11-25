import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/views/admin/offer_form_dialog.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/fact_card.dart';
import 'package:dziesiatka/views/offer_scope.dart';
import 'package:flutter/material.dart';

const _formWidth = 480.0;
const _previewWidth = 340.0;
const _previewHeight = 520.0;

/// Writes a new partner fact or changes one, with a preview of the card as
/// the app will show it. Returns the fact, or null if the dialog was closed.
class PartnerFactDialog extends StatefulWidget {
  const PartnerFactDialog({super.key, required this.fact, this.now});

  final AdminFact fact;

  /// Decides whether the preview still shows the offer.
  final DateTime Function()? now;

  static Future<AdminFact?> show(BuildContext context, AdminFact fact) {
    return showDialog<AdminFact>(
      context: context,
      builder: (_) => PartnerFactDialog(fact: fact),
    );
  }

  @override
  State<PartnerFactDialog> createState() => _PartnerFactDialogState();
}

class _PartnerFactDialogState extends State<PartnerFactDialog> {
  late final _title = TextEditingController(text: widget.fact.title);
  late final _shortText = TextEditingController(text: widget.fact.shortText);
  late final _longText = TextEditingController(text: widget.fact.longText);
  late final _sourceLabel = TextEditingController(
    text: widget.fact.sourceLabel,
  );
  late final _sourceUrl = TextEditingController(text: widget.fact.sourceUrl);
  late final _offer = OfferFields(widget.fact.offer);
  bool _isDark = false;
  List<String> _errors = const [];

  @override
  void dispose() {
    for (final controller in [
      _title,
      _shortText,
      _longText,
      _sourceLabel,
      _sourceUrl,
    ]) {
      controller.dispose();
    }
    _offer.dispose();
    super.dispose();
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  AdminFact? _edited() {
    final offer = _offer.read();
    if (offer == null) return null;
    return AdminFact.partner(
      id: widget.fact.id,
      title: _title.text,
      shortText: _shortText.text,
      longText: _longText.text,
      sourceLabel: _sourceLabel.text,
      sourceUrl: _textOrNull(_sourceUrl),
      offer: offer,
      status: widget.fact.status,
    );
  }

  void _save() {
    final edited = _edited();
    final errors = edited == null
        ? const ['Podaj produkt, sklep i link.']
        : edited.copyWith(status: AdminFact.draft).validationErrors(const {});
    if (errors.isEmpty) {
      Navigator.of(context).pop(edited);
    } else {
      setState(() => _errors = errors);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildForm() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const SizedBox(height: 4),
        _field(_title, 'Tytuł', maxLength: AdminFact.maxTitleLength),
        _field(
          _shortText,
          'Krótki tekst',
          maxLength: AdminFact.maxShortTextLength,
          maxLines: 3,
        ),
        _field(_longText, 'Długi tekst', maxLines: 8),
        _field(_sourceLabel, 'Źródło faktu'),
        _field(_sourceUrl, 'Adres źródła'),
        Text('Produkt', style: Theme.of(context).textTheme.titleSmall),
        ..._offer.build(onChanged: (_) => setState(() {})),
        for (final error in _errors)
          Text(error, style: TextStyle(color: colors.error)),
      ],
    );
  }

  /// The card as the app draws it, in either theme. It takes no taps, so the
  /// link cannot open from here.
  Widget _buildPreview() {
    final offer = _offer.read();
    final theme = _isDark ? AppTheme.dark : AppTheme.light;
    final fact = Fact(
      id: 'podglad',
      title: _title.text.trim().isEmpty ? 'Tytuł' : _title.text.trim(),
      category: FactKind.partnerCategory,
      kind: FactKind.partner,
      shortText: _shortText.text.trim().isEmpty
          ? 'Krótki tekst'
          : _shortText.text.trim(),
      longText: _longText.text,
      sourceLabel: _sourceLabel.text,
      offer: offer,
      createdAt: DateTime(2026),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Jasny')),
            ButtonSegment(value: true, label: Text('Ciemny')),
          ],
          selected: {_isDark},
          onSelectionChanged: (value) => setState(() => _isDark = value.first),
        ),
        Theme(
          data: theme,
          child: OfferScope(
            now: widget.now ?? DateTime.now,
            child: Container(
              width: _previewWidth,
              height: _previewHeight,
              padding: const EdgeInsets.all(12),
              color: theme.extension<AppSurfaces>()!.frame,
              child: IgnorePointer(
                child: FactCard(fact: fact, onExpand: () {}),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.fact.id.isEmpty;
    return AlertDialog(
      title: Text(
        isNew
            ? 'Nowa ciekawostka partnerska'
            : 'Ciekawostka partnerska: ${widget.fact.id}',
      ),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(width: _formWidth, child: _buildForm()),
            _buildPreview(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isNew ? 'Zapisz i opublikuj' : 'Zapisz'),
        ),
      ],
    );
  }
}
