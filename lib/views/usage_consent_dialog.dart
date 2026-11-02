import 'package:flutter/material.dart';

/// Asks the web demo's visitor about statistics. Both answers look the same,
/// so neither is pushed.
class UsageConsentDialog extends StatelessWidget {
  const UsageConsentDialog({super.key});

  /// Answers whether the visitor agreed.
  static Future<bool> show(BuildContext context) async {
    final isAllowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UsageConsentDialog(),
    );
    return isAllowed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anonimowe statystyki'),
      content: const Text(
        'Czy możemy zbierać anonimowe statystyki, na przykład ile kart '
        'przejrzano i jak poszedł quiz? Pomagają ulepszać aplikację i '
        'ciekawostki. Zmienisz to w każdej chwili w ustawieniach.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Nie zgadzam się'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Zgadzam się'),
        ),
      ],
    );
  }
}
