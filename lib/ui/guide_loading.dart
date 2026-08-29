import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';

/// Consistent on-device guide load indicator. No network.
class GuideLoadingIndicator extends StatelessWidget {
  const GuideLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('guide-loading-indicator'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(height: 16),
        Text(
          UserFacingCopy.guideLoading,
          key: const Key('guide-loading-copy'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
