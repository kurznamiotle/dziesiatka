import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/import_item.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:dziesiatka/services/browser_files.dart';
import 'package:dziesiatka/services/import_service.dart';
import 'package:flutter/material.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({
    super.key,
    required this.facts,
    required this.categories,
    required this.adminService,
    required this.onSaved,
    this.importService = const ImportService(),
    this.onPickFile = pickTextFile,
  });

  final List<AdminFact> facts;
  final Set<String> categories;
  final AdminService adminService;
  final Future<void> Function() onSaved;
  final ImportService importService;
  final Future<String?> Function() onPickFile;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final _text = TextEditingController();
  List<ImportItem>? _items;
  bool _publishConfident = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final text = await widget.onPickFile();
    if (text == null) return;

    _text.text = text;
    _check();
  }

  void _check() {
    setState(() {
      try {
        _items = widget.importService.check(
          _text.text,
          existing: widget.facts,
          categories: widget.categories,
        );
        _error = null;
      } on FormatException {
        _items = null;
        _error =
            'To nie jest poprawna lista JSON. Poproś czat o poprawę pliku.';
      }
    });
  }

  Future<void> _save() async {
    final facts = widget.importService.prepareToSave(
      _items!,
      existing: widget.facts,
      publishConfident: _publishConfident,
    );
    setState(() => _isSaving = true);
    try {
      await widget.adminService.insertFacts(facts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zapisano ciekawostki: ${facts.length}.')),
      );
      _text.clear();
      setState(() => _items = null);
      await widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się zapisać. Nic nie zostało dodane.'),
        ),
      );
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final error = _error;
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Wybierz plik JSON z czatu albo wklej jego treść. Panel sprawdzi '
          'limity, kategorie i podobieństwo do istniejących ciekawostek, '
          'zanim cokolwiek zapisze.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Treść pliku',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Wybierz plik'),
            ),
            FilledButton(onPressed: _check, child: const Text('Sprawdź')),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error, style: TextStyle(color: colors.error)),
          ),
        if (items != null) ..._buildPreview(items),
      ],
    );
  }

  List<Widget> _buildPreview(List<ImportItem> items) {
    final valid = items.where((item) => item.isValid).length;
    final similar = items.where((item) => item.duplicateOf != null).length;
    return [
      const SizedBox(height: 16),
      Text(
        'Pozycji: ${items.length}. Do zapisania: $valid. '
        'Z błędem: ${items.length - valid}. Możliwe duplikaty: $similar.',
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Od razu publikuj pewne'),
        subtitle: const Text(
          'Wyłączone: wszystko trafia do szkiców. Wątpliwe i możliwe '
          'duplikaty zawsze zostają szkicami.',
        ),
        value: _publishConfident,
        onChanged: (value) => setState(() => _publishConfident = value),
      ),
      FilledButton(
        onPressed: valid == 0 || _isSaving ? null : _save,
        child: Text('Zapisz ($valid)'),
      ),
      const SizedBox(height: 8),
      for (final item in items) _ImportTile(item: item),
    ];
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile({required this.item});

  final ImportItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fact = item.fact;
    final note = fact.reviewNote;
    final duplicateOf = item.duplicateOf;
    final warning = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.error,
      fontWeight: FontWeight.w600,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.isValid ? Icons.check_circle_outline : Icons.error_outline,
        color: item.isValid ? null : theme.colorScheme.error,
      ),
      title: Text(fact.title.isEmpty ? '(bez tytułu)' : fact.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${fact.category} · ${fact.shortText}'),
          for (final error in item.errors) Text(error, style: warning),
          if (duplicateOf != null)
            Text('Możliwy duplikat: „$duplicateOf”.', style: warning),
          if (note != null) Text(note, style: warning),
        ],
      ),
    );
  }
}
