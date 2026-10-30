import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:dziesiatka/views/share_card_sheet.dart';
import 'package:flutter/material.dart';

class FactDetailsSheet extends StatelessWidget {
  const FactDetailsSheet({super.key, required this.fact});

  static Future<void> show(BuildContext context, Fact fact) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // useSafeArea leaves the bottom inset to the sheet's content.
      builder: (_) => SafeArea(top: false, child: FactDetailsSheet(fact: fact)),
    );
  }

  final Fact fact;

  Future<void> _openSource(BuildContext context, String url) async {
    final opened = await const LinkService().open(url);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nie udało się otworzyć linku.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sourceUrl = fact.sourceUrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: CategoryBadge(category: fact.category)),
              IconButton(
                tooltip: 'Udostępnij',
                onPressed: () => ShareCardSheet.show(context, fact),
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fact.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fact.longText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          if (fact.sourceLabel.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Źródło',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (sourceUrl != null && const LinkService().isWebLink(sourceUrl))
              InkWell(
                onTap: () => _openSource(context, sourceUrl),
                child: Text(
                  fact.sourceLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  ),
                ),
              )
            else
              SelectableText(
                fact.sourceLabel,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ],
      ),
    );
  }
}
