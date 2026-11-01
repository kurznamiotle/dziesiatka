import 'dart:math';

import 'package:dziesiatka/services/category_preferences_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:flutter/material.dart';

const _tileAspectRatio = 2.1;

/// Lets a new user choose their favorite categories before the first deck.
class FavoriteCategoriesScreen extends StatefulWidget {
  const FavoriteCategoriesScreen({
    super.key,
    required this.factsService,
    required this.onFinished,
    this.onChosen,
    this.preferencesService = const CategoryPreferencesService(),
  });

  final FactsService factsService;
  final VoidCallback onFinished;

  /// Reports whether the user took all categories.
  final void Function({required bool choseAll})? onChosen;
  final CategoryPreferencesService preferencesService;

  @override
  State<FavoriteCategoriesScreen> createState() =>
      _FavoriteCategoriesScreenState();
}

class _FavoriteCategoriesScreenState extends State<FavoriteCategoriesScreen> {
  List<String>? _categories;
  final _chosen = <String>{};

  int get _required {
    return min(CategoryPreferencesService.minFavorites, _categories!.length);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// A failure here must not stand between a new user and the deck, and all
  /// categories stay on by default.
  Future<void> _load() async {
    try {
      // An update brings new bundled facts, which only the deck adds otherwise.
      await widget.factsService.syncWithSeed();
      final categories = await widget.factsService.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      if (mounted) widget.onFinished();
    }
  }

  void _toggle(String category) {
    setState(() {
      if (!_chosen.remove(category)) _chosen.add(category);
    });
  }

  Future<void> _finish(Set<String> favorites) async {
    widget.onChosen?.call(choseAll: favorites.length == _categories!.length);
    try {
      await widget.preferencesService.saveFavorites(
        favorites,
        allCategories: _categories!,
      );
    } catch (_) {
      // All categories stay on, and the settings can change that later.
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Gotowe!'),
        content: const Text(
          'Ulubione kategorie możesz zmienić w każdej chwili w ustawieniach, '
          'w sekcji Kategorie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Rozumiem'),
          ),
        ],
      ),
    );
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return Scaffold(
      body: SafeArea(
        child: categories == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _buildContent(categories),
              ),
      ),
    );
  }

  Widget _buildContent(List<String> categories) {
    final theme = Theme.of(context);
    final missing = _required - _chosen.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _finish(categories.toSet()),
            child: const Text('Chcę wszystkie'),
          ),
        ),
        Text(
          'Co Cię ciekawi?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wybierz co najmniej $_required kategorie. Z nich będzie większość '
          'kart, a pozostałe pojawią się od czasu do czasu.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: _tileAspectRatio,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final category in categories)
                _CategoryTile(
                  category: category,
                  isChosen: _chosen.contains(category),
                  onTap: () => _toggle(category),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: missing > 0 ? null : () => _finish(_chosen),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: Text(missing > 0 ? 'Wybierz jeszcze $missing' : 'Gotowe'),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isChosen,
    required this.onTap,
  });

  final String category;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = CategoryStyle.of(category, theme.brightness);
    final foreground = isChosen ? Colors.white : style.color;
    return Semantics(
      button: true,
      selected: isChosen,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        color: theme.extension<AppSurfaces>()!.card,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isChosen ? LinearGradient(colors: style.gradient) : null,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                spacing: 8,
                children: [
                  Icon(
                    isChosen ? Icons.check_circle_rounded : style.icon,
                    color: foreground,
                  ),
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isChosen ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
