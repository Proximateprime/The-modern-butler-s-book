import '../helpers/easy_check_already_checked.dart';
import '../models/inspect_step.dart';

/// Won't-drain / standing-water modes: filter, door, then high-loop look.
const List<String> dishwasherDrainInspectModeIds = [
  'clogged-dishwasher-filter',
  'kinked-or-clogged-dishwasher-drain',
];

/// Door latch look before any switch bypass.
const List<String> dishwasherDoorInspectModeIds = [
  'clogged-dishwasher-filter',
  'kinked-or-clogged-dishwasher-drain',
  'dishwasher-door-not-latched',
];

/// Poor-clean spray-arm look. Filter inspect is shared with drain.
const List<String> dishwasherSprayInspectModeIds = [
  'clogged-dishwasher-spray-arms',
];

/// Filter / sump visible debris — look only, no sealed pump.
const InspectStep dishwasherFilterInspectStep = InspectStep(
  id: 'inspect-dishwasher-filter',
  title: 'Look at the tub filter and sump',
  safetyPreamble:
      'Unplug the dishwasher (or switch off its breaker) before reaching into '
      'the tub. Do not open a sealed pump or motor. Do not reach inside while '
      'it is running.',
  lookFor:
      'Pull out the lower dish rack. On the tub floor, find the round or '
      'square filter you can lift or twist out by hand. Look at the mesh and '
      'the shallow well around it for a mat of food, glass, or grease. Do not '
      'open the pump under the filter.',
  okMeans:
      'The mesh and sump look clear — no mat of food or standing sludge.',
  notOkMeans:
      'Food, glass, or grease is packed on the filter or in the visible sump.',
  diagramAsset: 'diagram:dishwasher-tub',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dishwasher',
  evidenceTemplateId: 'dishwasher-filter-debris',
  relatedEasyCheckTemplateId: 'dishwasher-filter-debris',
  failureModeIds: [
    ...dishwasherDrainInspectModeIds,
    ...dishwasherSprayInspectModeIds,
  ],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.38,
    top: 0.58,
    width: 0.24,
    height: 0.24,
  ),
);

/// Door latched / solid click — no switch bypass.
const InspectStep dishwasherDoorClickInspectStep = InspectStep(
  id: 'inspect-dishwasher-door-click',
  title: 'Check that the door latches',
  safetyPreamble:
      'Do not bypass the door switch or open a sealed control box. No live '
      'electrical testing.',
  lookFor:
      'Close the dishwasher door until it is flush with the cabinet. Press at '
      'the top-center latch until you feel or hear one solid click. Nothing '
      'should be in the seal.',
  okMeans:
      'The door stays shut and you feel or hear a firm click. Nothing is '
      'caught in the seal.',
  notOkMeans:
      'It will not click, springs open, or food in the seal keeps it from '
      'latching.',
  diagramAsset: 'diagram:dishwasher-tub',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dishwasher',
  evidenceTemplateId: 'dishwasher-door-click',
  relatedEasyCheckTemplateId: 'dishwasher-door-click',
  failureModeIds: dishwasherDoorInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes',
    inspectDoesntMatchChip: 'No',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.38,
    top: 0.08,
    width: 0.24,
    height: 0.18,
  ),
);

/// Drain hose high-loop / air-gap — observation only.
const InspectStep dishwasherDrainHoseInspectStep = InspectStep(
  id: 'inspect-dishwasher-drain-hose',
  title: 'Look at the drain hose, high-loop, or air gap',
  safetyPreamble:
      'This is a look-only check. Unplug before pulling the dishwasher out if '
      'the hose is hidden. Do not split a sealed pump. No live electrical '
      'testing.',
  lookFor:
      'Under the sink, find the dishwasher drain hose. Trace it: it should '
      'rise in a high loop on the cabinet side before it goes down to the '
      'air-gap cap (chrome cap on the sink, if present) or the disposal inlet. '
      'If a disposal was just installed, look into that inlet for a leftover '
      'knockout plug. Do not unscrew fittings.',
  okMeans:
      'The hose is not crushed or kinked, it rises in a high loop where you '
      'can see it, an air-gap cap (if present) is not packed, and a disposal '
      'inlet (if used) is not blocked by a leftover knockout.',
  notOkMeans:
      'The hose is kinked or flattened, it sags below the sink rim with no '
      'high loop, the air-gap cap is packed, or a new disposal still has its '
      'knockout in place. Observation only — do not cut or re-route plumbing.',
  diagramAsset: 'diagram:dishwasher-sink',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dishwasher',
  evidenceTemplateId: 'dishwasher-drain-hose',
  relatedEasyCheckTemplateId: 'dishwasher-drain-hose',
  failureModeIds: dishwasherDrainInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.58,
    top: 0.24,
    width: 0.28,
    height: 0.28,
  ),
);

