import 'easy_airflow_checks.dart';
import 'forbidden_guidance.dart';

/// Structured user-facing guidance for a check or safe step.
class GuidanceDisplayBlock {
  const GuidanceDisplayBlock({
    required this.what,
    required this.how,
    required this.resultMeans,
    required this.whenToStop,
  });

  final String what;
  final String how;
  final String resultMeans;
  final String whenToStop;
}

const _defaultWhenToStop =
    'Stop and call a professional if you notice smoke, a sharp burning-plastic '
    'or electrical smell, sparking, melting, or anything that feels unsafe.';

/// Plain-language HOW for observation prompts.
GuidanceDisplayBlock? observationGuidanceForTemplate(String templateId) {
  return _observationGuidance[templateId];
}

/// Safety Validator on a display block. Forbidden how-to is emptied so
/// the UI must not paint it. Prohibition lines stay.
GuidanceDisplayBlock? visibleGuidanceDisplayBlock(
  GuidanceDisplayBlock? block, {
  required bool expertMode,
}) {
  if (block == null) {
    return null;
  }
  return GuidanceDisplayBlock(
    what: visibleHouseholdHowTo(block.what, expertMode: expertMode),
    how: visibleHouseholdHowTo(block.how, expertMode: expertMode),
    resultMeans: visibleHouseholdHowTo(
      block.resultMeans,
      expertMode: expertMode,
    ),
    whenToStop: visibleHouseholdHowTo(
      block.whenToStop,
      expertMode: expertMode,
    ),
  );
}

/// Enriches close-path / safe-guidance steps for display.
GuidanceDisplayBlock guidanceForSafeStep(String step) {
  final trimmed = step.trim();
  if (trimmed.isEmpty) {
    return const GuidanceDisplayBlock(
      what: 'Safety check',
      how: 'Follow the step carefully.',
      resultMeans: 'This helps confirm whether the safe check succeeded.',
      whenToStop: _defaultWhenToStop,
    );
  }

  final lower = trimmed.toLowerCase();
  final easyAirflow = isEasyAirflowCheckStep(trimmed);
  for (final entry in _safeStepGuidance.entries) {
    if (easyAirflow && _teardownGuidanceKeys.contains(entry.key)) {
      continue;
    }
    if (lower.contains(entry.key)) {
      return GuidanceDisplayBlock(
        what: entry.value.what,
        how: trimmed,
        resultMeans: entry.value.resultMeans,
        whenToStop: entry.value.whenToStop,
      );
    }
  }
  final isEscalation = lower.contains('call a') ||
      lower.contains('technician') ||
      lower.contains('professional');
  final isProhibition = lower.contains('do not') ||
      lower.contains('never') ||
      lower.contains('avoid ');

  final whenToStop = isEscalation ||
          isProhibition ||
          lower.contains('stop') ||
          lower.contains('unplug')
      ? trimmed
      : _defaultWhenToStop;

  return GuidanceDisplayBlock(
    what: isEscalation
        ? 'When to hand this to a professional'
        : isProhibition
            ? 'Safety limit for this check'
            : _summarizeStep(trimmed),
    how: trimmed,
    resultMeans: isEscalation
        ? 'This part of the repair needs tools, disassembly, or testing '
            'that are outside beginner scope.'
        : isProhibition
            ? 'Following this keeps the check inside beginner-safe limits.'
            : 'Completing this step shows whether this cause matches what you '
                'are seeing.',
    whenToStop: whenToStop,
  );
}

/// Short imperative title taken from the step's own leading clause, so a
/// guidance step never renders placeholder copy.
String _summarizeStep(String step) {
  var head = step;
  for (final separator in const [' — ', '. ', '; ', ', and ']) {
    final index = head.indexOf(separator);
    if (index > 0) {
      head = head.substring(0, index);
    }
  }
  head = head.replaceAll(RegExp(r'[.;:,]+$'), '').trim();
  if (head.isEmpty) {
    return step;
  }
  if (head.length > 72) {
    final cut = head.lastIndexOf(' ', 72);
    head = '${head.substring(0, cut > 24 ? cut : 72).trim()}…';
  }
  return head[0].toUpperCase() + head.substring(1);
}

