import 'failure_mode_authoring_record.dart';
import 'failure_mode_batch_importer.dart';
import 'dryer_batch_01.dart';
import 'dryer_batch_02.dart';
import 'golden_examples.dart';
import 'washer_mvp_v01.dart';
import 'fridge_mvp_v01.dart';
import 'dishwasher_mvp_v01.dart';
import '../helpers/parts_cost.dart';
import '../helpers/thermal_reset_scope.dart';

/// Read-only authoring depth for a failure mode (root cause, prevention, etc.).
class FailureModeAuthoringSummary {
  const FailureModeAuthoringSummary({
    required this.id,
    required this.title,
    required this.immediateCause,
    required this.rootCause,
    required this.contributingFactors,
    required this.preventionActions,
    this.commonMisdiagnoses = const [],
    this.toolsRequired = const [],
    this.partsEstimates = const [],
    this.safetyNotes = '',
  });

  final String id;
  final String title;
  final String immediateCause;
  final String rootCause;
  final List<String> contributingFactors;
  final List<String> preventionActions;
  final List<String> commonMisdiagnoses;
  final List<String> toolsRequired;
  final List<PartCostEstimate> partsEstimates;
  final String safetyNotes;

  bool get hasRootCauseInsight =>
      rootCause.trim().isNotEmpty ||
      contributingFactors.isNotEmpty ||
      preventionActions.isNotEmpty ||
      commonMisdiagnoses.isNotEmpty;
}

/// Deterministic lookup table built from imported Knowledge Factory records.
class FailureModeAuthoringRegistry {
  FailureModeAuthoringRegistry._();

  static Map<String, FailureModeAuthoringSummary>? _cache;

  static Map<String, FailureModeAuthoringSummary> get _byId {
    if (_cache != null) {
      return _cache!;
    }
    const importer = FailureModeBatchImporter();
    final records = <FailureModeAuthoringRecord>[
      ...importer.parseBatchJson(dryerThermalFuseRestrictedVentGoldenJson),
      ...importer.parseBatchJson(dryerBatch01Json),
      ...importer.parseBatchJson(dryerBatch02Json),
    ];
    _cache = {
      for (final record in records)
        record.id: FailureModeAuthoringSummary(
          id: record.id,
          title: record.title,
          immediateCause: record.immediateCause,
          rootCause: record.rootCause,
          contributingFactors: record.contributingFactors,
          preventionActions: record.preventionActions,
          commonMisdiagnoses: record.commonMisdiagnoses,
          toolsRequired: record.toolsRequired,
          partsEstimates: record.partsEstimates.isNotEmpty
              ? record.partsEstimates
              : partsCostCatalog[record.id] ?? const [],
          safetyNotes: record.safetyNotes,
        ),
      for (final summary in _washerMvpAuthoringSummaries) summary.id: summary,
      for (final summary in _fridgeMvpAuthoringSummaries) summary.id: summary,
      for (final summary in _dishwasherMvpAuthoringSummaries) summary.id: summary,
      accessibleThermalResetModeId: const FailureModeAuthoringSummary(
        id: accessibleThermalResetModeId,
        title: 'Resettable thermal cutoff',
        immediateCause:
            'A user-accessible reset or auto-reset thermal protector opened.',
        rootCause:
            'Restricted airflow or another overheat condition tripped a '
            'resettable cutoff. Clearing the vent is the lasting fix.',
        contributingFactors: [
          'Packed lint filter or housing',
          'Crushed or long vent run',
          'Repeated heat cycles without cooldown',
        ],
        preventionActions: [
          'Clean the lint filter before every load',
          'Keep the exterior vent hood and visible hose clear',
        ],
        toolsRequired: ['None for cooldown, visible reset, and lint checks'],
        safetyNotes:
            'Never jumper a protector. Do not open heater panels or probe '
            'live wiring.',
      ),
    };
    return _cache!;
  }

