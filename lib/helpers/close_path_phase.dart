import '../models/session_objective.dart';
import 'repair_readiness.dart';

/// Stepped close-path stages. Presentation only — not ranking or safety.
enum ClosePathPhase {
  conclusion,
  decision,
  parts,
  tools,
  inspect,
  guidance,
  verification,
  opportunistic,
  done,
}

ClosePathPhase closePathPhaseFromName(String? raw) {
  for (final value in ClosePathPhase.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return ClosePathPhase.conclusion;
}

/// Stable id for a guidance step so resume can skip completed ones.
String guidanceStepId(int index, String step) {
  final slug = step.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final clipped = slug.length > 48 ? slug.substring(0, 48) : slug;
  return '$index:$clipped';
}

int firstIncompleteGuidanceIndex({
  required List<String> steps,
  required Iterable<String> completedIds,
}) {
  final done = completedIds.toSet();
  for (var i = 0; i < steps.length; i++) {
    if (!done.contains(guidanceStepId(i, steps[i]))) {
      return i;
    }
  }
  return steps.isEmpty ? 0 : steps.length;
}

/// Whether I'll repair has already been chosen (parts/tools/guidance onward).
bool closePathImpliesRepairChosen(ClosePathPhase phase) {
  return phase != ClosePathPhase.conclusion &&
      phase != ClosePathPhase.decision;
}

/// Tools rows are marked and missing required tools are not blocking.
bool toolsChecklistReadyForGuidance({
  required List<RepairReadinessItem> items,
  required Map<String, bool> haveByToolId,
  required bool continueWithCaution,
}) {
  if (items.isEmpty) {
    return true;
  }
  if (!toolsChecklistComplete(items: items, haveByToolId: haveByToolId)) {
    return false;
  }
  final missing = missingRequiredTools(
    items: items,
    haveByToolId: haveByToolId,
  );
  return missing.isEmpty || continueWithCaution;
}

/// Where Continue repair should land. See docs/qa/RESUME_CASES.md.
///
/// Mid-guidance stays on guidance (caller snaps to the first incomplete
/// step). Tools finished with no I did this opens the first guidance step.
/// Conclusion / I'll repair not chosen stays there — never skip to tools
/// or guidance just because the checklist could be filled from inventory.
ClosePathPhase resumeClosePathPhase({
  required ClosePathPhase stored,
  required List<String> completedIds,
  bool choseRepair = false,
  bool toolsChecklistComplete = false,
  bool hasIncompleteInspect = false,
  bool inspectReviewOnly = false,
}) {
  if (inspectReviewOnly && stored == ClosePathPhase.inspect) {
    return ClosePathPhase.inspect;
  }
  if (stored == ClosePathPhase.inspect && !choseRepair) {
    return ClosePathPhase.inspect;
  }
  if (stored == ClosePathPhase.inspect) {
    return hasIncompleteInspect
        ? ClosePathPhase.inspect
        : ClosePathPhase.guidance;
  }
  if (hasIncompleteInspect &&
      (stored == ClosePathPhase.guidance ||
          stored == ClosePathPhase.verification ||
          stored == ClosePathPhase.opportunistic ||
          (stored == ClosePathPhase.tools && toolsChecklistComplete) ||
          completedIds.isNotEmpty)) {
    return ClosePathPhase.inspect;
  }
  if (stored == ClosePathPhase.guidance ||
      stored == ClosePathPhase.verification ||
      stored == ClosePathPhase.opportunistic ||
      stored == ClosePathPhase.done) {
    return stored;
  }
  if (completedIds.isNotEmpty) {
    return ClosePathPhase.guidance;
  }
  if (stored == ClosePathPhase.tools && toolsChecklistComplete) {
    return ClosePathPhase.guidance;
  }
  if (!choseRepair &&
      !closePathImpliesRepairChosen(stored) &&
      (stored == ClosePathPhase.conclusion ||
          stored == ClosePathPhase.decision)) {
    return stored;
  }
  return stored;
}

/// Panel / parts / fuse-replacement steps that a missing required tool blocks.
bool isInvasiveGuidanceStep(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('do not') ||
      lower.contains('never ') ||
      lower.contains('stop if') ||
      lower.contains('before opening the cabinet')) {
    return false;
  }
  if (lower.contains('service panel') ||
      lower.contains('heater service') ||
      lower.contains('access panel') ||
      lower.contains('kick plate')) {
    return true;
  }
  if (lower.contains('open the') && lower.contains('panel')) {
    return true;
  }
  if (lower.contains('reassemble')) {
    return true;
  }
  if (lower.contains('user-accessible filter') ||
      lower.contains('shallow pan') ||
      lower.contains('remove lint, coins') ||
      lower.contains('close the filter firmly')) {
    return true;
  }
  if (lower.contains('replace') &&
      (lower.contains('fuse') ||
          lower.contains('element') ||
          lower.contains('belt') ||
          lower.contains('part'))) {
    return true;
  }
  if (lower.contains('cabinet') &&
      (lower.contains('open') || lower.contains('remove'))) {
    return true;
  }
  return false;
}

