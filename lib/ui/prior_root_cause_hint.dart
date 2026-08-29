import 'package:flutter/material.dart';

import '../helpers/root_cause_memory.dart';
import '../helpers/user_facing_error.dart';
import 'product_chrome.dart';

/// Display-only reminder of a prior Fixed root cause. Does not skip evidence.
class PriorRootCauseHintCard extends StatelessWidget {
  const PriorRootCauseHintCard({
    required this.hint,
    super.key,
  });

  final PriorRootCauseHint hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UserFacingCopy.priorRootCauseHintTitle,
            style: text.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            UserFacingCopy.priorRootCauseHintBody,
            key: const Key('prior-root-cause-hint-body'),
            style: text.bodySmall,
          ),
          if (hint.immediateCause.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              hint.immediateCause,
              key: const Key('prior-root-cause-hint-immediate'),
              style: text.bodyMedium,
            ),
          ],
          if (hint.rootCause != null) ...[
            const SizedBox(height: 6),
            Text(
              hint.rootCause!,
              key: const Key('prior-root-cause-hint-root'),
              style: text.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