GuidanceDisplayBlock guidanceForVerification({
  required String ask,
  required String why,
  String? failureModeId,
}) {
  if (failureModeId != null) {
    final specific = _closeVerificationGuidance[failureModeId];
    if (specific != null) {
      return specific;
    }
  }

  return GuidanceDisplayBlock(
    what: 'Complete the safe checks, then record what you observed',
    how: 'Work through each Safe Guidance step below in order. When you are '
        'done, choose Confirmed only if the outcome clearly matches the '
        'verification question above.',
    resultMeans: why,
    whenToStop:
        'Choose Not confirmed or Could not complete rather than guessing. '
        'Stop immediately for smoke, burning smell, or sparking.',
  );
}

const Map<String, GuidanceDisplayBlock> _closeVerificationGuidance = {
  'restricted-exhaust-airflow': GuidanceDisplayBlock(
    what: 'Check whether exterior airflow improved after cleaning',
    how:
        'After cleaning the lint filter and clearing the visible vent path, run '
        'a short heat cycle and feel or listen at the outside vent hood.',
    resultMeans:
        'Stronger airflow supports a simple vent restriction. No change means '
        'escalate rather than keep cleaning blindly.',
    whenToStop:
        'Stop for smoke, burning smell, or a cabinet that feels dangerously hot.',
  ),
  'thermal-fuse-open': GuidanceDisplayBlock(
    what: 'Confirm the load is still completely cold after airflow is clear',
    how:
        'After the lint filter and visible vent path are cleared, run a short heat '
        'cycle with the drum turning. Feel whether the load is still cold throughout. '
        'Do not open the cabinet for this check.',
    resultMeans:
        'Still completely cold matches an open fuse pattern. Warmth returning '
        'after a proper fuse swap and vent check means the repair worked.',
    whenToStop:
        'Do not meter live circuits or jumper the fuse. Stop for smoke or burning smell.',
  ),
  'thermistor-fault-electronic': GuidanceDisplayBlock(
    what:
        'Check whether warmth is partial or extreme rather than completely absent',
    how:
        'On a heat cycle, note whether clothes get some warmth but stay damp, feel '
        'too hot, or vary during the run — versus staying completely cold.',
    resultMeans:
        'Partial warmth, damp clothes, or overheating point toward sensor/control '
        'feedback faults. Completely cold throughout points elsewhere.',
    whenToStop:
        'Do not open the console or probe wiring. Stop for smoke or burning smell.',
  ),
};

