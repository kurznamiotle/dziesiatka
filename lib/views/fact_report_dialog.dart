import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_report.dart';
import 'package:dziesiatka/services/fact_report_service.dart';
import 'package:flutter/material.dart';

const _maxCommentLength = 500;

class FactReportDialog extends StatefulWidget {
  const FactReportDialog({
    super.key,
    required this.fact,
    required this.reportService,
  });

  static Future<void> show(
    BuildContext context,
    Fact fact,
    FactReportService reportService,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          FactReportDialog(fact: fact, reportService: reportService),
    );
  }

  final Fact fact;
  final FactReportService reportService;

  @override
  State<FactReportDialog> createState() => _FactReportDialogState();
}

class _FactReportDialogState extends State<FactReportDialog> {
  final _comment = TextEditingController();
  FactReportReason _reason = FactReportReason.wrongFact;
  bool _isSending = false;
  bool _isSent = false;
  bool _sendFailed = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _isSending = true;
      _sendFailed = false;
    });
    final isSent = await widget.reportService.send(
      widget.fact.id,
      _reason,
      _comment.text,
    );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _isSent = isSent;
      _sendFailed = !isSent;
    });
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    if (_isSent) {
      return AlertDialog(
        title: const Text('Dziękujemy!'),
        content: const Text('Sprawdzimy tę ciekawostkę.'),
        actions: [TextButton(onPressed: _close, child: const Text('Zamknij'))],
      );
    }

    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Zgłoś błąd'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<FactReportReason>(
              groupValue: _reason,
              onChanged: (reason) => setState(() => _reason = reason!),
              child: Column(
                children: [
                  for (final reason in FactReportReason.values)
                    RadioListTile<FactReportReason>(
                      contentPadding: EdgeInsets.zero,
                      value: reason,
                      title: Text(reason.label),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comment,
              maxLength: _maxCommentLength,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Co jest nie tak? (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_sendFailed)
              Text(
                'Nie udało się wysłać. Spróbuj ponownie.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _close, child: const Text('Anuluj')),
        FilledButton(
          onPressed: _isSending ? null : _send,
          child: const Text('Wyślij'),
        ),
      ],
    );
  }
}
