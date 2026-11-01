import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:dziesiatka/services/browser_files.dart';
import 'package:dziesiatka/services/facts_csv_service.dart';
import 'package:dziesiatka/views/admin/fact_edit_dialog.dart';
import 'package:flutter/material.dart';

const _allCategories = '';
const _statusLabels = {
  AdminFact.draft: 'Szkice',
  AdminFact.published: 'Opublikowane',
  AdminFact.withdrawn: 'Wycofane',
  AdminFact.rejected: 'Odrzucone',
};
const _statusNames = {
  AdminFact.draft: 'szkic',
  AdminFact.published: 'opublikowana',
  AdminFact.withdrawn: 'wycofana',
  AdminFact.rejected: 'odrzucona',
};

class FactsPage extends StatefulWidget {
  const FactsPage({
    super.key,
    required this.facts,
    required this.categories,
    required this.adminService,
    required this.onChanged,
    this.csvService = const FactsCsvService(),
    this.onDownload = downloadTextFile,
  });

  final List<AdminFact> facts;
  final Set<String> categories;
  final AdminService adminService;
  final Future<void> Function() onChanged;
  final FactsCsvService csvService;
  final void Function(String fileName, String text) onDownload;

  @override
  State<FactsPage> createState() => _FactsPageState();
}

class _FactsPageState extends State<FactsPage> {
  final _search = TextEditingController();
  final _selected = <String>{};
  String _category = _allCategories;
  String? _status;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final hasDrafts = widget.facts.any(
      (fact) => fact.status == AdminFact.draft,
    );
    _status = hasDrafts ? AdminFact.draft : null;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AdminFact> get _visible {
    final query = _search.text.trim().toLowerCase();
    return widget.facts.where((fact) {
      if (_status != null && fact.status != _status) return false;
      if (_category != _allCategories && fact.category != _category) {
        return false;
      }
      if (query.isEmpty) return true;
      return fact.title.toLowerCase().contains(query) ||
          fact.shortText.toLowerCase().contains(query) ||
          fact.id.toLowerCase().contains(query);
    }).toList();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _download() {
    widget.onDownload(
      'ciekawostki.csv',
      widget.csvService.encode(widget.facts),
    );
  }

  Future<void> _setStatus(List<String> ids, String status) async {
    setState(() => _isBusy = true);
    try {
      await widget.adminService.setStatus(ids, status);
      _selected.removeAll(ids);
      await widget.onChanged();
    } catch (_) {
      if (mounted) _showMessage('Nie udało się zapisać zmiany.');
    }
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _edit(AdminFact fact) async {
    final edited = await FactEditDialog.show(
      context,
      fact,
      categories: widget.categories,
    );
    if (edited == null) return;

    try {
      await widget.adminService.updateFact(edited);
      await widget.onChanged();
    } catch (_) {
      if (mounted) _showMessage('Nie udało się zapisać zmiany.');
    }
  }

  void _selectVisible(List<AdminFact> visible) {
    setState(() {
      final ids = visible.map((fact) => fact.id);
      if (_selected.containsAll(ids)) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.all(16), child: _buildFilters()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Widocznych: ${visible.length}'),
              TextButton(
                onPressed: visible.isEmpty
                    ? null
                    : () => _selectVisible(visible),
                child: const Text('Zaznacz widoczne'),
              ),
              if (_selected.isNotEmpty) ...[
                FilledButton(
                  onPressed: _isBusy
                      ? null
                      : () =>
                            _setStatus(_selected.toList(), AdminFact.published),
                  child: Text('Opublikuj (${_selected.length})'),
                ),
                OutlinedButton(
                  onPressed: _isBusy
                      ? null
                      : () =>
                            _setStatus(_selected.toList(), AdminFact.rejected),
                  child: Text('Odrzuć (${_selected.length})'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Pobierz CSV dla czatu'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) => _buildTile(visible[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Szukaj',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        DropdownButton<String>(
          value: _category,
          onChanged: (value) => setState(() => _category = value!),
          items: [
            const DropdownMenuItem(
              value: _allCategories,
              child: Text('Wszystkie kategorie'),
            ),
            for (final name in widget.categories)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
        ),
        DropdownButton<String?>(
          value: _status,
          onChanged: (value) => setState(() => _status = value),
          items: [
            const DropdownMenuItem(child: Text('Wszystkie statusy')),
            for (final MapEntry(key: status, value: label)
                in _statusLabels.entries)
              DropdownMenuItem(value: status, child: Text(label)),
          ],
        ),
      ],
    );
  }

  Widget _buildTile(AdminFact fact) {
    final theme = Theme.of(context);
    final note = fact.reviewNote;
    return CheckboxListTile(
      value: _selected.contains(fact.id),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (isChecked) => setState(() {
        isChecked! ? _selected.add(fact.id) : _selected.remove(fact.id);
      }),
      title: Text(fact.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(fact.shortText),
          Text(
            '${fact.category} · ${_statusNames[fact.status] ?? fact.status} · '
            '${fact.id}',
            style: theme.textTheme.bodySmall,
          ),
          if (note != null)
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      secondary: _buildMenu(fact),
    );
  }

  Widget _buildMenu(AdminFact fact) {
    return PopupMenuButton<String>(
      tooltip: 'Działania',
      onSelected: (status) {
        status.isEmpty ? _edit(fact) : _setStatus([fact.id], status);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: '', child: Text('Edytuj')),
        if (fact.status != AdminFact.published)
          const PopupMenuItem(
            value: AdminFact.published,
            child: Text('Opublikuj'),
          ),
        if (fact.status == AdminFact.published)
          const PopupMenuItem(
            value: AdminFact.withdrawn,
            child: Text('Wycofaj'),
          ),
        if (fact.status == AdminFact.draft)
          const PopupMenuItem(value: AdminFact.rejected, child: Text('Odrzuć')),
      ],
    );
  }
}
