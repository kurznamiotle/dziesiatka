import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.factsService});

  final FactsService factsService;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Fact>? _favorites;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final facts = await widget.factsService.getFacts();
    if (!mounted) return;

    setState(() {
      _favorites = facts.where((fact) => fact.isFavorite).toList();
    });
  }

  Future<void> _removeFavorite(Fact fact) async {
    try {
      await widget.factsService.toggleFavorite(fact.id);
      await _loadFavorites();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zapisać zmian.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ulubione')),
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    final favorites = _favorites;
    if (favorites == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favorites.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nie masz jeszcze ulubionych ciekawostek. '
            'Przesuń kartę w prawo, aby ją zapisać.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final fact = favorites[index];
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
          subtitle: Text(fact.category),
          onTap: () => FactDetailsSheet.show(context, fact),
          trailing: IconButton(
            tooltip: 'Usuń z ulubionych',
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () => _removeFavorite(fact),
          ),
        );
      },
    );
  }
}
