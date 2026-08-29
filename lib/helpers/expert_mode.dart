import 'dryer_close_path.dart';
import 'forbidden_guidance.dart';

export 'forbidden_guidance.dart'
    show
        isAlwaysForbiddenInstruction,
        isBeginnerBlockedElectricalService,
        isSafetyLimitLanguage,
        sanitizeGuidanceSteps,
        shouldHideGuidanceStep,
        visibleHouseholdHowTo;

/// Extra mechanical steps flagged `expert_ok` in the package. Never gas,
/// sealed-system, refrigerant, live metering, or safety-bypass how-to —
/// even when Expert Mode is on.
List<String> visibleSafeGuidanceSteps(
  FailureModeClosePath path, {
  required bool expertMode,
}) {
  final combined = expertMode
      ? [...path.safeGuidanceSteps, ...path.expertOkSteps]
      : path.safeGuidanceSteps;
  return sanitizeGuidanceSteps(combined, expertMode: expertMode);
}

/// Blocks expert extras that instruct forbidden work.
/// Explicit "do not" / "never" safety lines are kept.
bool isBlockedExpertInstruction(String step) {
  return isAlwaysForbiddenInstruction(step);
}

class SplitGuidanceSteps {
  const SplitGuidanceSteps({
    this.beginner = const [],
    this.expertOk = const [],
  });

  final List<String> beginner;
  final List<String> expertOk;
}

/// Parses package guidance: plain strings stay beginner; maps with
/// `expert_ok` / `expertOk` are Expert Mode extras.
SplitGuidanceSteps splitGuidanceSteps(
  dynamic boundary, {
  dynamic expertOkSteps,
}) {
  final beginner = <String>[];
  final expertOk = <String>[];
  _collectSteps(boundary, beginner: beginner, expertOk: expertOk);
  _collectSteps(
    expertOkSteps,
    beginner: beginner,
    expertOk: expertOk,
    forceExpert: true,
  );
  return SplitGuidanceSteps(
    beginner: List<String>.unmodifiable(beginner),
    expertOk: List<String>.unmodifiable(expertOk),
  );
}

void _collectSteps(
  dynamic raw, {
  required List<String> beginner,
  required List<String> expertOk,
  bool forceExpert = false,
}) {
  if (raw is! List) {
    return;
  }
  for (final item in raw) {
    if (item is String) {
      final text = item.trim();
      if (text.isEmpty) {
        continue;
      }
      if (forceExpert) {
        expertOk.add(text);
      } else {
        beginner.add(text);
      }
      continue;
    }
    if (item is! Map) {
      continue;
    }
    final map = Map<String, dynamic>.from(item);
    final text =
        (map['text'] ?? map['step'] ?? map['how'] ?? '').toString().trim();
    if (text.isEmpty) {
      continue;
    }
    final flagged =
        map['expert_ok'] == true ||
        map['expertOk'] == true ||
        forceExpert;
    if (flagged) {
      expertOk.add(text);
    } else {
      beginner.add(text);
    }
  }
}