/// Steps the user may see after answering the tools checklist.
List<String> guidanceStepsForToolsGate({
  required List<String> steps,
  required bool missingRequiredTool,
  required bool continueWithCaution,
}) {
  if (!missingRequiredTool) {
    return List<String>.from(steps);
  }
  if (!continueWithCaution) {
    return const [];
  }
  return [
    for (final step in steps)
      if (!isInvasiveGuidanceStep(step)) step,
  ];
}

bool closePathShowsDecision(SessionObjective? objective) {
  return objective != SessionObjective.figureOutWhatsWrong;
}

bool closePathShowsParts({
  required SessionObjective? objective,
  required bool hasParts,
}) {
  return hasParts && showPartsCostOnClosePath(objective);
}

ClosePathPhase phaseAfterConclusion({
  required SessionObjective? objective,
  required bool hasParts,
  required bool hasTools,
  bool hasIncompleteInspect = false,
}) {
  if (closePathShowsDecision(objective)) {
    return ClosePathPhase.decision;
  }
  return phaseAfterRepairChoice(
    objective: objective,
    hasParts: hasParts,
    hasTools: hasTools,
    hasIncompleteInspect: hasIncompleteInspect,
  );
}

ClosePathPhase phaseAfterRepairChoice({
  required SessionObjective? objective,
  required bool hasParts,
  required bool hasTools,
  bool hasIncompleteInspect = false,
}) {
  if (closePathShowsParts(objective: objective, hasParts: hasParts)) {
    return ClosePathPhase.parts;
  }
  if (hasIncompleteInspect) {
    return ClosePathPhase.inspect;
  }
  if (hasTools) {
    return ClosePathPhase.tools;
  }
  return ClosePathPhase.guidance;
}

ClosePathPhase phaseAfterInspect({
  required SessionObjective? objective,
  required bool hasTools,
  required bool choseRepair,
}) {
  if (closePathShowsDecision(objective) && !choseRepair) {
    return ClosePathPhase.decision;
  }
  if (hasTools) {
    return ClosePathPhase.tools;
  }
  return ClosePathPhase.guidance;
}

ClosePathPhase phaseAfterParts({
  required bool hasTools,
  bool hasIncompleteInspect = false,
}) {
  if (hasIncompleteInspect) {
    return ClosePathPhase.inspect;
  }
  if (hasTools) {
    return ClosePathPhase.tools;
  }
  return ClosePathPhase.guidance;
}

bool toolsChecklistComplete({
  required List<RepairReadinessItem> items,
  required Map<String, bool> haveByToolId,
}) {
  return items.every((item) => haveByToolId.containsKey(item.id));
}

List<RepairReadinessItem> missingRequiredTools({
  required List<RepairReadinessItem> items,
  required Map<String, bool> haveByToolId,
}) {
  return [
    for (final item in items)
      if (item.isCritical && haveByToolId[item.id] == false) item,
  ];
}
