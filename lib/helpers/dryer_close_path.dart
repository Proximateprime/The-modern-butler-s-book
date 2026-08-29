import '../models/evidence.dart';
import '../models/inspect_step.dart';
import 'failure_mode_standing.dart';
import 'thermal_reset_scope.dart';
import 'visual_guide.dart';

/// Dedicated verification answer labels for the close path.
const List<String> closeVerificationChoices = [
  'Confirmed',
  'Not confirmed',
  'Could not complete',
];

/// Result of the Primary close-path verification gate.
enum VerificationOutcome {
  /// No primary selected yet.
  notApplicable,

  /// Close-path verification still needs an answer.
  pending,

  /// Verification Confirmed.
  supported,

  /// Verification Not confirmed.
  contradicted,

  /// Could not complete / unsure.
  inconclusive,
}

/// Deterministic close-path content for one dryer failure mode.
///
/// Package-adjacent MVP map: beginner-safe verification and guidance only.
/// No live electrical measurement instructions.
class FailureModeClosePath {
  const FailureModeClosePath({
    required this.failureModeId,
    required this.verificationAsk,
    required this.verificationWhy,
    required this.safeGuidanceSteps,
    required this.allowResolvedWhenConfirmed,
    required this.preferProfessionalWhenNotConfirmed,
    this.visualGuides = const [],
    this.expertOkSteps = const [],
    this.inspectSteps = const [],
  });

  final String failureModeId;
  final String verificationAsk;
  final String verificationWhy;
  final List<String> safeGuidanceSteps;

  /// Extra mechanical steps flagged expert_ok. Hidden unless Expert Mode is on.
  /// Never used for gas, sealed-system, or refrigerant work.
  final List<String> expertOkSteps;

  /// Optional package visual anchors for steps that name a part.
  final List<VisualGuideAnchor> visualGuides;

  /// Ordered inspect overlays for this failure mode (dryer first).
  final List<InspectStep> inspectSteps;

  /// Confirmed means the safe check/fix outcome succeeded → Resolved OK.
  final bool allowResolvedWhenConfirmed;

  /// Not confirmed means beginner-safe steps did not restore function → pro.
  final bool preferProfessionalWhenNotConfirmed;
}

String closeVerificationTemplateId(String failureModeId) =>
    'close-verify-$failureModeId';

/// Dryer, washer, fridge, or dishwasher MVP close-path definitions keyed by
/// failure mode id.
FailureModeClosePath? closePathForFailureMode(String failureModeId) {
  // Built-in reset procedure wins over imported terse boundary copy.
  if (isResettableThermalPath(failureModeId)) {
    return _dryerClosePaths[failureModeId] ??
        _importedClosePaths[failureModeId];
  }
  return _importedClosePaths[failureModeId] ??
      _dryerClosePaths[failureModeId] ??
      _washerClosePaths[failureModeId] ??
      _fridgeClosePaths[failureModeId] ??
      _dishwasherClosePaths[failureModeId];
}

/// Built-in package visual anchors (not factory-imported overlays).
List<VisualGuideAnchor> builtInVisualGuidesFor(String failureModeId) {
  return _dryerClosePaths[failureModeId]?.visualGuides ??
      _washerClosePaths[failureModeId]?.visualGuides ??
      _fridgeClosePaths[failureModeId]?.visualGuides ??
      _dishwasherClosePaths[failureModeId]?.visualGuides ??
      const [];
}

/// Built-in inspect overlays keyed by failure mode.
List<InspectStep> builtInInspectStepsFor(String failureModeId) {
  return _dryerClosePaths[failureModeId]?.inspectSteps ??
      _washerClosePaths[failureModeId]?.inspectSteps ??
      _dishwasherClosePaths[failureModeId]?.inspectSteps ??
      const [];
}

/// Registers or replaces a close path from Knowledge Factory import.
void registerImportedClosePath(FailureModeClosePath path) {
  _importedClosePaths[path.failureModeId] = path;
}

/// Clears factory-imported close paths (tests / re-seed).
void clearImportedClosePaths() {
  _importedClosePaths.clear();
}

final Map<String, FailureModeClosePath> _importedClosePaths = {};

