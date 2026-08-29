import 'package:flutter/material.dart';

import '../helpers/pattern_hint.dart';
import 'product_chrome.dart';

/// Dismissible maintenance suggestion from repeated on-device history.
class PatternHintCard extends StatelessWidget {
  const PatternHintCard({
    required this.hint,
    required this.onDismiss,
    super.key,
  });

  final PatternHint hint;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return PaperCard(
      child: Column(
        key: const Key('pattern-hint-card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hint.title,
            key: const Key('pattern-hint-title'),
            style: text.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            hint.body,
            key: const Key('pattern-hint-body'),
            style: text.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('pattern-hint-dismiss'),
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ),
        ],
      ),
    );
  }
}
