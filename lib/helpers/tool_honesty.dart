import 'close_path_phase.dart';
import 'forbidden_guidance.dart';
import 'repair_readiness.dart';

/// Tools that imply panel-off / cabinet work when the user says they have them.
const Set<String> panelOffToolIds = {
  'screwdriver',
  'nut-driver',
  'pliers',
};

/// Session answers that mean the household cannot do a class of work.
class ToolHonestyCapabilities {
  const ToolHonestyCapabilities({
    this.recordedNoTools = false,
    this.declinedPanelOff = false,
    this.declinedMeter = false,
  });

  /// Every checklist row was marked I don’t.
  final bool recordedNoTools;

  /// No tools, or they marked I don’t on a panel-class tool.
  final bool declinedPanelOff;

  /// No tools, or they marked I don’t on a meter / live-electrical tool.
  final bool declinedMeter;

  bool get blocksPanelOff => recordedNoTools || declinedPanelOff;

  bool get blocksMeter => recordedNoTools || declinedMeter;
}

/// Reads checklist marks only — never Groq, ranking, or Expert Mode.
///
/// Unmarked rows are not a decline. Empty checklists are not “no tools.”
ToolHonestyCapabilities toolHonestyFromChecklist({
  required List<RepairReadinessItem> items,
  required Map<String, bool> haveByToolId,
}) {
  if (items.isEmpty) {
    return const ToolHonestyCapabilities();
  }
  final recordedNoTools =
      toolsChecklistComplete(items: items, haveByToolId: haveByToolId) &&
      items.every((item) => haveByToolId[item.id] == false);
  var declinedPanelOff = recordedNoTools;
  var declinedMeter = recordedNoTools;
  for (final item in items) {
    if (haveByToolId[item.id] != false) {
      continue;
    }
    if (toolItemRequiresPanelOff(item)) {
      declinedPanelOff = true;
    }
    if (toolItemRequiresMeter(item)) {
      declinedMeter = true;
    }
  }
  return ToolHonestyCapabilities(
    recordedNoTools: recordedNoTools,
    declinedPanelOff: declinedPanelOff,
    declinedMeter: declinedMeter,
  );
}

/// Unplug / never / do not lines are limits, not a panel-off how-to.
bool isUnplugOrSafetyLimitGuidanceStep(String step) {
  final lower = step.toLowerCase();
  if (isSafetyLimitLanguage(step)) {
    return true;
  }
  if (lower.contains('do not') ||
      lower.contains('never ') ||
      lower.contains('stop if') ||
      lower.contains('stop here') ||
      lower.contains('before opening')) {
    return true;
  }
  if (lower.contains('unplug') && !lower.contains('you may')) {
    return true;
  }
  return false;
}

/// Instructs opening or removing a service / heater / access panel.
bool isPanelOffWorkStep(String step) {
  if (isUnplugOrSafetyLimitGuidanceStep(step)) {
    return false;
  }
  final lower = step.toLowerCase();
  if (lower.contains('technician') ||
      lower.contains('professional') ||
      lower.contains('call a')) {
    return false;
  }
  if (lower.contains('you may open') ||
      lower.contains('you may remove') ||
      lower.contains('heater service') ||
      lower.contains('service panel') ||
      lower.contains('access panel') ||
      lower.contains('kick plate')) {
    return true;
  }
  if ((lower.contains('open') || lower.contains('remove')) &&
      (lower.contains('panel') || lower.contains('cabinet'))) {
    return true;
  }
  return false;
}

/// Instructs metering / live measurement (not a “do not meter” limit).
bool isMeterWorkStep(String step) {
  if (isUnplugOrSafetyLimitGuidanceStep(step)) {
    return false;
  }
  final lower = step.toLowerCase();
  if (lower.contains('technician') || lower.contains('professional')) {
    return false;
  }
  return lower.contains('multimeter') ||
      lower.contains('voltmeter') ||
      lower.contains('ohm') ||
      (lower.contains('meter') &&
          (lower.contains('live') ||
              lower.contains('measure') ||
              lower.contains('test the') ||
              lower.contains('reading')));
}

bool toolHonestyBlocksStep(
  String step, {
  required ToolHonestyCapabilities capabilities,
}) {
  if (isUnplugOrSafetyLimitGuidanceStep(step)) {
    return false;
  }
  if (capabilities.blocksMeter && isMeterWorkStep(step)) {
    return true;
  }
  if (capabilities.blocksPanelOff && isPanelOffWorkStep(step)) {
    return true;
  }
  if (capabilities.blocksPanelOff && isInvasiveGuidanceStep(step)) {
    return true;
  }
  return false;
}

/// Package tag wins. Id / live-electrical heuristics are fallback only.
bool toolItemRequiresPanelOff(RepairReadinessItem item) {
  if (item.requiresPanelOff != null) {
    return item.requiresPanelOff!;
  }
  return panelOffToolIds.contains(item.id);
}

/// Package tag wins. Live-electrical / meter ids are fallback only.
bool toolItemRequiresMeter(RepairReadinessItem item) {
  if (item.requiresMeter != null) {
    return item.requiresMeter!;
  }
  return item.liveElectrical ||
      item.id == 'multimeter' ||
      item.id == 'voltage-tester';
}

/// Authored steps existed, but honesty / missing-required left none to show.
///
/// That empty list is stop / Call a pro — not verification.
bool guidanceEmptyBecauseHonesty({
  required List<String> authoredSteps,
  required List<RepairReadinessItem> items,
  required Map<String, bool> haveByToolId,
  required bool continueWithCaution,
}) {
  if (authoredSteps.isEmpty) {
    return false;
  }
  final honest = guidanceStepsForToolHonesty(
    steps: authoredSteps,
    items: items,
    haveByToolId: haveByToolId,
    continueWithCaution: continueWithCaution,
  );
  if (honest.isNotEmpty) {
    return false;
  }
  final capabilities = toolHonestyFromChecklist(
    items: items,
    haveByToolId: haveByToolId,
  );
  if (capabilities.recordedNoTools ||
      capabilities.blocksPanelOff ||
      capabilities.blocksMeter) {
    return true;
  }
  final missing = missingRequiredTools(
    items: items,
    haveByToolId: haveByToolId,
  );
  return missing.isNotEmpty;
}

/// Required-tool gate first, then honesty on declined / no-tools answers.
///
/// Does not invent replacement how-to. Empty means stop or hand off.
List<String> guidanceStepsForToolHonesty({
  required List<String> steps,
  required List<RepairReadinessItem> items,
  required Map<String, bool> haveByToolId,
  required bool continueWithCaution,
}) {
  final missing = missingRequiredTools(
    items: items,
    haveByToolId: haveByToolId,
  );
  final afterRequired = guidanceStepsForToolsGate(
    steps: steps,
    missingRequiredTool: missing.isNotEmpty,
    continueWithCaution: continueWithCaution,
  );
  final capabilities = toolHonestyFromChecklist(
    items: items,
    haveByToolId: haveByToolId,
  );
  return [
    for (final step in afterRequired)
      if (!toolHonestyBlocksStep(step, capabilities: capabilities)) step,
  ];
}
