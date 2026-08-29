import 'dart:io';

import 'package:flutter/material.dart';

/// Local thumbnail. Does not upload or send the image for diagnosis.
class EvidencePhotoThumb extends StatelessWidget {
  const EvidencePhotoThumb({
    required this.path,
    super.key,
  });

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 56,
            height: 56,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.photo_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}
