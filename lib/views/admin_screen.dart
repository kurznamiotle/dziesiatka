import 'package:dziesiatka/models/database_snapshot.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/backup_service.dart';
import 'package:dziesiatka/services/categories_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';

const _maxShortTextLength = 200;
const _maxCategoryLength = 30;
const _newCategoryValue = '__new_category__';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _factsService = FactsService();
  final _categoriesService = CategoriesService();
  late final _backupService = BackupService(_factsService, _categoriesService);

  List<Fact>? _facts;
  List<String> _categories = const [];
  String _exportJson = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final facts = await _factsService.getFacts();
    final categories = await _categoriesService.getCategories();
    final exportJson = await _backupService.exportJson();
    if (!mounted) return;

    setState(() {
      _facts = facts;
      _categories = categories;
      _exportJson = exportJson;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Returns whether [change] was saved, so forms know if they can clear.
  Future<bool> _save(
    Future<void> Function() change, {
    required String successMessage,
  }) async {
    try {
      await change();
      await _reload();
    } catch (_) {
      if (mounted) _showMessage('Nie udało się zapisać zmian.');
      return false;
    }
    if (mounted) _showMessage(successMessage);
    return true;
  }

  Future<String?> _addCategory(String name) async {
    try {
      final category = await _categoriesService.addCategory(name);
      await _reload();
      return category;
    } catch (_) {
      if (mounted) _showMessage('Nie udało się zapisać kategorii.');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final facts = _facts;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel twórcy'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dodaj'),
              Tab(text: 'Fakty'),
              Tab(text: 'Dane'),
            ],
          ),
        ),
        body: SafeArea(
          child: facts == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _AddFactTab(
                      categories: _categories,
                      onAddCategory: _addCategory,
                      onSave:
                          ({
                            required title,
                            required category,
                            required shortText,
                            required longText,
                            required source,
                          }) => _save(
                            () => _factsService.addFact(
                              title: title,
                              category: category,
                              shortText: shortText,
                              longText: longText,
                              source: source,
                            ),
                            successMessage: 'Dodano ciekawostkę.',
                          ),
                    ),
                    _FactsTab(
                      facts: facts,
                      onDelete: (fact) => _save(
                        () => _factsService.deleteFact(fact.id),
                        successMessage: 'Usunięto ciekawostkę.',
                      ),
                    ),
                    _DataTab(
                      exportJson: _exportJson,
                      backupService: _backupService,
                      onRestore: (snapshot) => _save(
                        () => _backupService.restore(snapshot),
                        successMessage: 'Zaimportowano bazę.',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

String? _validateRequired(String? value) {
  final isEmpty = value == null || value.trim().isEmpty;
  return isEmpty ? 'To pole jest wymagane.' : null;
}

class _AddFactTab extends StatefulWidget {
  const _AddFactTab({
    required this.categories,
    required this.onAddCategory,
    required this.onSave,
  });

  final List<String> categories;
  final Future<String?> Function(String name) onAddCategory;
  final Future<bool> Function({
    required String title,
    required String category,
    required String shortText,
    required String longText,
    required String source,
  })
  onSave;

  @override
  State<_AddFactTab> createState() => _AddFactTabState();
}

class _AddFactTabState extends State<_AddFactTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortTextController = TextEditingController();
  final _longTextController = TextEditingController();
  final _sourceController = TextEditingController();
  String? _category;
  // Dropdown fields only read their initial value once, so a new key is what
  // moves the selection after adding a category or cancelling that dialog.
  int _dropdownRevision = 0;
  bool _isSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _titleController.dispose();
    _shortTextController.dispose();
    _longTextController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  String? _validateCategory(String? value) {
    final isMissing = value == null || value == _newCategoryValue;
    return isMissing ? 'Wybierz kategorię.' : null;
  }

  String? _validateSource(String? value) {
    final requiredError = _validateRequired(value);
    if (requiredError != null) return requiredError;

    final source = value!.trim();
    final looksLikeLink =
        source.startsWith('http://') || source.startsWith('https://');
    if (looksLikeLink && !const LinkService().isWebLink(source)) {
      return 'To nie jest poprawny link.';
    }
    return null;
  }

  Future<void> _onCategoryChanged(String? value) async {
    if (value != _newCategoryValue) {
      setState(() => _category = value);
      return;
    }

    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewCategoryDialog(),
    );
    final added = name == null ? null : await widget.onAddCategory(name);
    if (!mounted) return;

    setState(() {
      _category = added ?? _category;
      _dropdownRevision++;
    });
  }

  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final saved = await widget.onSave(
      title: _titleController.text.trim(),
      category: _category!,
      shortText: _shortTextController.text.trim(),
      longText: _longTextController.text.trim(),
      source: _sourceController.text.trim(),
    );
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!saved) return;
    // Reset first: it restores the text from the last build, so clearing the
    // controllers has to come after it.
    _formKey.currentState!.reset();
    _titleController.clear();
    _shortTextController.clear();
    _longTextController.clear();
    _sourceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final brightness = Theme.of(context).brightness;
    // An import can remove the selected category from the list.
    final selected = widget.categories.contains(_category) ? _category : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            TextFormField(
              controller: _titleController,
              validator: _validateRequired,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nagłówek',
                border: OutlineInputBorder(),
              ),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('$selected/$_dropdownRevision'),
              initialValue: selected,
              isExpanded: true,
              validator: _validateCategory,
              onChanged: _onCategoryChanged,
              decoration: const InputDecoration(
                labelText: 'Kategoria',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category,
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(
                          CategoryStyle.of(category, brightness).icon,
                          size: 20,
                          color: CategoryStyle.of(category, brightness).color,
                        ),
                        Expanded(
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const DropdownMenuItem(
                  value: _newCategoryValue,
                  child: Text('+ Dodaj nową kategorię'),
                ),
              ],
            ),
            TextFormField(
              controller: _shortTextController,
              validator: _validateRequired,
              minLines: 2,
              maxLines: 4,
              maxLength: _maxShortTextLength,
              decoration: const InputDecoration(
                labelText: 'Tekst krótki (zajawka na fiszkę)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: _longTextController,
              validator: _validateRequired,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Tekst długi (rozwinięcie)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: _sourceController,
              validator: _validateSource,
              decoration: const InputDecoration(
                labelText: 'Źródło (link lub nazwa publikacji)',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nowa kategoria'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          maxLength: _maxCategoryLength,
          validator: _validateRequired,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Nazwa kategorii'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Dodaj')),
      ],
    );
  }
}

