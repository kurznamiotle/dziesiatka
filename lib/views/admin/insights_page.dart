import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_performance.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/services/admin_stats_service.dart';
import 'package:dziesiatka/views/admin/dashboard_page.dart';
import 'package:flutter/material.dart';

const _rankingSize = 20;

/// Which facts, questions and categories work, once there is enough data.
class InsightsPage extends StatelessWidget {
  const InsightsPage({
    super.key,
    required this.facts,
    required this.categories,
    required this.factUsage,
    this.statsService = const AdminStatsService(),
  });

  final List<AdminFact> facts;
  final Set<String> categories;
  final Map<String, FactUsage> factUsage;
  final AdminStatsService statsService;

  @override
  Widget build(BuildContext context) {
    final ranked = statsService.rankFacts(facts, factUsage);
    final suspicious = statsService.suspiciousQuestions(facts, factUsage);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Najlepsze'),
              Tab(text: 'Najsłabsze'),
              Tab(text: 'Podejrzane pytania'),
              Tab(text: 'Kategorie'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FactList(
                  items: ranked.take(_rankingSize).toList(),
                  emptyText: _notEnoughData,
                ),
                _FactList(
                  items: ranked.reversed.take(_rankingSize).toList(),
                  emptyText: _notEnoughData,
                ),
                _FactList(
                  items: suspicious,
                  showQuiz: true,
                  emptyText:
                      'Brak podejrzanych pytań. Pytanie trafia tu przy co '
                      'najmniej ${AdminStatsService.minAnswersForQuizCheck} '
                      'odpowiedziach, gdy prawie nikt nie trafia albo nikt '
                      'się nie myli.',
                ),
                _buildCategories(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _notEnoughData =
      'Za mało danych. Ciekawostka trafia do rankingu po '
      '${AdminStatsService.minShownForRanking} pokazaniach.';

  Widget _buildCategories() {
    final items = statsService.categories(facts, factUsage, categories)
      ..sort((a, b) => (b.likedPercent ?? -1).compareTo(a.likedPercent ?? -1));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Kategoria')),
            DataColumn(label: Text('Pokazania'), numeric: true),
            DataColumn(label: Text('Polubienia'), numeric: true),
            DataColumn(label: Text('Rozwinięcia'), numeric: true),
          ],
          rows: [
            for (final item in items)
              DataRow(
                cells: [
                  DataCell(Text(item.category)),
                  DataCell(Text('${item.shown}')),
                  DataCell(Text(formatPercent(item.likedPercent))),
                  DataCell(Text(formatPercent(item.openedPercent))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FactList extends StatelessWidget {
  const _FactList({
    required this.items,
    required this.emptyText,
    this.showQuiz = false,
  });

  final List<FactPerformance> items;
  final String emptyText;
  final bool showQuiz;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final question = item.fact.quiz?.question;
        return ListTile(
          title: Text(item.fact.title),
          subtitle: Text(
            showQuiz
                ? '${question ?? ''}\n${item.fact.category} · ${item.answers} '
                      'odpowiedzi'
                : '${item.fact.category} · pokazania: ${item.usage.shown} · '
                      'rozwinięcia: ${formatPercent(item.openedPercent)}',
          ),
          trailing: Text(
            formatPercent(showQuiz ? item.quizPercent : item.likedPercent),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }
}
