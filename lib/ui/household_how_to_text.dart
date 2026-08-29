import 'package:flutter/material.dart';

import '../helpers/forbidden_guidance.dart';

/// Paints a household how-to line only after the Safety Validator.
///
/// Forbidden instructions are not shown. "Do not" / "never" lines stay.
class HouseholdHowToText extends StatelessWidget {
  const HouseholdHowToText({
    super.key,
    required this.text,
    required this.expertMode,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final bool expertMode;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final shown = visibleHouseholdHowTo(text, expertMode: expertMode);
    if (shown.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      shown,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