class _FactsTab extends StatelessWidget {
  const _FactsTab({required this.facts, required this.onDelete});

  final List<Fact> facts;
  final Future<bool> Function(Fact fact) onDelete;

  Future<void> _confirmDelete(BuildContext context, Fact fact) async {
    final confirmed = await _confirm(
      context,
      title: 'Usunąć ciekawostkę?',
      message: '„${fact.title}” zostanie trwale usunięta.',
      action: 'Usuń',
    );
    if (confirmed) await onDelete(fact);
  }

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const Center(child: Text('Brak zapisanych ciekawostek.'));
    }

    final newestFirst = facts.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: newestFirst.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final fact = newestFirst[index];
        final style = CategoryStyle.of(
          fact.category,
          Theme.of(context).brightness,
        );
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: style.background,
            child: Icon(style.icon, size: 20, color: style.color),
          ),
          title: Text(fact.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            fact.isRead ? '${fact.category} · przeczytane' : fact.category,
          ),
          onTap: () => FactDetailsSheet.show(context, fact),
          trailing: IconButton(
            tooltip: 'Usuń',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, fact),
          ),
        );
      },
    );
  }
}

class _DataTab extends StatefulWidget {
  const _DataTab({
    required this.exportJson,
    required this.backupService,
    required this.onRestore,
  });

  final String exportJson;
  final BackupService backupService;
  final Future<bool> Function(DatabaseSnapshot snapshot) onRestore;

  @override
  State<_DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<_DataTab> {
  final _importController = TextEditingController();
  String? _importError;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyExport() async {
    try {
      await widget.backupService.copyToClipboard(widget.exportJson);
      if (mounted) _showMessage('Skopiowano JSON do schowka.');
    } catch (_) {
      if (mounted) {
        _showMessage('Nie udało się skopiować. Zaznacz tekst ręcznie.');
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final text = await widget.backupService.readClipboard();
      if (text != null) _importController.text = text;
    } catch (_) {
      if (mounted) {
        _showMessage('Brak dostępu do schowka. Wklej tekst ręcznie.');
      }
    }
  }

  Future<void> _import() async {
    final DatabaseSnapshot snapshot;
    try {
      snapshot = widget.backupService.parse(_importController.text);
    } on FormatException catch (error) {
      setState(() => _importError = error.message);
      return;
    }
    setState(() => _importError = null);

    final confirmed = await _confirm(
      context,
      title: 'Zastąpić całą bazę?',
      message:
          'Obecne fakty i kategorie zostaną zastąpione danymi z importu '
          '(fakty: ${snapshot.facts.length}, '
          'kategorie: ${snapshot.categories.length}). '
          'Tej operacji nie można cofnąć.',
      action: 'Zastąp',
    );
    if (!confirmed) return;

    final restored = await widget.onRestore(snapshot);
    if (restored) _importController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text('Eksport', style: theme.textTheme.titleMedium),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              height: 160,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  widget.exportJson,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _copyExport,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Kopiuj do schowka'),
          ),
          const SizedBox(height: 12),
          Text('Import', style: theme.textTheme.titleMedium),
          TextField(
            controller: _importController,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Wklej JSON z eksportu',
              alignLabelWithHint: true,
              errorText: _importError,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pasteFromClipboard,
            icon: const Icon(Icons.content_paste_rounded),
            label: const Text('Wklej ze schowka'),
          ),
          FilledButton.icon(
            onPressed: _import,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Importuj i zastąp bazę'),
          ),
        ],
      ),
    );
  }
}
