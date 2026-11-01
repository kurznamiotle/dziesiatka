import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/category_performance.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/usage_row.dart';
import 'package:dziesiatka/models/usage_summary.dart';
import 'package:dziesiatka/services/admin_stats_service.dart';
import 'package:flutter/material.dart';

const _shownDays = 14;

/// A category with less than this is worth refilling soon.
const _lowStockDays = 30;

String formatPercent(double? value) {
  return value == null ? '–' : '${value.toStringAsFixed(0)}%';
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.facts,
    required this.categories,
    required this.usage,
    required this.factUsage,
    this.statsService = const AdminStatsService(),
    this.now,
  });

  final List<AdminFact> facts;
  final Set<String> categories;
  final List<UsageRow> usage;
  final Map<String, FactUsage> factUsage;
  final AdminStatsService statsService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final moment = (now ?? DateTime.now)();
    final today = DateTime.utc(moment.year, moment.month, moment.day);
    final summary = statsService.summarize(usage, today: today);
    final stock = statsService.categories(facts, factUsage, categories);
    final published = facts
        .where((fact) => fact.status == AdminFact.published)
        .length;
    final drafts = facts.where((fact) => fact.status == AdminFact.draft).length;
    final latest = summary.days.isEmpty ? null : summary.days.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatTile('Instalacje', '${summary.installs}'),
            _StatTile('Ostatni dzień', '${latest?.activeUsers ?? 0}'),
            _StatTile(
              'Powrót po 1 dniu',
              formatPercent(summary.returnedAfterDay),
            ),
            _StatTile(
              'Powrót po 7 dniach',
              formatPercent(summary.returnedAfterWeek),
            ),
            _StatTile(
              'Poprawne w quizie',
              formatPercent(summary.quizCorrectPercent),
            ),
            _StatTile('Rundy „Jeszcze 5”', '${summary.bonusRounds}'),
            _StatTile('Opublikowane', '$published'),
            _StatTile('Szkice', '$drafts'),
          ],
        ),
        const _Heading('Zapas ciekawostek'),
        _StockTable(stock: stock),
        const _Heading('Pierwsze uruchomienie'),
        _FirstRunList(summary: summary),
        const _Heading('Ostatnie dni'),
        _DaysTable(days: summary.days.take(_shownDays).toList()),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockTable extends StatelessWidget {
  const _StockTable({required this.stock});

  final List<CategoryPerformance> stock;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Kategoria')),
          DataColumn(label: Text('Opublikowane'), numeric: true),
          DataColumn(label: Text('Szkice'), numeric: true),
          DataColumn(label: Text('Wystarczy na dni'), numeric: true),
        ],
        rows: [
          for (final item in stock)
            DataRow(
              cells: [
                DataCell(Text(item.category)),
                DataCell(Text('${item.published}')),
                DataCell(Text('${item.drafts}')),
                DataCell(
                  Text(
                    '${item.daysLeft}',
                    style: item.daysLeft < _lowStockDays
                        ? TextStyle(
                            color: errorColor,
                            fontWeight: FontWeight.w700,
                          )
                        : null,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FirstRunList extends StatelessWidget {
  const _FirstRunList({required this.summary});

  final UsageSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatTile('Instrukcja do końca', '${summary.finishedInstructions}'),
        _StatTile('Instrukcja pominięta', '${summary.skippedInstructions}'),
        _StatTile('Wybrane ulubione', '${summary.choseFavorites}'),
        _StatTile('„Chcę wszystkie”', '${summary.choseAllCategories}'),
        _StatTile('Zgoda na powiadomienia', '${summary.allowedNotifications}'),
        _StatTile('Brak zgody', '${summary.deniedNotifications}'),
        _StatTile('Pierwsza talia ukończona', '${summary.finishedFirstDeck}'),
      ],
    );
  }
}

class _DaysTable extends StatelessWidget {
  const _DaysTable({required this.days});

  final List<DailyUsage> days;

  String _date(DateTime day) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(day.day)}.${twoDigits(day.month)}.${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const Text('Brak danych.');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Dzień')),
          DataColumn(label: Text('Aktywni'), numeric: true),
          DataColumn(label: Text('Ukończone talie'), numeric: true),
          DataColumn(label: Text('Średnio kart'), numeric: true),
        ],
        rows: [
          for (final day in days)
            DataRow(
              cells: [
                DataCell(Text(_date(day.day))),
                DataCell(Text('${day.activeUsers}')),
                DataCell(Text('${day.finishedDeck}')),
                DataCell(Text(day.averageCards.toStringAsFixed(1))),
              ],
            ),
        ],
      ),
    );
  }
}