const Map<String, GuidanceDisplayBlock> _observationGuidance = {
  'dryer-response': GuidanceDisplayBlock(
    what: 'What the dryer does when you press Start',
    how:
        'Close the door normally, select a regular cycle, and press Start once. '
        'Watch and listen for about 10 seconds.',
    resultMeans:
        'Nothing happens points to power/door/start issues. A hum suggests motor '
        'load trouble. Normal start means we move to heat and drum checks.',
    whenToStop: _defaultWhenToStop,
  ),
  'drum-turns': GuidanceDisplayBlock(
    what: 'Whether the drum is tumbling',
    how:
        'Start a cycle and watch through the closed door glass. Do not open the '
        'door or reach in while it is running. Unplug before any reach-in look.',
    resultMeans:
        'No tumble with motor sound often means a belt issue. Normal tumble with '
        'no heat points toward a heating-path problem.',
    whenToStop:
        'Do not reach into a moving drum. Unplug before reaching in. Stop if you '
        'hear harsh grinding or smell burning.',
  ),
  'heat-observed': GuidanceDisplayBlock(
    what: 'Whether the load is getting warm',
    how:
        'Run the dryer on a heat cycle for 2–3 minutes with a small load. Open '
        'carefully and feel whether clothes or the drum area are warm.',
    resultMeans:
        'No warmth on a heat cycle supports no-heat modes. Warmth with damp '
        'clothes points more toward airflow restriction.',
    whenToStop:
        'Stop for smoke or sharp electrical/burning smells. Do not open live '
        'heater compartments.',
  ),
  'cycle-heat-setting': GuidanceDisplayBlock(
    what: 'Whether a heat cycle is actually selected',
    how:
        'Look at the control panel and confirm the cycle is not Air Fluff, Air '
        'Dry, or another no-heat setting.',
    resultMeans:
        'Air-only/fluff selected explains cold tumbling without a parts failure.',
    whenToStop: _defaultWhenToStop,
  ),
  'panel-lights': GuidanceDisplayBlock(
    what: 'Whether the control panel has power',
    how: 'Press buttons or turn the knob and see whether lights, numbers, or '
        'display segments respond.',
    resultMeans:
        'No lights at all suggests supply/power. Lights on with no start points '
        'toward door or start-control issues.',
    whenToStop:
        'Do not open the console. Stop if the plug, cord, or outlet looks burnt.',
  ),
  'door-closed-firmly': GuidanceDisplayBlock(
    what: 'Whether the door latch clicks shut',
    how:
        'Close the door with normal pressure until you feel or hear a firm click. '
        'Gently pull the handle to see if it stays latched.',
    resultMeans:
        'A soft close or door that will not stay shut supports a door-switch or '
        'latch problem.',
    whenToStop: 'Never bypass the door switch or safety interlock.',
  ),
  'exterior-airflow': GuidanceDisplayBlock(
    what: 'How strong air is at the outside vent',
    how:
        'Check airflow before opening the cabinet. Feel or listen at the hood. '
        'Note whether the flap opens. Stay outside — do not open the dryer '
        'cabinet for this check.',
    resultMeans:
        'Weak or almost no airflow supports vent restriction. Normal airflow argues '
        'against a simple vent blockage.',
    whenToStop:
        'Do not climb on roofs or enter unsafe areas. Stop if the dryer overheats '
        'or smells hot.',
  ),
  'lint-filter-condition': GuidanceDisplayBlock(
    what: 'Condition of the lint filter',
    how:
        'Check airflow before opening the cabinet. Pull out only the removable '
        'screen and look at it. Do not open panels for this check.',
    resultMeans:
        'A heavily clogged or missing filter supports lint-path restriction.',
    whenToStop: 'Do not wash a filter unless your manual says it is washable.',
  ),
  'lint-housing-slot': GuidanceDisplayBlock(
    what: 'Lint packed in the filter slot or housing',
    how: 'Unplug the dryer. Pull the lint filter all the way out and look down '
        'the slot with a flashlight. Note packed lint on the walls — do not '
        'dismantle the cabinet.',
    resultMeans:
        'Packed housing lint supports a clogged lint pathway even when the '
        'screen itself looks clean.',
    whenToStop:
        'Stop if you would need to open sealed panels or wiring. Unplug first.',
  ),
  'noise-timing': GuidanceDisplayBlock(
    what: 'Whether noise follows the drum or starts after warmup',
    how:
        'Run a light or empty tumble and listen. A repeating thump in time with '
        'the drum is different from a sharp squeal that begins after a few '
        'minutes.',
    resultMeans:
        'Drum-timed thump/rumble supports worn rollers. A delayed sharp squeal '
        'supports idler pulley wear.',
    whenToStop: 'Stop for metal-on-metal grinding, smoke, or burning smell.',
  ),
  'heat-before-failure': GuidanceDisplayBlock(
    what: 'Whether heat was present before this complaint',
    how: 'Think back to recent loads on a heat cycle — not air-only / fluff. '
        'Did it heat normally, then go cold after a very hot run or vent issue, '
        'or has this complaint always been cold?',
    resultMeans:
        'Always-cold with no overheat story favors a failed heating element. '
        'Heat that vanished after overheating or a clogged vent favors an open '
        'thermal fuse. Do not test live heater wiring.',
    whenToStop:
        'Do not meter live circuits or bypass a thermal fuse. Stop for smoke '
        'or burning smell.',
  ),
  'door-held-closed-start': GuidanceDisplayBlock(
    what: 'Whether Start works only while holding the door closed',
    how: 'Close the door and hold it firmly shut with your hand. Press Start. '
        'Do not tape, jumper, or defeat the door switch.',
    resultMeans:
        'Starting only while you hold the door closed supports a door switch '
        'or strike problem. Starting normally without holding argues against it.',
    whenToStop: 'Never bypass the door switch or safety interlock.',
  ),
  'vent-hose-condition': GuidanceDisplayBlock(
    what: 'Whether the visible vent hose is restricted',
    how: 'Check airflow before opening the cabinet. Unplug if you need to roll '
        'the dryer. Check the visible hose only. Do not open the cabinet for '
        'this check.',
    resultMeans:
        'A crushed or packed hose supports restricted exhaust airflow.',
    whenToStop:
        'Unplug before moving the dryer. Do not puncture or dismantle hidden vent '
        'runs inside walls.',
  ),
  'wall-plug-seated': GuidanceDisplayBlock(
    what: 'Whether the wall plug is fully seated',
    how:
        'With dry hands, look at the plug and outlet from the outside only. Confirm '
        'the plug is pushed fully in and the cord looks undamaged.',
    resultMeans:
        'A loose or damaged plug supports a supply-connection issue. A normal '
        'seated plug makes supply less likely.',
    whenToStop:
        'Do not measure live voltage or open the terminal block. Stop for hot '
        'plugs, discolored outlets, or burning smell.',
  ),
  'motor-audible': GuidanceDisplayBlock(
    what: 'What the motor sounds like when trying to start',
    how:
        'Press Start and listen for about 10 seconds. Note clear running sound, '
        'hum/struggle only, or silence.',
    resultMeans:
        'Clear motor sound with a still drum supports a belt issue. Hum/struggle '
        'supports motor load failure.',
    whenToStop:
        'Do not keep hammering Start if the motor only hums and smells hot.',
  ),
  'running-noise': GuidanceDisplayBlock(
    what: 'Unusual sounds while the dryer runs',
    how:
        'Run a normal tumble cycle and listen for squeal, thump, grind, or hum.',
    resultMeans:
        'Squeal often points to idler/belt path wear. Thump suggests drum supports. '
        'Grind may mean blower or mechanical damage.',
    whenToStop: 'Stop for metal-on-metal grinding, smoke, or burning smell.',
  ),
  'hazard-observation': GuidanceDisplayBlock(
    what: 'Immediate hazard signs',
    how:
        'Stop using the dryer. Note whether you smell burning, see smoke, or hear '
        'sparking.',
    resultMeans:
        'Any yes answer is a hard stop — do not continue DIY diagnosis.',
    whenToStop:
        'Unplug or switch off the breaker immediately. Do not restart to test.',
  ),
  'breaker-tripped-check': GuidanceDisplayBlock(
    what: 'Whether the dryer breaker is tripped',
    how:
        'Locate the dryer circuit breaker in the home panel. Look at the handle '
        'only. Do not remove the panel cover. Note if the handle is in the '
        'middle/off position or clearly tripped.',
    resultMeans:
        'A tripped breaker supports supply interruption. Both poles on supports a '
        'different cause than a missing 240V leg.',
    whenToStop:
        'Look at the breaker handle only. Do not remove the electrical-panel cover. '
        'Call a professional for panel work, warm breakers, or burning smell.',
  ),
  'gas-dryer-type': GuidanceDisplayBlock(
    what: 'Whether this is a gas or electric dryer',
    how:
        'Look at the power cord, the rating plate, or the manual. Electric dryers '
        'use a thick 240V cord. If you are not sure, choose Not sure. Do not '
        'inspect, trace, or work on gas lines.',
    resultMeans:
        'Gas dryers with no heat need a different path than electric no-heat '
        'checks. Gas ignition work is not beginner DIY.',
    whenToStop: _defaultWhenToStop,
  ),
  'gas-ignition-observed': GuidanceDisplayBlock(
    what: 'Whether the gas burner ignites on a heat cycle',
    how:
        'On a heat cycle with the drum turning, stay outside the cabinet and feel '
        'whether the load or exhaust air warms within a few minutes. Do not open '
        'the burner compartment or gas lines, and do not look for a flame inside.',
    resultMeans:
        'No flame on a gas heat cycle supports professional gas ignition service — '
        'not DIY repair.',
    whenToStop:
        'If you smell gas, stop use, ventilate, leave the area, and follow gas '
        'emergency procedures. Never attempt gas ignition repair yourself.',
  ),
  'outlet-power-check': GuidanceDisplayBlock(
    what: 'Whether the outlet appears to have power',
    how:
        'With dry hands, check whether another known-good device works in the same '
        'outlet, or whether the dryer panel shows any lights when plugged in.',
    resultMeans:
        'A dead outlet supports supply faults. Power at the outlet with no heat '
        'points elsewhere.',
    whenToStop:
        'Do not measure live voltage. Stop for hot outlets, discolored plugs, or '
        'burning smell.',
  ),
  'control-lock-status': GuidanceDisplayBlock(
    what: 'Whether a control or child lock is engaged',
    how:
        'Look for a lock icon on the panel. Hold the lock button per your manual for '
        '3–5 seconds to release, then try Start again.',
    resultMeans:
        'An engaged lock explains a dryer that will not respond to Start.',
    whenToStop: _defaultWhenToStop,
  ),
  'heat-pattern': GuidanceDisplayBlock(
    what: 'How the load feels after a heat cycle',
    how: 'Run the dryer on a heat cycle for a few minutes with a typical load. '
        'Open carefully and note whether clothes are cold, partly warm but damp, '
        'overhot, or normally warm and drying.',
    resultMeans:
        'No heat points toward heating-path faults. Partly warm but damp points '
        'toward airflow restriction. Too hot points toward overheat protection. '
        'Normal warmth argues against those paths.',
    whenToStop:
        'Stop for smoke, burning smell, or a cabinet that feels dangerously hot.',
  ),
  'door-latch-intermittent': GuidanceDisplayBlock(
    what: 'Whether the door latch is intermittent',
    how:
        'Close the door several times with normal pressure. Note whether the click '
        'and Start response are consistent or sometimes fail.',
    resultMeans:
        'Intermittent latch failure supports a worn latch or switch path.',
    whenToStop: 'Never bypass the door safety interlock.',
  ),
  'motor-overheat-cooldown': GuidanceDisplayBlock(
    what: 'Whether the dryer stops mid-cycle and restarts after cooling',
    how:
        'Note if the dryer runs then stops on its own, and whether it will start '
        'again after 30–60 minutes of rest.',
    resultMeans:
        'Stop-then-restart-after-cooldown supports motor thermal protection.',
    whenToStop:
        'Do not repeatedly hammer Start on a hot motor. Stop for burning smell or '
        'smoke.',
  ),
  'belt-slip-observation': GuidanceDisplayBlock(
    what: 'Whether the drum slips or turns slowly',
    how:
        'Start a cycle and watch the drum. Note if it turns slowly, slips under load, '
        'or smells like burning rubber.',
    resultMeans:
        'Slipping with motor sound supports a worn belt rather than a fully broken one.',
    whenToStop: 'Stop for burning rubber smell or smoke.',
  ),
  'duct-run-length': GuidanceDisplayBlock(
    what: 'Whether the vent run is unusually long or complex',
    how:
        'Estimate the visible vent path from the dryer to the exterior hood. Note if '
        'it is a long run, has many elbows, or uses crushed flexible duct.',
    resultMeans:
        'Excessive length or crush supports slow-dry airflow restriction.',
    whenToStop: 'Do not cut into walls to inspect hidden duct.',
  ),
  'moisture-sensor-bars': GuidanceDisplayBlock(
    what: 'Condition of moisture sensor bars',
    how:
        'Open the drum and look for metal bars inside the drum (often near the filter '
        'area). Wipe them with a soft cloth dampened with rubbing alcohol if coated.',
    resultMeans:
        'Contaminated bars can cause early cycle termination on auto-dry.',
    whenToStop: _defaultWhenToStop,
  ),
  'vent-pest-blockage': GuidanceDisplayBlock(
    what: 'Whether the exterior vent is blocked by pests or debris',
    how:
        'At the exterior hood, look for nests, lint plugs, or debris blocking the '
        'flap. Clear only what you can reach safely from the ground.',
    resultMeans:
        'A blocked hood supports restricted exhaust even when the interior hose looks fine.',
    whenToStop: 'Do not enter unsafe roof or crawl areas.',
  ),
  'cabinet-seal-gap': GuidanceDisplayBlock(
    what: 'Whether the door or cabinet seal leaks air',
    how:
        'With the dryer running, feel around the door gasket and cabinet edges for '
        'unexpected hot air escaping.',
    resultMeans:
        'Air leaks reduce effective exhaust and can mimic vent restriction.',
    whenToStop: _defaultWhenToStop,
  ),
  'timer-heat-portion': GuidanceDisplayBlock(
    what: 'Whether the timer advances through a heat portion',
    how:
        'On a timed heat cycle, watch whether the timer moves and whether warmth '
        'occurs during the expected heat segment.',
    resultMeans:
        'Timer advancing with no heat segment supports timer or heat-path control faults.',
    whenToStop: _defaultWhenToStop,
  ),
  'relay-heat-output': GuidanceDisplayBlock(
    what: 'Whether heat output responds when the cycle calls for heat',
    how:
        'On a heat cycle, listen for relay clicks and feel for warmth during the heat '
        'portion. Do not open control compartments.',
    resultMeans:
        'No heat with an active panel and heat cycle can support relay/control output faults.',
    whenToStop:
        'Do not open live control compartments. Stop for burning electrical smell.',
  ),
  'load-size-wetness': GuidanceDisplayBlock(
    what: 'Load size and wetness compared with normal',
    how:
        'Compare the current load to a typical load. Note if it is very large, soaking '
        'wet, or mixed heavy/light items.',
    resultMeans:
        'Oversized or very wet loads extend dry time without a parts failure.',
    whenToStop: _defaultWhenToStop,
  ),
  'clothes-feel-after-cycle': GuidanceDisplayBlock(
    what: 'How clothes felt when you took them out',
    how:
        'Think back to when you took the clothes out — not the instant the cycle ended. '
        'Were they cold and damp, warm but damp, dry but unusually hot, or dry and normal?',
    resultMeans:
        'Cold and damp supports no-heat paths. Warm but damp supports airflow restriction. '
        'Dry but unusually hot supports ongoing excess heat.',
    whenToStop: _defaultWhenToStop,
  ),
  'clothes-remain-damp': GuidanceDisplayBlock(
    what: 'Whether clothes remain damp after the cycle',
    how:
        'When you took clothes out after a typical cycle, note whether items were still '
        'damp. You do not need to open the dryer the instant the cycle ends.',
    resultMeans:
        'Persistent dampness supports airflow or heat problems depending on warmth.',
    whenToStop: _defaultWhenToStop,
  ),
  'dry-time-change': GuidanceDisplayBlock(
    what: 'Whether dry times have changed recently',
    how:
        'Compare a typical load today with what you expect. Note if cycles run much '
        'longer or only slightly longer than before.',
    resultMeans:
        'Much longer dry times support restricted airflow. Slight changes may fit load '
        'or sensor issues.',
    whenToStop: _defaultWhenToStop,
  ),
  'recent-overheat': GuidanceDisplayBlock(
    what: 'Whether the dryer recently ran very hot or shut off from heat',
    how: 'Recall the last few runs. Did the cabinet feel unusually hot, or did '
        'the cycle stop early because of heat?',
    resultMeans:
        'A recent overheat episode supports thermal fuse or high-limit paths. '
        'Answering no only weakens an overheat-then-no-heat fuse story; it does not '
        'by itself confirm a failed heating element.',
    whenToStop: 'Stop for active smoke or burning smell.',
  ),
};

