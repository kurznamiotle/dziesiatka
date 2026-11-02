import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_report.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/usage_row.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:dziesiatka/views/admin/dashboard_page.dart';
import 'package:dziesiatka/views/admin/facts_page.dart';
import 'package:dziesiatka/views/admin/import_page.dart';
import 'package:dziesiatka/views/admin/insights_page.dart';
import 'package:dziesiatka/views/admin/reports_page.dart';
import 'package:flutter/material.dart';

/// Below this width the navigation moves from the side to the bottom.
const _wideLayoutWidth = 800.0;

const _destinations = [
  (icon: Icons.dashboard_outlined, label: 'Pulpit'),
  (icon: Icons.list_alt_rounded, label: 'Ciekawostki'),
  (icon: Icons.upload_file_rounded, label: 'Import'),
  (icon: Icons.leaderboard_outlined, label: 'Ranking'),
  (icon: Icons.flag_outlined, label: 'Zgłoszenia'),
];

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.adminService,
    required this.onSignOut,
  });

  final AdminService adminService;
  final VoidCallback onSignOut;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _page = 0;
  bool _isLoading = true;
  bool _loadFailed = false;
  List<AdminFact> _facts = const [];
  Set<String> _categories = const {};
  List<UsageRow> _usage = const [];
  Map<String, FactUsage> _factUsage = const {};
  List<FactReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final service = widget.adminService;
      final facts = await service.loadFacts();
      final categories = await service.loadCategories();
      final usage = await service.loadUsage();
      final factUsage = await service.loadFactUsage();
      final reports = await service.loadReports();
      if (!mounted) return;
      setState(() {
        _facts = facts;
        _categories = categories;
        _usage = usage;
        _factUsage = factUsage;
        _reports = reports;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Widget _buildPage() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Text('Nie udało się wczytać danych.'),
            FilledButton(
              onPressed: _load,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    return switch (_page) {
      0 => DashboardPage(
        facts: _facts,
        categories: _categories,
        usage: _usage,
        factUsage: _factUsage,
      ),
      1 => FactsPage(
        facts: _facts,
        categories: _categories,
        adminService: widget.adminService,
        onChanged: _load,
      ),
      2 => ImportPage(
        facts: _facts,
        categories: _categories,
        adminService: widget.adminService,
        onSaved: _load,
      ),
      3 => InsightsPage(
        facts: _facts,
        categories: _categories,
        factUsage: _factUsage,
      ),
      _ => ReportsPage(
        reports: _reports,
        facts: _facts,
        adminService: widget.adminService,
        onChanged: _load,
      ),
    };
  }

  void _selectPage(int page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideLayoutWidth;
    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_page].label),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Wyloguj',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: _selectPage,
              destinations: [
                for (final item in _destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _page,
              onDestinationSelected: _selectPage,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final item in _destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }
}
