import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2 relative luminance for sRGB [color].
double relativeLuminance(Color color) {
  double channel(double value) {
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.red / 255.0);
  final g = channel(color.green / 255.0);
  final b = channel(color.blue / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Contrast ratio of two colors (1–21). Order does not matter.
double contrastRatio(Color a, Color b) {
  final l1 = relativeLuminance(a);
  final l2 = relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA normal-text minimum.
const double wcagAaNormalText = 4.5;

/// WCAG AA large text / UI-component minimum.
const double wcagAaLargeOrUi = 3.0;
