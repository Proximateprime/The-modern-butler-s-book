import 'package:flutter/material.dart';

import '../helpers/impact_tracker.dart';
import '../helpers/user_facing_error.dart';
import 'product_chrome.dart';

/// Home card for Fixed-repair counts and optional estimated savings.
class HouseholdImpactCard extends StatelessWidget {
  const HouseholdImpactCard({required this.impact, super.key});

  final HouseholdImpact impact;

  @override
  Widget build(BuildContext context) {
    if (impact.isEmpty) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return PaperCard(
      child: Column(
        key: const Key('home-impact-card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(UserFacingCopy.impactTitle, style: text.titleSmall),
          const SizedBox(height: 6),
          Text(
            UserFacingCopy.impactEstimatesLabel,
            key: const Key('home-impact-estimates-label'),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _ImpactRow(
            key: const Key('home-impact-repairs'),
            label: UserFacingCopy.impactRepairsLabel,
            value: '${impact.repairsLogged}',
          ),
          const SizedBox(height: 8),
          _ImpactRow(
            key: const Key('home-impact-appliances'),
            label: UserFacingCopy.impactAppliancesLabel,
            value: '${impact.appliancesKeptInService}',
          ),
          if (impact.estimatedSavingsUsd != null) ...[
            const SizedBox(height: 8),
            _ImpactRow(
              key: const Key('home-impact-savings'),
              label: UserFacingCopy.impactSavingsLabel,
              value:
                  '${formatImpactUsd(impact.estimatedSavingsUsd!)} (estimate)',
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyMedium)),
        Text(value, style: text.titleSmall),
      ],
    );
  }
}
