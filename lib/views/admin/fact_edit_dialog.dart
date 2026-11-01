import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:flutter/material.dart';

const _dialogWidth = 560.0;

class FactEditDialog extends StatefulWidget {
  const FactEditDialog({
    super.key,
    required this.fact,
    required this.categories,
  });

  final AdminFact fact;
  final Set<String> categories;

  /// Returns the edited fact, or null if the dialog was closed.
  static Future<AdminFact?> show(
    BuildContext context,
    AdminFact fact, {
    required Set<String> categories,
  }) {
    return showDialog<AdminFact>(
      context: context,
      builder: (_) => FactEditDialog(fact: fact, categories: categories),
    );
  }

  @override
  State<FactEditDialog> createState() => _FactEditDialogState();
}

class _FactEditDialogState extends State<FactEditDialog> {
  late final _title = TextEditingController(text: widget.fact.title);
  late final _shortText = TextEditingController(text: widget.fact.shortText);
  late final _longText = TextEditingController(text: widget.fact.longText);
  late final _sourceLabel = TextEditingController(
    text: widget.fact.sourceLabel,
  );
  late final _sourceUrl = TextEditingController(text: widget.fact.sourceUrl);
  late final _reviewNote = TextEditingController(text: widget.fact.reviewNote);
  late final _question = TextEditingController(
    text: widget.fact.quiz?.question,
  );
  late final _options = [
    for (var i = 0; i < AdminFact.quizOptionCount; i++)
      TextEditingController(
        text: (widget.fact.quiz?.options.length ?? 0) > i
            ? widget.fact.quiz!.options[i]
            : '',
      ),
  ];
  late String _category = widget.fact.category;
  late int _correctIndex = widget.fact.quiz?.correctIndex ?? 0;
  List<String> _errors = const [];

  @override
  void dispose() {
    for (final controller in [
      _title,
      _shortText,
      _longText,
      _sourceLabel,
      _sourceUrl,
      _reviewNote,
      _question,
      ..._options,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  AdminFact _edited() {
    final question = _textOrNull(_question);
    return widget.fact.withEdits(
      title: _title.text,
      category: _category,
      shortText: _shortText.text,
      longText: _longText.text,
      sourceLabel: _sourceLabel.text,
      sourceUrl: _textOrNull(_sourceUrl),
      reviewNote: _textOrNull(_reviewNote),
      quiz: question == null
          ? null
          : QuizQuestion(
              question: question,
              options: [for (final option in _options) option.text.trim()],
              correctIndex: _correctIndex,
            ),
    );
  }

  void _save() {
    final edited = _edited();
    // Facts in any status follow the same content rules.
    final errors = edited
        .copyWith(status: AdminFact.draft)
        .validationErrors(widget.categories);
    if (errors.isEmpty) {
      Navigator.of(context).pop(edited);
    } else {
      setState(() => _errors = errors);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('Edycja: ${widget.fact.id}'),
      content: SizedBox(
        width: _dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              const SizedBox(height: 4),
              _field(_title, 'Tytuł', maxLength: AdminFact.maxTitleLength),
              DropdownButtonFormField<String>(
                initialValue: widget.categories.contains(_category)
                    ? _category
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Kategoria',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _category = value!),
                items: [
                  for (final name in widget.categories)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
              ),
              _field(
                _shortText,
                'Krótki tekst',
                maxLength: AdminFact.maxShortTextLength,
                maxLines: 3,
              ),
              _field(_longText, 'Długi tekst', maxLines: 8),
              _field(_sourceLabel, 'Nazwa źródła'),
              _field(_sourceUrl, 'Adres źródła'),
              _field(_reviewNote, 'Uwaga do szkicu', maxLines: 3),
              _field(_question, 'Pytanie quizowe', maxLines: 2),
              RadioGroup<int>(
                groupValue: _correctIndex,
                onChanged: (value) => setState(() => _correctIndex = value!),
                child: Column(
                  spacing: 8,
                  children: [
                    for (final (index, option) in _options.indexed)
                      Row(
                        children: [
                          Radio<int>(value: index),
                          Expanded(
                            child: _field(option, 'Odpowiedź ${index + 1}'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              for (final error in _errors)
                Text(error, style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _save, child: const Text('Zapisz')),
      ],
    );
  }
}
