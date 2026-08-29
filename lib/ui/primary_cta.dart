import 'package:flutter/material.dart';

/// Screen-reader names for the four primary session CTAs.
abstract final class PrimaryCtaSemantics {
  static const start = 'Start';
  static const continueAction = 'Continue';
  static const fixed = 'Fixed';
  static const back = 'Back';
}

enum PrimaryCtaStyle { filled, outlined, tonal, text }

/// Primary action that keeps a stable semantic name and wraps at large text.
class PrimaryCta extends StatelessWidget {
  const PrimaryCta({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.style = PrimaryCtaStyle.filled,
    this.icon,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final PrimaryCtaStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      softWrap: true,
      maxLines: 3,
      overflow: TextOverflow.fade,
    );
    final Widget button;
    switch (style) {
      case PrimaryCtaStyle.filled:
        button = icon == null
            ? FilledButton(onPressed: onPressed, child: text)
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: text,
              );
      case PrimaryCtaStyle.outlined:
        button = icon == null
            ? OutlinedButton(onPressed: onPressed, child: text)
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: text,
              );
      case PrimaryCtaStyle.tonal:
        button = icon == null
            ? FilledButton.tonal(onPressed: onPressed, child: text)
            : FilledButton.tonal(
                onPressed: onPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    text,
                  ],
                ),
              );
      case PrimaryCtaStyle.text:
        button = icon == null
            ? TextButton(onPressed: onPressed, child: text)
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: text,
              );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: button,
    );
  }
}
