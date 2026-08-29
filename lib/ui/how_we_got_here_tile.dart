import 'package:flutter/material.dart';

import '../helpers/session_timeline.dart';
import 'evidence_photo_thumb.dart';
import 'product_chrome.dart';

/// Expandable path recap. Collapsed by default. Display only.
class HowWeGotHereTile extends StatelessWidget {
  const HowWeGotHereTile({
    required this.observations,
    this.leaderWhy,
    super.key,
  });

  final List<SessionTimelineObservation> observations;
  final String? leaderWhy;

  @override
  Widget build(BuildContext context) {
    final why = leaderWhy?.trim();
    if (observations.isEmpty && (why == null || why.isEmpty)) {
      return const SizedBox.shrink();
    }

    final text = Theme.of(context).textTheme;
    return PaperCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('how-we-got-here-tile'),
        initiallyExpanded: false,
        title: Text(
          'How we got here',
          style: text.titleSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              key: const Key('how-we-got-here-observations'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < observations.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Text(
                    observations[i].answer,
                    key: Key('how-we-got-here-item-$i'),
                    style: text.bodyLarge,
                  ),
                  Text(
                    observations[i].prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                  if (observations[i].localPhotoPath != null &&
                      observations[i].localPhotoPath!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    EvidencePhotoThumb(
                      key: Key('how-we-got-here-photo-$i'),
                      path: observations[i].localPhotoPath!,
                    ),
                  ],
                ],
                if (why != null && why.isNotEmpty) ...[
                  if (observations.isNotEmpty) const SizedBox(height: 14),
                  Text(
                    why,
                    key: const Key('how-we-got-here-leader-why'),
                    style: text.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
