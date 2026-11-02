import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_report.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:flutter/material.dart';

/// Mistakes reported by readers. A handled report is removed for good.
class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    required this.reports,
    required this.facts,
    required this.adminService,
    required this.onChanged,
  });

  final List<FactReport> reports;
  final List<AdminFact> facts;
  final AdminService adminService;
  final VoidCallback onChanged;

  String _titleOf(String factId) {
    for (final fact in facts) {
      if (fact.id == factId) return fact.title;
    }
    return factId;
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year}';
  }

  String _describe(FactReport report) {
    final summary = '${_formatDate(report.createdAt)} · ${report.reason.label}';
    return report.comment.isEmpty ? summary : '$summary\n${report.comment}';
  }

  Future<void> _resolve(BuildContext context, FactReport report) async {
    try {
      await adminService.deleteReport(report.id);
      onChanged();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się usunąć zgłoszenia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(child: Text('Brak zgłoszeń.'));
    }

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return ListTile(
          title: Text(_titleOf(report.factId)),
          subtitle: Text(_describe(report)),
          trailing: TextButton(
            onPressed: () => _resolve(context, report),
            child: const Text('Załatwione'),
          ),
        );
      },
    );
  }
}