  static FailureModeAuthoringSummary? lookup(String? failureModeId) {
    if (failureModeId == null || failureModeId.trim().isEmpty) {
      return null;
    }
    return _byId[failureModeId];
  }

  static List<String> toolsRequiredFor(String? failureModeId) {
    return lookup(failureModeId)?.toolsRequired ?? const [];
  }

  static String? safetyNotesFor(String? failureModeId) {
    final notes = lookup(failureModeId)?.safetyNotes.trim();
    if (notes == null || notes.isEmpty) {
      return null;
    }
    return notes;
  }

  /// Package parts/cost stubs for a leader mode. Empty means hide the card.
  static List<PartCostEstimate> partsEstimatesFor(String? failureModeId) {
    final summary = lookup(failureModeId);
    if (summary != null && summary.partsEstimates.isNotEmpty) {
      return summary.partsEstimates;
    }
    if (failureModeId == null || failureModeId.trim().isEmpty) {
      return const [];
    }
    return partsCostCatalog[failureModeId] ?? const [];
  }
}

const List<FailureModeAuthoringSummary> _washerMvpAuthoringSummaries = [
  FailureModeAuthoringSummary(
    id: washerCloggedDrainFilterId,
    title: 'Clogged drain filter or pump trap',
    immediateCause: 'Debris in the accessible drain filter',
    rootCause: 'Lint, coins, or small items blocking the pump trap',
    contributingFactors: ['Skipped filter cleaning', 'Tissues in pockets'],
    preventionActions: [
      'Check pockets before washing',
      'Clean the accessible drain filter about every 30 days',
    ],
    commonMisdiagnoses: [
      'A failed drain pump — often it is only the accessible filter',
      'A lid-switch or control failure — look at the coin trap before a panel',
    ],
    toolsRequired: [
      'Shallow pan and towel for opening the drain filter',
      'Flashlight (optional)',
    ],
    partsEstimates: [
      PartCostEstimate(
        name: 'Drain filter / pump trap',
        diyEstimate: r'$8–25',
        proEstimate: r'$90–180',
      ),
    ],
  ),
  FailureModeAuthoringSummary(
    id: washerClosedTapsId,
    title: 'Closed taps or kinked inlet hose',
    immediateCause: 'No water reaching the inlet',
    rootCause: 'Closed taps or a kinked hose',
    contributingFactors: ['Washer recently moved', 'Shared shutoff closed'],
    preventionActions: [
      'Confirm both taps are open before a wash',
      'Leave a gentle bend in the inlet hose, not a pinch',
    ],
    commonMisdiagnoses: [
      'A failed inlet valve — often a closed tap or a kink',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
  FailureModeAuthoringSummary(
    id: washerDrainHoseId,
    title: 'Kinked or clogged drain hose',
    immediateCause: 'The drain hose was pinched or stuffed too deep',
    rootCause: 'Water could not leave through the accessible drain hose',
    contributingFactors: [
      'Washer recently moved',
      'Hose jammed into the standpipe',
    ],
    preventionActions: [
      'Leave a gentle loop in the drain hose, not a pinch',
      'Do not stuff the hose deep into the standpipe',
    ],
    commonMisdiagnoses: [
      'A failed drain pump — check the hose and filter first',
      'A clogged coin trap assumed without looking at the hose run',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
  FailureModeAuthoringSummary(
    id: washerCloggedInletScreensId,
    title: 'Packed inlet-hose screens',
    immediateCause: 'Grit in the screens at the hose ends',
    rootCause: 'Fill water could not pass the hose-end screens',
    contributingFactors: ['Well water or sediment', 'Screens never rinsed'],
    preventionActions: [
      'Rinse the screens at the hose ends about every 30 days if fill slows',
      'Confirm both taps are open before disconnecting a hose',
    ],
    commonMisdiagnoses: [
      'A failed fill valve — often packed screens at the hose ends',
      'Packed screens assumed while a tap is still closed',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
  FailureModeAuthoringSummary(
    id: washerUnbalancedLoadId,
    title: 'Unbalanced load',
    immediateCause: 'Clothes bunched on one side',
    rootCause: 'Spin protection stopped an unbalanced drum',
    contributingFactors: ['Single heavy item', 'Small load'],
    preventionActions: [
      'Mix large and small items',
      'Redistribute and restart spin rather than forcing the motor',
    ],
    commonMisdiagnoses: [
      'A failed motor or bearing — often a bunched load stopped spin',
      'A failed drain pump — standing water in the drum is a drain path, not a motor teardown',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
  FailureModeAuthoringSummary(
    id: washerLooseInletHoseId,
    title: 'Loose inlet hose at the tap',
    immediateCause: 'Drip at the tap coupling',
    rootCause: 'Hand-tight coupling loosened',
    contributingFactors: ['Recent hose change', 'Vibration'],
    preventionActions: [
      'Hand-tighten the accessible coupling after moving the washer',
      'Check for drips at the tap on the next fill',
    ],
    commonMisdiagnoses: [
      'A cracked tub — often a loose tap coupling',
    ],
    toolsRequired: ['None for beginner external checks'],
    partsEstimates: [
      PartCostEstimate(
        name: 'Inlet hose',
        diyEstimate: r'$15–35',
        proEstimate: r'$80–150',
      ),
    ],
  ),
  FailureModeAuthoringSummary(
    id: washerDoorNotLatchedId,
    title: 'Door not fully latched',
    immediateCause: 'Door interlock not clicked shut',
    rootCause: 'Door not closed firmly, or something in the seal',
    contributingFactors: ['Sock in the seal', 'Soft close'],
    preventionActions: [
      'Close until you feel a click before pressing Start',
      'Keep the door seal clear of small items',
    ],
    commonMisdiagnoses: [
      'A failed control board — often the door is not clicked shut',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
  FailureModeAuthoringSummary(
    id: washerDrainHoseNotSeatedId,
    title: 'Drain hose not seated in the standpipe',
    immediateCause: 'The drain hose slipped out of the standpipe',
    rootCause: 'Drain water poured behind the washer instead of into the pipe',
    contributingFactors: ['Washer pulled out', 'Missing hose clip'],
    preventionActions: [
      'Clip the drain hose so it cannot slip out of the standpipe',
      'Check the standpipe after moving the washer',
    ],
    commonMisdiagnoses: [
      'A leaking tub — often the hose is not in the standpipe',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
  FailureModeAuthoringSummary(
    id: washerNoPowerOrLockId,
    title: 'No power, breaker off, or control lock',
    immediateCause: 'The washer had no power or a lock was on',
    rootCause: 'Unplugged cord, open breaker, or child-lock / control lock',
    contributingFactors: ['Outlet tripped', 'Lock turned on by accident'],
    preventionActions: [
      'Confirm the plug and breaker before calling a technician',
      'Learn where control lock lives in the owner book',
    ],
    commonMisdiagnoses: [
      'A failed control board — often the breaker is off or lock is on',
    ],
    toolsRequired: ['None for beginner external checks'],
  ),
];

const List<FailureModeAuthoringSummary> _fridgeMvpAuthoringSummaries = [
  FailureModeAuthoringSummary(
    id: fridgeBlockedCoilsId,
    title: 'Dirty coils or blocked airflow around the fridge',
    immediateCause: 'Accessible coils or grille were dusty, or the cabinet had no air gap',
    rootCause: 'Heat could not leave the fridge through the condenser path',
    contributingFactors: [
      'Fridge packed tight to the wall',
      'Pet hair or lint on the toe-kick grille',
    ],
    preventionActions: [
      'Vacuum accessible coils or the grille about every 90 days',
      'Leave a few inches of space behind and above the cabinet',
    ],
    commonMisdiagnoses: [
      'A failed compressor — often dirty accessible coils or no air gap',
    ],
    toolsRequired: ['Vacuum for accessible coils (optional)'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeBlockedInternalVentsId,
    title: 'Blocked internal air vents',
    immediateCause: 'Food or bins covered the internal air vents',
    rootCause: 'Cold air could not reach the fresh-food side',
    contributingFactors: ['Overpacked shelves', 'Tall bottles in front of vents'],
    preventionActions: [
      'Keep internal vents visible when you restock',
      'Do not store sheet pans against the back wall vents',
    ],
    commonMisdiagnoses: [
      'A failed damper or sealed-system leak — often food blocking a vent',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeDoorGasketId,
    title: 'Door ajar or worn door seal',
    immediateCause: 'Warm air entered at the door',
    rootCause: 'The door was not closed, or the gasket was dirty, torn, or flat',
    contributingFactors: ['Bins hitting the door', 'Sticky spills on the gasket'],
    preventionActions: [
      'Wipe door gaskets when you clean the interior',
      'Close until the seal sits flat before walking away',
    ],
    commonMisdiagnoses: [
      'A sealed-system failure — often an ajar door or dirty gasket',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeTempControlsId,
    title: 'Temperature controls set too warm or too cold',
    immediateCause: 'The setpoint was at an extreme',
    rootCause: 'A dial or digital control was not at a mid-range setting',
    contributingFactors: ['Someone turned the dial', 'Demo or Sabbath mode'],
    preventionActions: [
      'Keep fridge and freezer at a mid-range from the owner book',
      'Recheck settings after a power outage or move',
    ],
    commonMisdiagnoses: [
      'A failed thermostat — often the control was simply at an extreme',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeCloggedDefrostDrainId,
    title: 'Clogged defrost drain or drip pan',
    immediateCause: 'A user-accessible drain or drip pan was blocked or full',
    rootCause: 'Defrost water could not reach or stay in the pan',
    contributingFactors: ['Food crumbs in the freezer drain', 'Pan not emptied'],
    preventionActions: [
      'Keep the visible freezer drain hole clear of debris',
      'Check a slide-out drip pan if your model has one',
    ],
    commonMisdiagnoses: [
      'A punctured water line — often a full pan or a clogged visible drain',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeIceMakerSupplyId,
    title: 'Ice maker off or water supply closed',
    immediateCause: 'The ice maker was off or the accessible water supply was shut',
    rootCause: 'No water reached the ice maker',
    contributingFactors: ['Fridge recently moved', 'Shared shutoff closed'],
    preventionActions: [
      'Confirm the ice maker is on after a move',
      'Keep the accessible water line unkinked',
    ],
    commonMisdiagnoses: [
      'A failed ice-maker valve — often the switch is off or the tap is closed',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeIceBinJamId,
    title: 'Ice bin jammed or dispenser blocked',
    immediateCause: 'Clumped ice in the bin or a visible dispenser jam',
    rootCause: 'Ice could not leave the user-accessible bin',
    contributingFactors: ['Melt and refreeze', 'Overfilled bin'],
    preventionActions: [
      'Empty the ice bin if cubes fuse into a block',
      'Do not overfill the bin past the fill line',
    ],
    commonMisdiagnoses: [
      'A failed ice maker — often the bin is simply jammed',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeUnlevelVibrationId,
    title: 'Fridge not level or items rattling',
    immediateCause: 'The cabinet rocked or items rattled',
    rootCause: 'Uneven feet or loose items against the wall',
    contributingFactors: ['Floor slope', 'Bottles touching the liner'],
    preventionActions: [
      'Re-check level after moving the fridge',
      'Leave a little space so bottles do not rattle',
    ],
    commonMisdiagnoses: [
      'A failing compressor — often bottles rattling or a rocking cabinet',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: fridgeNoPowerId,
    title: 'No power or display off',
    immediateCause: 'The fridge had no power at the plug or breaker',
    rootCause: 'Unplugged cord or an open breaker',
    contributingFactors: ['Outlet tripped', 'Cord kicked loose'],
    preventionActions: [
      'Confirm the plug and breaker before calling a technician',
      'Keep the cord where it cannot be kicked out',
    ],
    commonMisdiagnoses: [
      'A failed compressor — often the breaker is off or the plug is loose',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: fridgeBeginnerSafety,
  ),
];

const List<FailureModeAuthoringSummary> _dishwasherMvpAuthoringSummaries = [
  FailureModeAuthoringSummary(
    id: dishwasherCloggedFilterId,
    title: 'Clogged tub filter',
    immediateCause: 'Food debris in the accessible tub filter',
    rootCause: 'Filter not rinsed, so water could not leave the tub',
    contributingFactors: ['Skipped filter cleaning', 'Starchy or greasy loads'],
    preventionActions: [
      'Rinse the accessible tub filter about every 30 days',
      'Scrape plates before loading',
    ],
    commonMisdiagnoses: [
      'A failed drain pump — often the tub filter is packed',
      'A sealed-pump replacement — rinse the accessible filter first',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: dishwasherBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: dishwasherDrainPathId,
    title: 'Kinked drain hose or blocked drain path',
    immediateCause: 'The accessible drain path was pinched or blocked',
    rootCause: 'Hose kink, air-gap debris, or a disposal knockout still in place',
    contributingFactors: ['Dishwasher recently moved', 'New disposal install'],
    preventionActions: [
      'Leave a gentle bend in the drain hose, not a pinch',
      'Keep the air gap cap clear if your sink has one',
    ],
    commonMisdiagnoses: [
      'A failed pump — check the hose, air gap, and disposal knockout first',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: dishwasherBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: dishwasherDoorNotLatchedId,
    title: 'Door not fully latched',
    immediateCause: 'The door interlock was not closed',
    rootCause: 'Door not clicked shut, or something in the seal',
    contributingFactors: ['Utensil in the door', 'Warped seal'],
    preventionActions: [
      'Close until you feel a click before pressing Start',
      'Keep the door seal free of utensils',
    ],
    commonMisdiagnoses: [
      'A failed control board — often the door is not clicked shut',
      'A no-power diagnosis that needs a meter — this path is a latch look only',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: dishwasherBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: dishwasherCloggedSprayArmsId,
    title: 'Clogged spray arms or dirty filter',
    immediateCause: 'Spray could not reach the dishes',
    rootCause: 'Blocked spray holes, a dirty filter, or a packed load',
    contributingFactors: ['Hard water film', 'Overloading'],
    preventionActions: [
      'Clear spray-arm holes when you clean the filter, about every 30 days',
      'Load so arms can spin',
    ],
    commonMisdiagnoses: [
      'A failed heater or pump — often blocked spray or a packed load',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: dishwasherBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: dishwasherClosedSupplyId,
    title: 'Closed supply or air-gap blockage',
    immediateCause: 'No water reaching the dishwasher',
    rootCause: 'Closed under-sink tap or a packed air-gap cap',
    contributingFactors: ['Sink work', 'Shared shutoff closed'],
    preventionActions: [
      'Confirm the dishwasher supply tap is open after plumbing work',
      'Rinse the air-gap cap if your sink has one',
    ],
    commonMisdiagnoses: [
      'A failed fill valve — often the supply tap is closed',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: dishwasherBeginnerSafety,
  ),
  FailureModeAuthoringSummary(
    id: dishwasherDoorSealLeakId,
    title: 'Door seal drip or loose visible connection',
    immediateCause: 'Water left at the door seal or a visible sink hose',
    rootCause: 'Food in the seal or a loose accessible coupling',
    contributingFactors: ['Skipped wipe of the seal', 'Unit recently pulled out'],
    preventionActions: [
      'Wipe the door seal when you rinse the filter',
      'Hand-check visible sink connections after moving the unit',
    ],
    commonMisdiagnoses: [
      'A cracked tub — often food in the door seal or a loose hose nut',
    ],
    toolsRequired: ['None for beginner external checks'],
    safetyNotes: dishwasherBeginnerSafety,
  ),
];
