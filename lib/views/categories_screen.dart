import 'package:dziesiatka/services/category_preferences_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.factsService,
    this.preferencesService = const CategoryPreferencesService(),
  });

  final FactsService factsService;
  final CategoryPreferencesService preferencesService;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String>? _categories;
  Set<String> _disabled = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await widget.factsService.getCategories();
    final disabled = await widget.preferencesService.getDisabled();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _disabled = disabled;
    });
  }

  bool _isLastEnabled(String category) {
    final enabled = _categories!.where((name) => !_disabled.contains(name));
    return enabled.length == 1 && enabled.first == category;
  }

  Future<void> _toggle(String category, bool isEnabled) async {
    setState(() {
      isEnabled ? _disabled.remove(category) : _disabled.add(category);
    });
    await widget.preferencesService.setEnabled(category, isEnabled: isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kategorie')),
      body: SafeArea(
        child: categories == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Wybierz, o czym chcesz czytać. '
                      'Zmiana zadziała od następnej talii.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final category in categories) _buildTile(category),
                ],
              ),
      ),
    );
  }

  Widget _buildTile(String category) {
    final theme = Theme.of(context);
    final style = CategoryStyle.of(category, theme.brightness);
    return SwitchListTile(
      secondary: Icon(style.icon, color: style.color),
      title: Text(category),
      value: !_disabled.contains(category),
      // At least one stays on, or there would be nothing to choose a deck from.
      onChanged: _isLastEnabled(category)
          ? null
          : (isEnabled) => _toggle(category, isEnabled),
    );
  }
}
