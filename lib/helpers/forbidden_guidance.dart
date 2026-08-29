/// Detects instructions that must never be shown as a how-to, including
/// Expert Mode extras. Prohibition lines ("do not", "never") stay visible.
library;

bool isSafetyLimitLanguage(String step) {
  final lower = step.toLowerCase();
  return lower.contains('do not') ||
      lower.contains("don't ") ||
      lower.contains('never ') ||
      lower.startsWith('never') ||
      lower.contains('not a diy') ||
      lower.contains('without any bypass') ||
      lower.contains('rather than');
}

/// Gas / sealed-system / refrigerant DIY, live metering, or defeating safeties.
/// External look-only checks (open household gas shutoff, breaker glance) are
/// allowed unless they tell the user to service the appliance.
bool isAlwaysForbiddenInstruction(String step) {
  if (isSafetyLimitLanguage(step)) {
    return false;
  }
  final lower = step.toLowerCase();

  if (_instructsRefrigerantOrSealedSystem(lower)) {
    return true;
  }
  if (_instructsGasRepair(lower)) {
    return true;
  }
  if (_instructsLiveElectrical(lower)) {
    return true;
  }
  if (_instructsSafetyBypass(lower)) {
    return true;
  }
  return false;
}

/// Heater-circuit panel / fuse swap is Expert Mode only (skill gate exists).
bool isBeginnerBlockedElectricalService(String step) {
  if (isSafetyLimitLanguage(step)) {
    return false;
  }
  if (isAlwaysForbiddenInstruction(step)) {
    return true;
  }
  final lower = step.toLowerCase();
  if (lower.contains('technician') ||
      lower.contains('professional') ||
      lower.contains('call a')) {
    return false;
  }
  if (lower.contains('heater service panel') ||
      (lower.contains('open') &&
          lower.contains('heater') &&
          lower.contains('housing'))) {
    return true;
  }
  if (lower.contains('thermal fuse') &&
      (lower.contains('replace') || lower.contains('locate'))) {
    return true;
  }
  if (lower.contains('reassemble the panel')) {
    return true;
  }
  return false;
}

bool shouldHideGuidanceStep(String step, {required bool expertMode}) {
  if (isAlwaysForbiddenInstruction(step)) {
    return true;
  }
  if (!expertMode && isBeginnerBlockedElectricalService(step)) {
    return true;
  }
  return false;
}

List<String> sanitizeGuidanceSteps(
  Iterable<String> steps, {
  required bool expertMode,
}) {
  return [
    for (final step in steps)
      if (!shouldHideGuidanceStep(step, expertMode: expertMode)) step,
  ];
}

bool _instructsRefrigerantOrSealedSystem(String lower) {
  if (lower.contains('refrigerant') &&
      (lower.contains('add') ||
          lower.contains('recover') ||
          lower.contains('handle') ||
          lower.contains('charge') ||
          lower.contains('recharge'))) {
    return true;
  }
  if ((lower.contains('sealed system') || lower.contains('sealed-system')) &&
      (lower.contains('pierce') ||
          lower.contains('open') ||
          lower.contains('cut') ||
          lower.contains('repair'))) {
    return true;
  }
  if (lower.contains('pierce') &&
      (lower.contains('line') || lower.contains('tube'))) {
    return true;
  }
  return false;
}

bool _instructsGasRepair(String lower) {
  if (lower.contains('external gas supply') ||
      lower.contains('household gas supply') ||
      lower.contains('gas supply valve is fully open') ||
      lower.contains('cycle setting checks only')) {
    return false;
  }
  final serviceVerb =
      lower.contains('replace') ||
      lower.contains('repair') ||
      lower.contains('disassemble') ||
      lower.contains('service') ||
      lower.contains('test the') ||
      lower.contains('adjust');
  if (!serviceVerb) {
    return false;
  }
  return lower.contains('gas valve') ||
      lower.contains('gas line') ||
      lower.contains('gas ignition') ||
      lower.contains('igniter') ||
      lower.contains('burner') ||
      lower.contains('flame sensor') ||
      lower.contains('work on gas');
}

bool _instructsLiveElectrical(String lower) {
  if (lower.contains('multimeter') ||
      lower.contains('voltmeter') ||
      lower.contains('ohm') ||
      lower.contains('continuity')) {
    return true;
  }
  if (lower.contains('energized') &&
      (lower.contains('test') ||
          lower.contains('probe') ||
          lower.contains('measure') ||
          lower.contains('meter'))) {
    return true;
  }
  if ((lower.contains('measure') ||
          lower.contains('meter') ||
          lower.contains('probe')) &&
      (lower.contains('live voltage') ||
          lower.contains('live electrical') ||
          lower.contains('terminal block'))) {
    return true;
  }
  if (lower.contains('test live') || lower.contains('live testing')) {
    return true;
  }
  return false;
}

bool _instructsSafetyBypass(String lower) {
  if (lower.contains('jumper') ||
      (lower.contains('foil') &&
          (lower.contains('fuse') || lower.contains('bypass')))) {
    return true;
  }
  if ((lower.contains('tape') || lower.contains('defeat')) &&
      (lower.contains('door switch') || lower.contains('interlock'))) {
    return true;
  }
  if (lower.contains('bypass') &&
      (lower.contains('door switch') ||
          lower.contains('interlock') ||
          lower.contains('thermal fuse') ||
          lower.contains('thermostat') ||
          lower.contains('high-limit') ||
          lower.contains('high limit') ||
          lower.contains('safety'))) {
    return true;
  }
  return false;
}
