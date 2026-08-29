import 'package:flutter/material.dart';

import '../helpers/parts_cost.dart';
import '../helpers/user_facing_error.dart';

/// Optional parts/cost stubs for the ranking leader. Estimates only — no pay.
class PartsCostCard extends StatelessWidget {
  const PartsCostCard({
    required this.parts,
    this.onIllRepair,
    this.onCallPro,
    this.diyOutOfScope = false,
    super.key,
  });

  final List<PartCostEstimate> parts;
  final VoidCallback? onIllRepair;
  final VoidCallback? onCallPro;

  /// Pro-only path: show the pro estimate only, and no "I'll repair".
  final bool diyOutOfScope;

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final showIllRepair = onIllRepair != null && !diyOutOfScope;
    return Card(
      key: const Key('parts-cost-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Parts & cost', style: text.titleSmall),
            const SizedBox(height: 6),
            Text(
              UserFacingCopy.partsCostEstimatesOnly,
              key: const Key('parts-cost-estimates-only'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (diyOutOfScope) ...[
              const SizedBox(height: 8),
              Text(
                partsCostProOnlyNote,
                key: const Key('parts-cost-pro-only-note'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 14),
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _PartCostRow(
                part: parts[i],
                index: i,
                diyOutOfScope: diyOutOfScope,
              ),
            ],
            if (showIllRepair || onCallPro != null) ...[
              const SizedBox(height: 16),
              if (showIllRepair)
                FilledButton(
                  key: const Key('parts-cost-ill-repair'),
                  onPressed: onIllRepair,
                  child: const Text("I'll repair"),
                ),
              if (showIllRepair && onCallPro != null)
                const SizedBox(height: 8),
              if (onCallPro != null)
                FilledButton.tonal(
                  key: const Key('parts-cost-call-pro'),
                  onPressed: onCallPro,
                  child: const Text('Call a pro'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartCostRow extends StatelessWidget {
  const _PartCostRow({
    required this.part,
    required this.index,
    required this.diyOutOfScope,
  });

  final PartCostEstimate part;
  final int index;
  final bool diyOutOfScope;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pro = part.proEstimate.isEmpty ? '—' : part.proEstimate;
    return Column(
      key: Key('parts-cost-row-$index'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(part.name, style: text.titleMedium),
        const SizedBox(height: 2),
        Text(
          diyOutOfScope
              ? 'Pro ~ $pro'
              : 'DIY ~ ${part.diyEstimate.isEmpty ? '—' : part.diyEstimate}'
                  '   ·   Pro ~ $pro',
          style: text.bodyMedium,
        ),
      ],
    );
  }
}