/// Fill: under-sink supply tap and air-gap cap — look only.
const InspectStep dishwasherSupplyInspectStep = InspectStep(
  id: 'inspect-dishwasher-supply',
  title: 'Look at the supply tap and air-gap cap',
  safetyPreamble:
      'Look under the sink. Do not open a sealed pump or split a fill valve. '
      'No live electrical testing. Unplug before you later move the dishwasher.',
  lookFor:
      'Under the sink, find the dishwasher supply tap (often a small valve on '
      'the hot line) and, if your sink has one, the chrome air-gap cap on the '
      'counter or sink. The tap handle should be in line with the pipe. The '
      'air-gap cap should lift and not be packed with food.',
  okMeans:
      'The supply tap looks fully open and the air-gap cap (if present) is '
      'clear of debris.',
  notOkMeans:
      'The supply tap is closed or only partly open, or the air-gap cap is '
      'packed with food.',
  diagramAsset: 'diagram:dishwasher-sink',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dishwasher',
  evidenceTemplateId: 'dishwasher-supply-open',
  relatedEasyCheckTemplateId: 'dishwasher-supply-open',
  failureModeIds: ['closed-dishwasher-supply-or-air-gap'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes',
    inspectDoesntMatchChip: 'No',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Poor clean: spray-arm holes and packed load — look only.
const InspectStep dishwasherSprayInspectStep = InspectStep(
  id: 'inspect-dishwasher-spray',
  title: 'Look at the spray-arm holes',
  safetyPreamble:
      'Open the door and look. Do not reach inside while it is running. Unplug '
      'before you later lift a spray arm. Do not open a sealed pump. No live '
      'electrical testing.',
  lookFor:
      'With the door open, look along the lower (and upper, if present) spray '
      'arm. Holes should be open, not packed with food or mineral crust. Dishes '
      'should not be stacked so they block the arm from spinning.',
  okMeans:
      'Spray-arm holes look open and the load is not packed against the arms.',
  notOkMeans:
      'Holes look clogged with food, or the load is packed so water cannot '
      'reach the dishes.',
  diagramAsset: 'diagram:dishwasher-tub',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dishwasher',
  evidenceTemplateId: 'dishwasher-spray-holes',
  relatedEasyCheckTemplateId: 'dishwasher-spray-holes',
  failureModeIds: dishwasherSprayInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Leak: door gasket or visible sink hose — observational only.
const InspectStep dishwasherLeakInspectStep = InspectStep(
  id: 'inspect-dishwasher-leak',
  title: 'Look at the door seal and visible sink hose',
  safetyPreamble:
      'Look at the gasket and, if you can see it, the hose under the sink. Do '
      'not split a sealed tub or pump. Unplug before you later pull the unit. '
      'No live electrical testing.',
  lookFor:
      'Wipe the door gasket and look for food stuck in the fold, or a drip at '
      'the bottom of the door. Under the sink, look at any visible dishwasher '
      'hose nut for a drip. Do not open a sealed cabinet or pump.',
  okMeans:
      'The door gasket looks clean and dry, and any visible sink hose stays dry.',
  notOkMeans:
      'Water drips at the door gasket, or a visible hose nut under the sink is '
      'wet.',
  diagramAsset: 'diagram:dishwasher-tub',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dishwasher',
  evidenceTemplateId: 'dishwasher-door-seal-leak',
  relatedEasyCheckTemplateId: 'dishwasher-door-seal-leak',
  failureModeIds: ['dishwasher-door-seal-or-loose-connection'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Not leaking',
    inspectDoesntMatchChip: 'Door seal',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Drain: filter/sump, door, high-loop/hose. Fill: supply. Poor clean: filter
/// then spray. Leak: gasket/hose. Door-not-latched: door only. No dryer assets.
const List<InspectStep> dishwasherPackageInspectSteps = [
  dishwasherFilterInspectStep,
  dishwasherDoorClickInspectStep,
  dishwasherDrainHoseInspectStep,
  dishwasherSupplyInspectStep,
  dishwasherSprayInspectStep,
  dishwasherLeakInspectStep,
];
