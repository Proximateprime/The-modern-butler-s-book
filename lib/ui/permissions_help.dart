import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import 'product_chrome.dart';

/// Explains optional camera/mic uses. Diagnosis stays local and deterministic.
class PermissionsHelpCard extends StatelessWidget {
  const PermissionsHelpCard({
    super.key,
    this.compact = false,
    this.includeDeniedPath = true,
  });

  final bool compact;
  final bool includeDeniedPath;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaperCard(
      padding: compact
          ? const EdgeInsets.all(14)
          : const EdgeInsets.all(18),
      child: Column(
        key: const Key('permissions-help-card'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UserFacingCopy.permissionsCameraMicWhy,
            key: const Key('permissions-help-why'),
            style: text.bodyMedium?.copyWith(height: 1.45),
          ),
          if (includeDeniedPath) ...[
            const SizedBox(height: 12),
            Text(
              UserFacingCopy.permissionsDeniedManual,
              key: const Key('permissions-help-denied'),
              style: text.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}