const Map<String, FailureModeClosePath> _dryerClosePaths = {
  'restricted-exhaust-airflow': FailureModeClosePath(
    failureModeId: 'restricted-exhaust-airflow',
    verificationAsk:
        'After cleaning the lint filter and clearing crush/kinks in the '
        'visible vent hose, is exterior vent airflow clearly stronger?',
    verificationWhy:
        'Confirms whether a simple exhaust restriction was limiting drying.',
    safeGuidanceSteps: [
      'Check airflow before opening the cabinet. Pull the lint filter and look '
          'at the screen.',
      'Check airflow before opening the cabinet. Go outside to the vent hood '
          'while the dryer runs.',
      'Check airflow before opening the cabinet. Look behind the dryer at the '
          'visible vent hose for crush, kinks, packed lint, or a long run.',
      'Unplug the dryer (or switch off its breaker) before moving it.',
      'Restore power, run a short heat cycle, and re-check exterior airflow.',
    ],
    visualGuides: [lintFilterGuide, ventHoodGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'clogged-lint-pathway': FailureModeClosePath(
    failureModeId: 'clogged-lint-pathway',
    verificationAsk:
        'After cleaning the lint filter and accessible lint around the filter '
        'slot, do clothes dry more normally on a short test load?',
    verificationWhy:
        'Confirms whether lint restriction near the filter was limiting drying.',
    safeGuidanceSteps: [
      'Unplug the dryer before inspecting the lint housing.',
      'Clean the lint filter and any safely accessible lint around the slot.',
      'Do not dismantle sealed cabinets or wiring.',
      'Restore power and run a small test load on a heat cycle.',
    ],
    visualGuides: [lintFilterGuide, accessPanelGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'thermal-fuse-open': FailureModeClosePath(
    failureModeId: 'thermal-fuse-open',
    verificationAsk:
        'With a heat cycle selected, the drum tumbling, and the lint filter '
        'and visible vent path already cleared, is there still no warmth at '
        'all on a short test run?',
    verificationWhy:
        'A thermal fuse is a one-shot safety device. Clearing the vent '
        'corrects the overheating that opened it, but it cannot restore heat '
        'on its own. Still completely cold after the airflow path is clear '
        'matches an open fuse. Warmth returning after a power-off fuse '
        'replacement and vent follow-up means the repair worked.',
    safeGuidanceSteps: [
      'Check airflow before opening the cabinet. Pull the lint filter and look '
          'at the screen.',
      'Check airflow before opening the cabinet. Go outside to the vent hood '
          'while the dryer runs.',
      'Check airflow before opening the cabinet. Look behind the dryer at the '
          'visible vent hose for crush, kinks, packed lint, or a long run.',
      'Unplug the dryer and turn OFF the dryer circuit breaker at the panel. '
          'Confirm the control panel shows no lights and Start does nothing.',
      'Do not measure live voltage, test the fuse while energized, or bypass '
          'it with foil, wire, or a jumper.',
      'Stop here and call a qualified technician to test and replace the '
          'thermal fuse. Confirming no warmth is not a completed repair.',
      'A new fuse alone without fixing restricted airflow can open again.',
    ],
    expertOkSteps: [
      'With the dryer unplugged and the breaker off, you may open an '
          'accessible heater service panel to locate the thermal fuse.',
      'If you can reach it without live testing, you may replace the fuse '
          'with an exact-match part. Never jumper it. Reassemble before '
          'restoring power.',
    ],
    visualGuides: [accessPanelGuide, lintFilterGuide, ventHoodGuide],
    // restored after a proper fuse swap may allow resolve.
    allowResolvedWhenConfirmed: false,
    preferProfessionalWhenNotConfirmed: true,
  ),
  accessibleThermalResetModeId: FailureModeClosePath(
    failureModeId: accessibleThermalResetModeId,
    verificationAsk:
        'After a cooldown or a user-accessible reset, and after clearing the '
        'lint filter and visible vent path, does warmth return on a short '
        'heat cycle?',
    verificationWhy:
        'A resettable cutoff or motor protector can restore heat after it '
        'cools or after you press a visible reset. Clearing the vent is the '
        'root-cause fix so it does not trip again. This is not a fuse swap '
        'behind panels.',
    safeGuidanceSteps: [
      'Check airflow before opening the cabinet. Pull the lint filter and look '
          'at the screen.',
      'Check airflow before opening the cabinet. Go outside to the vent hood '
          'while the dryer runs.',
      'Check airflow before opening the cabinet. Look behind the dryer at the '
          'visible vent hose for crush, kinks, packed lint, or a long run.',
      'Unplug the dryer. Let it cool at least 30 minutes. Do not open a heater '
          'panel or probe wiring.',
      'Look only for a user-accessible reset: a button or marked reset on the '
          'back, kick plate, or blower housing you can reach without removing '
          'internal panels or touching terminals. Press it once if you find '
          'one. Skip this if there is no visible reset.',
      'Restore power and run a short heat cycle with a small load. If heat '
          'returns, keep the vent and lint path clear so the protector does '
          'not trip again.',
      'If there is still no warmth, or it trips again quickly on a light load, '
          'stop this home check. Do not jumper the protector. Remaining work '
          'may be a non-resettable fuse or heater service.',
    ],
    visualGuides: [lintFilterGuide, ventHoodGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  motorOverheatProtectorModeId: FailureModeClosePath(
    failureModeId: motorOverheatProtectorModeId,
    verificationAsk:
        'After unplugging and letting the dryer cool at least 30 minutes, and '
        'after cleaning the lint filter, does it start and run a light load '
        'without stopping hot again?',
    verificationWhy:
        'Many dryers use an auto-reset motor protector. Cooldown plus airflow '
        'is the home check. Repeated hot stops or any motor wiring work is '
        'out of beginner scope.',
    safeGuidanceSteps: [
      'Check airflow before opening the cabinet. Pull the lint filter and look '
          'at the screen.',
      'Check airflow before opening the cabinet. Go outside to the vent hood '
          'while the dryer runs.',
      'Check airflow before opening the cabinet. Look behind the dryer at the '
          'visible vent hose for crush, kinks, packed lint, or a long run.',
      'Unplug the dryer and let it cool at least 30 minutes. Do not bypass a '
          'protector or test motor windings live.',
      'Restore power and try a light load. If it runs, keep lint and vent '
          'paths clear so the protector does not trip again.',
      'If it stops hot again on a light load, stop this home check. Do not '
          'jumper the protector.',
    ],
    visualGuides: [lintFilterGuide, ventHoodGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'heating-element-failed': FailureModeClosePath(
    failureModeId: 'heating-element-failed',
    verificationAsk:
        'With a heat cycle selected, the wall plug fully seated, and the drum '
        'turning, does a short run still produce no warmth?',
    verificationWhy:
        'Confirms beginner-safe setting and plug checks before escalating '
        'heater-circuit work. Element replacement and live probing are out of '
        'beginner scope.',
    safeGuidanceSteps: [
      'Check airflow before opening the cabinet. Pull the lint filter and look '
          'at the screen.',
      'Check airflow before opening the cabinet. Go outside to the vent hood '
          'while the dryer runs.',
      'Check airflow before opening the cabinet. Look behind the dryer at the '
          'visible vent hose for crush, kinks, packed lint, or a long run.',
      'Do not probe live heater terminals or bypass safety devices.',
      'Confirm a heat cycle is selected and the drum turns.',
      'Confirm the wall plug is fully seated and undamaged, from the outside '
          'only.',
      'Restore power and run a short heat test with a small load.',
      'If clothes stay cold / no warmth returns, call a qualified technician '
          'for heating-element service.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'electric-supply-connection-fault': FailureModeClosePath(
    failureModeId: 'electric-supply-connection-fault',
    verificationAsk:
        'After confirming the wall plug is fully seated, does the dryer now '
        'produce heat while tumbling?',
    verificationWhy:
        'Checks only a safe external connection outcome — no live metering.',
    safeGuidanceSteps: [
      'Do not open the supply cord or measure live voltage.',
      'Confirm the plug is fully seated in the receptacle.',
      'If the dryer tumbles without heat, stop and call a professional.',
      'High-voltage dryer supply work is not a beginner DIY task.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'broken-drive-belt': FailureModeClosePath(
    failureModeId: 'broken-drive-belt',
    verificationAsk:
        'With power disconnected for inspection: does a broken or slipped belt '
        'match a motor that runs while the drum stays still?',
    verificationWhy:
        'Confirms the classic broken-belt pattern using sound/motion and safe '
        'visual access only.',
    safeGuidanceSteps: [
      'Unplug the dryer before moving it or opening access panels.',
      'Do not reach into the drum opening while powered.',
      'If you hear the motor run and the drum does not turn, a broken belt is '
          'the usual cause.',
      'Belt replacement behind panels is optional DIY only if you are '
          'comfortable; otherwise call a technician.',
    ],
    expertOkSteps: [
      'With the dryer unplugged, you may remove an accessible rear or lower '
          'service panel to inspect the belt path and pulley alignment.',
      'If the belt is off or broken and you can reach it without forcing the '
          'cabinet, you may seat or replace that belt using the model’s '
          'belt-routing diagram.',
      'Do not work on gas connections, sealed cooling systems, or refrigerant.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: false,
  ),
  'worn-drum-rollers': FailureModeClosePath(
    failureModeId: 'worn-drum-rollers',
    verificationAsk:
        'Does the thump or rumble repeat in time with the drum turning on an '
        'empty or light load?',
    verificationWhy:
        'A drum-timed thump points to rollers/supports rather than a start '
        'or no-heat fault.',
    safeGuidanceSteps: [
      'Run briefly with a light load and listen only.',
      'Note whether the thump follows drum rotation.',
      'Unplug before any internal inspection.',
      'Do not oil sealed roller assemblies as a fix. Roller replacement is '
          'typically a technician job.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'idler-pulley-wear': FailureModeClosePath(
    failureModeId: 'idler-pulley-wear',
    verificationAsk:
        'Does a sharp squeal continue while the drum is turning normally?',
    verificationWhy:
        'Confirms a running mechanical squeal rather than a no-start or '
        'no-tumble fault.',
    safeGuidanceSteps: [
      'Start a normal tumble and listen for a sharp squeal.',
      'Confirm the drum is turning.',
      'Unplug before any look at the belt or idler.',
      'Do not spray lubricants into the cabinet as a permanent fix. Idler '
          'and belt service is typically professional.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'door-switch-failure': FailureModeClosePath(
    failureModeId: 'door-switch-failure',
    verificationAsk:
        'After firmly closing the door until it clicks, does the dryer now '
        'start normally when you press Start?',
    verificationWhy:
        'Confirms whether a door interlock / switch issue was blocking start. '
        'Never bypass the door switch.',
    safeGuidanceSteps: [
      'Do not bypass, tape, or defeat the door switch.',
      'Close the door firmly until you feel/hear a solid click.',
      'Confirm nothing is caught in the door seal.',
      'Try Start again. If it still will not start with a firm door close, '
          'call a technician for switch/interlock service.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'motor-failure': FailureModeClosePath(
    failureModeId: 'motor-failure',
    verificationAsk:
        'After confirming the door is closed and the drum is not jammed, does '
        'the dryer still hum or struggle without turning normally?',
    verificationWhy:
        'Re-checks motor-load symptoms without internal electrical probing.',
    safeGuidanceSteps: [
      'Unplug the dryer before inspection.',
      'Do not open motor wiring or test live windings.',
      'Confirm the door is firmly closed and the drum is not jammed by clothing.',
      'If humming/no-turn persists, call a professional for motor service.',
    ],
    allowResolvedWhenConfirmed: false,
    preferProfessionalWhenNotConfirmed: true,
  ),
};

/// Washer primary-path close paths. Beginner-safe only — no sealed system,
/// live electrical, or gas work.
const Map<String, FailureModeClosePath> _washerClosePaths = {
  'clogged-washer-drain-filter': FailureModeClosePath(
    failureModeId: 'clogged-washer-drain-filter',
    verificationAsk:
        'After unplugging and cleaning the accessible drain filter or pump '
        'trap, does the washer drain a short test cycle?',
    verificationWhy:
        'Confirms whether debris in the accessible filter was holding water.',
    safeGuidanceSteps: [
      'Check that the washer door closes firmly until you feel or hear a click. '
          'Do not bypass the door switch.',
      'Look for an accessible drain filter at the front or bottom. Stay outside '
          'a sealed tub or pump.',
      'Unplug the washer (or switch off its breaker) before opening the filter.',
      'Place a shallow pan and towel under the accessible drain filter.',
      'Open only the user-accessible filter or pump trap — do not split a '
          'sealed tub or pump housing.',
      'Remove lint, coins, or debris, then close the filter firmly.',
      'Restore power and run a short drain/spin to confirm water leaves.',
    ],
    visualGuides: [drainFilterGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'kinked-or-clogged-washer-drain-hose': FailureModeClosePath(
    failureModeId: 'kinked-or-clogged-washer-drain-hose',
    verificationAsk:
        'After unkinking the visible drain hose and seating it in the '
        'standpipe, does a short drain empty the drum?',
    verificationWhy:
        'Confirms whether the accessible drain hose was pinched or stuffed too '
        'deep.',
    safeGuidanceSteps: [
      'Look behind the washer at the drain hose and standpipe. Do not open a '
          'sealed tub or pump.',
      'Unplug the washer before pulling it out to free a kink.',
      'Straighten kinks. Pull the hose a little out of the standpipe if it was '
          'stuffed deep. Do not split a sealed pump.',
      'No live electrical testing. Restore power and run a short drain.',
    ],
    visualGuides: [washerDrainHoseGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'closed-taps-or-kinked-inlet': FailureModeClosePath(
    failureModeId: 'closed-taps-or-kinked-inlet',
    verificationAsk:
        'After opening both taps and unkinking the inlet hose, does the '
        'washer start filling on a short test?',
    verificationWhy:
        'Confirms whether supply was simply shut or pinched.',
    safeGuidanceSteps: [
      'Look at both hot and cold taps and the visible inlet hose. Do not open '
          'the cabinet.',
      'Open both hot and cold taps fully.',
      'Unplug the washer before moving it to inspect a hidden kink.',
      'Straighten kinks in the inlet hose. Do not dismantle the inlet valve '
          'or cabinet wiring.',
      'Restore power and start a short wash to watch for fill.',
    ],
    visualGuides: [waterTapsGuide, inletHoseGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'clogged-washer-inlet-screens': FailureModeClosePath(
    failureModeId: 'clogged-washer-inlet-screens',
    verificationAsk:
        'After rinsing the screens at the hose ends and restoring the '
        'couplings, does a short wash fill?',
    verificationWhy:
        'Confirms whether grit at the hose-end screens was starving fill.',
    safeGuidanceSteps: [
      'Look at both taps first. Confirm they are open before disconnecting a '
          'hose.',
      'Unplug the washer and close both taps before loosening a coupling.',
      'Unscrew only the hose at the tap and rinse the small screen in the hose '
          'end. Do not open the inlet valve body or cabinet wiring.',
      'Hand-tighten the coupling, open the taps, restore power, and watch fill. '
          'No live electrical testing.',
    ],
    visualGuides: [inletHoseGuide, waterTapsGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'unbalanced-washer-load': FailureModeClosePath(
    failureModeId: 'unbalanced-washer-load',
    verificationAsk:
        'After redistributing the load evenly, does spin complete without '
        'violent shaking?',
    verificationWhy:
        'Confirms whether a bunched load was stopping spin.',
    safeGuidanceSteps: [
      'Pause and wait for the drum to stop. Do not force the motor.',
      'Redistribute clothes so the drum is balanced.',
      'Do not open a sealed transmission or test live electrical parts.',
      'Restart drain/spin and stay nearby for the first minute.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'loose-inlet-hose': FailureModeClosePath(
    failureModeId: 'loose-inlet-hose',
    verificationAsk:
        'After unplugging and hand-tightening the accessible tap coupling, '
        'does the leak stop on the next fill?',
    verificationWhy:
        'Confirms whether a loose inlet coupling was the drip.',
    safeGuidanceSteps: [
      'Look at the tap coupling for drips. Do not open the cabinet.',
      'Unplug the washer and close the tap before touching the coupling.',
      'Hand-tighten the accessible nut at the tap. Do not open the cabinet '
          'or a sealed valve body.',
      'No live electrical testing.',
      'Open the tap, restore power, and watch the coupling during fill.',
    ],
    visualGuides: [inletHoseGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'washer-drain-hose-not-seated': FailureModeClosePath(
    failureModeId: 'washer-drain-hose-not-seated',
    verificationAsk:
        'After seating the drain hose in the standpipe and clipping it, does '
        'the leak stay gone on the next drain?',
    verificationWhy:
        'Confirms whether the hose had slipped out of the standpipe.',
    safeGuidanceSteps: [
      'Look behind the washer at the standpipe. Do not open a sealed tub.',
      'Unplug before pulling the washer out if you cannot see the hose.',
      'Seat the drain hose in the standpipe and clip it so it cannot slip. Do '
          'not split a sealed pump.',
      'No live electrical testing. Restore power and watch the next drain.',
    ],
    visualGuides: [washerDrainHoseGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'washer-door-not-latched': FailureModeClosePath(
    failureModeId: 'washer-door-not-latched',
    verificationAsk:
        'After closing the door firmly until it clicks, does Start begin a cycle?',
    verificationWhy:
        'Confirms whether the door interlock was simply not latched.',
    safeGuidanceSteps: [
      'Check that the washer door closes firmly until you feel or hear a click. '
          'Do not bypass the door switch.',
      'Remove anything caught in the door seal. Close the door firmly until '
          'you feel or hear a click.',
      'No live electrical testing. Do not tape or defeat the door switch.',
      'Try Start again. If Start begins with a firm latch, you are done; '
          'otherwise call a technician.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'washer-no-power-or-control-lock': FailureModeClosePath(
    failureModeId: 'washer-no-power-or-control-lock',
    verificationAsk:
        'After confirming the plug, breaker, and control lock, does Start '
        'begin a cycle?',
    verificationWhy:
        'Confirms whether the washer simply had no power or a lock was on.',
    safeGuidanceSteps: [
      'Look at the plug in the outlet, the breaker, and any child-lock or '
          'control-lock light. Do not do live electrical testing.',
      'Seat the plug fully. If the breaker is off, switch it on once. Check the '
          'owner book for how to clear control lock.',
      'No live electrical testing. Do not open the control box.',
      'Try Start again. If it stays dark with a firm plug and breaker on, call '
          'a technician.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
};

/// Fridge v1 close paths. Never sealed-system, refrigerant, compressor live
/// diagnostics, or piercing lines.
const Map<String, FailureModeClosePath> _fridgeClosePaths = {
  'blocked-fridge-coils-or-airflow': FailureModeClosePath(
    failureModeId: 'blocked-fridge-coils-or-airflow',
    verificationAsk:
        'After unplugging, cleaning accessible coils or the grille, and '
        'leaving space around the cabinet, is the interior colder after '
        'several hours?',
    verificationWhy:
        'Confirms whether dust or tight clearance was limiting cooling. '
        'Fridge temperature recovers slowly.',
    safeGuidanceSteps: [
      'Look at the interior temperature and the control settings. A mid-range '
          'setpoint is enough for this check.',
      'Look at each door gasket for gaps, tears, or food in the seal. Close '
          'the doors fully.',
      'Look at the internal air vents. Move food so vents are not blocked.',
      'Unplug the fridge (or switch off its breaker) before pulling it out.',
      'Move it only as far as the power cord and water line allow. Do not '
          'kink, cut, or puncture any tubes.',
      'Vacuum dust from the accessible condenser coils or toe-kick grille '
          'only. Do not open the sealed cooling system. Do not add, recover, '
          'or handle refrigerant. No compressor live diagnostics.',
      'Leave a few inches of space behind and above the cabinet for air.',
      'Restore power and wait several hours before judging cooling.',
    ],
    visualGuides: [fridgeCoilsGuide, fridgeDoorGasketGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'blocked-fridge-internal-vents': FailureModeClosePath(
    failureModeId: 'blocked-fridge-internal-vents',
    verificationAsk:
        'After clearing food from the internal vents and closing the doors, '
        'is the fridge side colder after several hours?',
    verificationWhy:
        'Confirms whether blocked vents were starving the fresh-food side of '
        'cold air.',
    safeGuidanceSteps: [
      'Look at the air vents on the back or side walls inside the fridge and '
          'freezer. Move bins and food so the openings are clear.',
      'Look at the fridge door gasket and close the door fully.',
      'Unplug before any coil or compressor work. This path stays inside the '
          'compartments — do not open the sealed cooling system. Do not add, '
          'recover, or handle refrigerant.',
      'Wait several hours with vents clear before judging cooling.',
    ],
    visualGuides: [fridgeInternalVentGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'fridge-door-gasket-or-ajar': FailureModeClosePath(
    failureModeId: 'fridge-door-gasket-or-ajar',
    verificationAsk:
        'After cleaning the gasket, removing anything in the seal, and '
        'closing the door fully, does the door stay shut and is frost at the '
        'opening reduced after several hours?',
    verificationWhy:
        'Confirms whether an ajar door or dirty gasket was letting warm air in.',
    safeGuidanceSteps: [
      'Look at each door gasket for gaps, tears, sticky food, or a door that '
          'pops open. Close until the seal sits flat.',
      'Wipe the gasket with a damp cloth. Remove items that keep the door from '
          'closing. Do not cut or stretch the gasket off its channel unless '
          'it is a user-replaceable snap-in seal and you have the matching part.',
      'Unplug before any coil or compressor work. Stay with the door. Do not '
          'open the sealed cooling system. Do not add, recover, or handle '
          'refrigerant.',
      'Wait several hours. If the door still will not stay closed with a clean '
          'seated gasket, call a technician.',
    ],
    visualGuides: [fridgeDoorGasketGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'fridge-temp-controls-set-wrong': FailureModeClosePath(
    failureModeId: 'fridge-temp-controls-set-wrong',
    verificationAsk:
        'After setting fridge and freezer controls to a normal mid-range, is '
        'food closer to the temperature you want after several hours?',
    verificationWhy:
        'Confirms whether the dials or digital setpoints were simply too warm '
        'or too cold.',
    safeGuidanceSteps: [
      'Look at the fridge and freezer temperature controls. Note whether they '
          'are at an extreme.',
      'Set both to a mid-range from the owner book. Do not open a sealed '
          'control box.',
      'Unplug before any coil or compressor work. This path is settings only. '
          'Do not open the sealed cooling system. Do not add, recover, or '
          'handle refrigerant. No live electrical testing.',
      'Wait several hours before judging. Food temperature changes slowly.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'clogged-fridge-defrost-drain': FailureModeClosePath(
    failureModeId: 'clogged-fridge-defrost-drain',
    verificationAsk:
        'After unplugging and clearing the user-accessible drain or emptying '
        'the drip pan, does new water stop pooling?',
    verificationWhy:
        'Confirms whether a visible drain or pan was overflowing.',
    safeGuidanceSteps: [
      'Look at the visible freezer drain hole, a slide-out drip pan, and where '
          'water is pooling. Do not follow a cut tube.',
      'Unplug the fridge before moving it or touching the drip pan.',
      'Clear only a user-accessible freezer drain hole with warm water if '
          'you can see it. Empty a slide-out drip pan if it comes out without '
          'cutting metal or tubes.',
      'Do not open the sealed cooling system. Do not add, recover, or handle '
          'refrigerant. Do not puncture cooling tubes.',
      'Restore power and watch for new puddles.',
    ],
    visualGuides: [fridgeDripPanGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'ice-maker-supply-or-switch': FailureModeClosePath(
    failureModeId: 'ice-maker-supply-or-switch',
    verificationAsk:
        'After turning the ice maker on and opening the accessible water tap '
        'with the line unkinked, does ice start to form on a later cycle?',
    verificationWhy:
        'Confirms whether the maker was simply off or the supply was shut.',
    safeGuidanceSteps: [
      'Confirm the ice maker switch or arm is in the on / fill position.',
      'Unplug before pulling the fridge out. Open the water tap behind it '
          'and straighten kinks in the accessible water line only.',
      'Do not puncture the water line or any cooling tube. Do not open the '
          'sealed cooling system. Do not add, recover, or handle refrigerant.',
      'Restore power and wait for an ice-maker cycle. Ice is not instant.',
    ],
    visualGuides: [fridgeIceMakerGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'fridge-ice-bin-or-dispenser-jam': FailureModeClosePath(
    failureModeId: 'fridge-ice-bin-or-dispenser-jam',
    verificationAsk:
        'After emptying clumped ice from the user-accessible bin and clearing '
        'the dispenser opening, does ice dispense or the bin fill again?',
    verificationWhy:
        'Confirms whether a jam in the bin was stopping ice.',
    safeGuidanceSteps: [
      'Look in the ice bin and at the dispenser opening for clumped ice. Do '
          'not reach into a running dispenser.',
      'Unplug before pulling the bin if your model requires it. Empty the '
          'user-accessible bin and break up clumps in a bowl — not with tools '
          'against the ice-maker body.',
      'Do not dismantle a sealed ice-maker housing. Do not open the sealed '
          'cooling system. Do not add, recover, or handle refrigerant.',
      'Restore power and wait for a later ice cycle.',
    ],
    visualGuides: [fridgeIceMakerGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'fridge-unlevel-or-vibration': FailureModeClosePath(
    failureModeId: 'fridge-unlevel-or-vibration',
    verificationAsk:
        'After leveling the fridge and padding rattling items, is the noise '
        'clearly quieter?',
    verificationWhy:
        'Confirms whether rocking or loose items were the rattle. Ice '
        'dropping into the bin can be normal.',
    safeGuidanceSteps: [
      'Look whether the cabinet rocks, or bottles and pans rattle against the '
          'wall.',
      'Unplug if you need to roll or lift the fridge to level it.',
      'Level the cabinet so it does not rock. Move bottles and pans so they '
          'do not rattle against the wall or each other.',
      'Ice dropping into the bin can be a normal sound.',
      'Do not open the compressor or sealed cooling system. Do not add, '
          'recover, or handle refrigerant. Call a technician for grinding or '
          'screeching from the machine itself. No compressor live diagnostics.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'fridge-no-power-or-control': FailureModeClosePath(
    failureModeId: 'fridge-no-power-or-control',
    verificationAsk:
        'After seating the plug and confirming the breaker is on, do lights '
        'or the display come back?',
    verificationWhy:
        'Confirms whether the fridge simply had no power.',
    safeGuidanceSteps: [
      'Look at the plug in the outlet and the breaker. Do not do live '
          'electrical testing.',
      'Seat the plug fully. If the breaker is off, switch it on once.',
      'Unplug before any coil or compressor work. Do not test the compressor '
          'while it is live. Do not open the sealed cooling system. Do not '
          'add, recover, or handle refrigerant.',
      'If it stays dark with a firm plug and breaker on, call a technician.',
    ],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
};

/// Dishwasher primary-path close paths. No sealed pump or live electrical work.
const Map<String, FailureModeClosePath> _dishwasherClosePaths = {
  'clogged-dishwasher-filter': FailureModeClosePath(
    failureModeId: 'clogged-dishwasher-filter',
    verificationAsk:
        'After unplugging and cleaning the accessible tub filter, does a short '
        'drain or rinse leave the tub empty?',
    verificationWhy:
        'Confirms whether debris in the user-accessible filter was holding water.',
    safeGuidanceSteps: [
      'Look at the accessible tub filter under the lower rack. Do not open a '
          'sealed pump.',
      'Unplug the dishwasher (or switch off its breaker) before reaching into '
          'the tub.',
      'Remove and rinse only the user-accessible filter at the tub bottom. '
          'Do not open a sealed pump or motor.',
      'No live electrical testing. Do not reach inside while it is running.',
      'Restore power and run a short drain or rinse to see whether standing '
          'water is gone.',
    ],
    visualGuides: [dishwasherTubFilterGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'kinked-or-clogged-dishwasher-drain': FailureModeClosePath(
    failureModeId: 'kinked-or-clogged-dishwasher-drain',
    verificationAsk:
        'After unkinking the visible drain hose and checking the air gap or '
        'disposal inlet, does a short drain empty the tub?',
    verificationWhy:
        'Confirms whether the accessible drain path was pinched or blocked.',
    safeGuidanceSteps: [
      'Look at the visible drain hose, air-gap cap, or disposal inlet under the '
          'sink. Do not open a sealed pump.',
      'Unplug before pulling the dishwasher out to see a hidden hose kink.',
      'Straighten kinks in the visible hose. Check that an air gap cap is '
          'clear, or that a newly installed disposal has its knockout removed.',
      'Do not split a sealed pump housing. No live electrical testing.',
      'Restore power and run a short drain.',
    ],
    visualGuides: [dishwasherDrainHoseGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'closed-dishwasher-supply-or-air-gap': FailureModeClosePath(
    failureModeId: 'closed-dishwasher-supply-or-air-gap',
    verificationAsk:
        'After opening the under-sink supply and clearing the air-gap cap, '
        'does a short cycle start filling?',
    verificationWhy:
        'Confirms whether supply was shut or the air gap was packed.',
    safeGuidanceSteps: [
      'Look under the sink at the dishwasher supply tap and the air-gap cap. '
          'Do not open a sealed pump.',
      'Open the supply tap fully. Lift the air-gap cap and rinse debris if '
          'your sink has one.',
      'Unplug before moving the dishwasher if you cannot see the supply hose.',
      'No live electrical testing. Restore power and start a short fill.',
    ],
    visualGuides: [dishwasherSupplyGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'dishwasher-door-not-latched': FailureModeClosePath(
    failureModeId: 'dishwasher-door-not-latched',
    verificationAsk:
        'After closing the door firmly until it clicks, does Start begin a cycle?',
    verificationWhy:
        'Confirms whether the door interlock was simply not latched.',
    safeGuidanceSteps: [
      'Check that the dishwasher door closes firmly until you feel or hear a '
          'click. Do not bypass the door switch.',
      'Remove anything caught in the door seal. Close the door firmly until '
          'you feel or hear a click.',
      'No live electrical testing. Do not open a sealed control box.',
      'Try Start again. If Start begins with a firm latch, you are done; '
          'otherwise call a technician.',
    ],
    visualGuides: [dishwasherDoorLatchGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'clogged-dishwasher-spray-arms': FailureModeClosePath(
    failureModeId: 'clogged-dishwasher-spray-arms',
    verificationAsk:
        'After cleaning accessible spray-arm holes and the tub filter, and '
        'loading so water can reach the dishes, is a short rinse cleaner?',
    verificationWhy:
        'Confirms whether blocked spray or a packed load was the poor clean.',
    safeGuidanceSteps: [
      'Look at spray-arm holes and the tub filter with the door open. Do not '
          'reach inside while it is running.',
      'Unplug before lifting out spray arms or the filter.',
      'Rinse the accessible filter. Clear visible spray-arm holes with a '
          'toothpick if they are clogged. Do not open a sealed pump.',
      'Load so dishes do not block the arms. No live electrical testing.',
      'Restore power and run a short rinse to check spray.',
    ],
    visualGuides: [dishwasherSprayArmGuide, dishwasherTubFilterGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
  'dishwasher-door-seal-or-loose-connection': FailureModeClosePath(
    failureModeId: 'dishwasher-door-seal-or-loose-connection',
    verificationAsk:
        'After clearing the door seal and hand-checking the visible sink hose, '
        'does the leak stay gone on a short cycle?',
    verificationWhy:
        'Confirms whether a dirty seal or a loose visible connection was the drip.',
    safeGuidanceSteps: [
      'Look at the door seal and, if you can see it, the hose under the sink. '
          'Do not open a sealed tub.',
      'Wipe food out of the door seal. Close the door firmly until it clicks.',
      'Unplug before pulling the unit if you need to see a hidden coupling.',
      'Hand-check a visible hose nut under the sink. Do not split a sealed '
          'pump. No live electrical testing.',
      'Restore power and run a short cycle while you watch the door and sink.',
    ],
    visualGuides: [dishwasherDoorLatchGuide, dishwasherDrainHoseGuide],
    allowResolvedWhenConfirmed: true,
    preferProfessionalWhenNotConfirmed: true,
  ),
};

/// Maps a close-path verification answer to [VerificationOutcome].
VerificationOutcome verificationOutcomeFromCloseAnswer(String? answer) {
  final key = normalizeObservationAnswer(answer);
  return switch (key) {
    'Confirmed' => VerificationOutcome.supported,
    'Not confirmed' => VerificationOutcome.contradicted,
    'Could not complete' => VerificationOutcome.inconclusive,
    'Not sure' => VerificationOutcome.inconclusive,
    _ => VerificationOutcome.inconclusive,
  };
}

/// Finds a recorded close-verification answer for [failureModeId], if any.
Evidence? findCloseVerificationEvidence({
  required List<Evidence> evidence,
  required String failureModeId,
}) {
  final templateId = closeVerificationTemplateId(failureModeId);
  for (final item in evidence.reversed) {
    if (item.templateId == templateId) {
      return item;
    }
  }
  return null;
}

/// Crisp End Session eligibility after Primary + verification.
enum CloseResolveEligibility {
  /// Still need a close verification answer.
  pendingVerification,

  /// DIY-safe confirmation — Resolved is allowed.
  allowResolved,

  /// Safe steps did not restore function / repair exceeds beginner scope.
  needsProfessional,

  /// Inconclusive / weak / user stopping — Unresolved (and professional) only.
  unresolvedOnly,

  /// Safety hard-stop.
  safetyStop,
}

CloseResolveEligibility closeResolveEligibility({
  required bool safetyStopActive,
  required String? primaryFailureModeId,
  required VerificationOutcome verificationOutcome,
  FailureModeClosePath? closePath,
}) {
  if (safetyStopActive) {
    return CloseResolveEligibility.safetyStop;
  }
  if (primaryFailureModeId == null) {
    return CloseResolveEligibility.unresolvedOnly;
  }
  if (verificationOutcome == VerificationOutcome.pending ||
      verificationOutcome == VerificationOutcome.notApplicable) {
    return CloseResolveEligibility.pendingVerification;
  }
  if (verificationOutcome == VerificationOutcome.inconclusive) {
    return CloseResolveEligibility.unresolvedOnly;
  }

  final path = closePath ?? closePathForFailureMode(primaryFailureModeId);
  if (path == null) {
    return CloseResolveEligibility.unresolvedOnly;
  }

  if (verificationOutcome == VerificationOutcome.supported) {
    if (path.allowResolvedWhenConfirmed) {
      return CloseResolveEligibility.allowResolved;
    }
    return CloseResolveEligibility.needsProfessional;
  }

  // Not confirmed.
  if (path.preferProfessionalWhenNotConfirmed) {
    return CloseResolveEligibility.needsProfessional;
  }
  return CloseResolveEligibility.unresolvedOnly;
}
