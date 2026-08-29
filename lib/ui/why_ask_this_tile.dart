import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';

/// Collapsed by default. Shows why the current observation splits remaining
/// causes. Display only — not a ranking dump.
class WhyAskThisTile extends StatelessWidget {
  const WhyAskThisTile({
    required this.body,
    super.key,
  });

  final String body;

  @override
  Widget build(BuildContext context) {
    final text = body.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    final style = Theme.of(context).textTheme;
    return ExpansionTile(
      key: const Key('why-ask-this-tile'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        UserFacingCopy.whyAskThis,
        style: style.titleSmall,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            key: const Key('why-ask-this-body'),
            style: style.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
