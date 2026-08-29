import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import '../helpers/warranty_hint.dart';
import '../models/appliance.dart';
import 'product_chrome.dart';

/// Hint only. Does not determine warranty status.
class WarrantyHintCard extends StatelessWidget {
  const WarrantyHintCard({required this.appliance, super.key});

  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    if (!shouldShowWarrantyHint(appliance)) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return PaperCard(
      child: Text(
        UserFacingCopy.warrantyHint,
        key: const Key('warranty-hint'),
        style: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