// Insertion order is match order: the most specific keys must come first.
const Set<String> _teardownGuidanceKeys = {
  'thermal fuse',
  'exact-match part',
  'heater service panel',
  'high-limit',
};

final Map<String, GuidanceDisplayBlock> _safeStepGuidance = {
  'qualified technician': GuidanceDisplayBlock(
    what: 'Hand off to a qualified technician',
    how: 'Book professional service rather than continuing. Describe the '
        'symptoms and the safe checks you already completed.',
    resultMeans:
        'A technician needs meter readings or cabinet work. That is outside '
        'beginner steps.',
    whenToStop:
        'Do not continue past this point yourself, and do not run the dryer '
        'again if it overheated.',
  ),
  'thermal fuse': GuidanceDisplayBlock(
    what: 'Replace the thermal fuse with power fully off',
    how:
        'Unplug and turn off the breaker. Open the heater service panel (front '
        'lower or rear on many models — check your manual). Swap the fuse for an '
        'exact-match part. Never jumper or test it live.',
    resultMeans:
        'A one-shot fuse opened because the dryer overheated. Replacing it '
        'without fixing restricted airflow can open again.',
    whenToStop:
        'Do not meter live circuits or bypass the fuse. Stop for smoke or burning smell.',
  ),
  'exact-match part': GuidanceDisplayBlock(
    what: 'Use the correct replacement fuse for your model',
    how:
        'Match the part number or take the old fuse to a parts counter. Install '
        'only with power fully isolated.',
    resultMeans:
        'Wrong parts or bypassing protection can cause fire risk or repeat failure.',
    whenToStop:
        'Do not substitute foil or wire. Stop for smoke or burning smell.',
  ),
  'heater service panel': GuidanceDisplayBlock(
    what: 'Open the correct service panel for heater access',
    how: 'With power off, remove the front lower panel or rear panel per your '
        'model label or manual — screw locations vary by brand.',
    resultMeans:
        'Access exposes the heater housing and fuse but still requires power to stay off.',
    whenToStop:
        'Do not open panels with power on. Stop for smoke or burning smell.',
  ),
  'high-limit': GuidanceDisplayBlock(
    what: 'Never bypass high-limit protection',
    how: 'Leave the high-limit thermostat in place. Correct the airflow cause '
        'and let a technician service the protection itself.',
    resultMeans:
        'High-limit protection is the last defence against an overheating '
        'dryer.',
    whenToStop:
        'Thermostat replacement and heater-housing work are technician tasks.',
  ),
  'set to heat': GuidanceDisplayBlock(
    what: 'Confirm a heat cycle is selected',
    how: 'Look at the control panel and make sure the cycle is not Air Fluff, '
        'Air Dry, or another no-heat setting.',
    resultMeans:
        'Air-only settings tumble without heat, which looks exactly like a '
        'heating fault.',
    whenToStop: _defaultWhenToStop,
  ),
  'short heat cycle': GuidanceDisplayBlock(
    what: 'Run a short heat test cycle',
    how: 'Restore power, start a few minutes on a heat cycle with the drum '
        'turning, then carefully feel whether the load is warm.',
    resultMeans:
        'Warmth returning points to the airflow path. Still completely cold '
        'points to an interrupted heater circuit.',
    whenToStop:
        'Stop the cycle immediately for smoke, a burning smell, or sparking.',
  ),
  'vent path': GuidanceDisplayBlock(
    what: 'Clear the lint and vent path',
    how:
        'Clean the lint filter and clear crush, kinks, or packed lint from the '
        'vent path you can reach safely.',
    resultMeans:
        'This corrects the overheating cause. On a fuse or high-limit path it '
        'does not restore heat by itself.',
    whenToStop:
        'Unplug before moving the dryer. Do not dismantle vent runs inside '
        'walls.',
  ),
  'vent restrictions': GuidanceDisplayBlock(
    what: 'Clear the lint and vent path',
    how:
        'Clean the lint filter and clear crush, kinks, or packed lint from the '
        'vent path you can reach safely.',
    resultMeans:
        'This corrects the overheating cause. On a fuse or high-limit path it '
        'does not restore heat by itself.',
    whenToStop:
        'Unplug before moving the dryer. Do not dismantle vent runs inside '
        'walls.',
  ),
  'vent hose': GuidanceDisplayBlock(
    what: 'Check the visible vent hose',
    how: 'Check airflow before opening the cabinet. Unplug if you need to roll '
        'the dryer. Check the visible hose only.',
    resultMeans:
        'A crushed or packed hose supports restricted exhaust airflow.',
    whenToStop:
        'Unplug before moving the dryer. Do not puncture or dismantle hidden '
        'vent runs.',
  ),
  'lint filter': GuidanceDisplayBlock(
    what: 'Check the lint filter',
    how:
        'Check airflow before opening the cabinet. Pull out only the removable '
        'screen. Do not open panels for this check.',
    resultMeans:
        'Better airflow after cleaning supports a lint-restriction cause.',
    whenToStop: _defaultWhenToStop,
  ),
  'unplug': GuidanceDisplayBlock(
    what: 'Disconnect power before touching the dryer',
    how:
        'Unplug the dryer from the wall or switch off its dedicated breaker before '
        'moving it or opening access panels.',
    resultMeans: 'Power is off so you can inspect safely without live parts.',
    whenToStop: 'Never work on a plugged-in dryer beyond normal button use.',
  ),
  'do not measure live': GuidanceDisplayBlock(
    what: 'No live electrical testing',
    how: 'Use only external observations — settings, sounds, warmth, and plug '
        'condition. Do not probe terminals or heaters with tools.',
    resultMeans:
        'You avoid high-voltage shock risk while still gathering useful clues.',
    whenToStop:
        'If the problem requires meter readings or wiring checks, call a '
        'professional.',
  ),
  'vent hood': GuidanceDisplayBlock(
    what: 'Check the outside vent hood',
    how:
        'Check airflow before opening the cabinet. Stay outside. Feel or listen '
        'for air and whether the flap opens.',
    resultMeans:
        'A free-opening hood with strong airflow supports good exhaust.',
    whenToStop: 'Do not enter unsafe roof or crawl areas.',
  ),
  'gas ignition': GuidanceDisplayBlock(
    what: 'No DIY gas ignition repair',
    how:
        'External gas supply valve and cycle checks only. Do not disassemble gas lines, '
        'burners, igniters, or valves.',
    resultMeans: 'Gas ignition faults require a qualified gas technician.',
    whenToStop:
        'If gas odor is present, stop use, ventilate, and follow gas emergency procedures.',
  ),
  'gas technician': GuidanceDisplayBlock(
    what: 'Call a qualified gas technician',
    how:
        'Do not attempt gas valve, igniter, burner, or flame-sensor repair. Schedule '
        'professional gas appliance service.',
    resultMeans: 'Gas heat restoration is not a beginner DIY task.',
    whenToStop:
        'Any gas odor — stop use, ventilate, evacuate if needed, follow gas emergency procedures.',
  ),
  'capacitor': GuidanceDisplayBlock(
    what: 'No live motor or capacitor work',
    how:
        'Listen for hum/struggle at Start only. Do not open the motor compartment or '
        'test capacitors.',
    resultMeans: 'Start assist faults require professional motor service.',
    whenToStop:
        'Stop for burning smell, smoke, or repeated failed start attempts.',
  ),
};
