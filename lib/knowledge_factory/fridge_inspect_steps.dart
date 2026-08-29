import '../helpers/easy_check_already_checked.dart';
import '../models/inspect_step.dart';

/// Setpoints before pulling the cabinet.
const List<String> fridgeTempsInspectModeIds = [
  'blocked-fridge-coils-or-airflow',
  'fridge-temp-controls-set-wrong',
];

const List<String> fridgeSealInspectModeIds = [
  'blocked-fridge-coils-or-airflow',
  'blocked-fridge-internal-vents',
  'fridge-door-gasket-or-ajar',
  'fridge-temp-controls-set-wrong',
];

const List<String> fridgeVentsInspectModeIds = [
  'blocked-fridge-coils-or-airflow',
  'blocked-fridge-internal-vents',
];

/// Dial or digital setpoint — mid-range vs an extreme stop.
const InspectStep fridgeTempsInspectStep = InspectStep(
  id: 'inspect-fridge-temps',
  title: 'Look at the temperature controls',
  safetyPreamble:
      'This is a look-only check. Do not open the sealed cooling system. No '
      'live electrical testing. No compressor live diagnostics.',
  lookFor:
      'Find the fridge and freezer temperature dials or digital setpoints '
      '(inside the fresh-food side or on the dispenser). See whether they sit '
      'near the middle of the range, not the warmest or coldest stop.',
  okMeans:
      'Both controls sit in a normal mid-range — not at the warmest or '
      'coldest stop.',
  notOkMeans:
      'A control is at the warmest or coldest stop, or you cannot tell where '
      'it is set.',
  diagramAsset: 'diagram:fridge-front',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'fridge',
  evidenceTemplateId: 'fridge-temps-or-settings',
  relatedEasyCheckTemplateId: 'fridge-temps-or-settings',
  failureModeIds: fridgeTempsInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes — mid-range',
    inspectDoesntMatchChip: 'No — at an extreme',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.38,
    top: 0.22,
    width: 0.24,
    height: 0.18,
  ),
);

/// Door gasket seated — no switch or sealed-system work.
const InspectStep fridgeDoorSealInspectStep = InspectStep(
  id: 'inspect-fridge-door-seal',
  title: 'Look at the door gasket',
  safetyPreamble:
      'Do not cut or stretch the gasket off its channel. Do not open the '
      'sealed cooling system. No live electrical testing.',
  lookFor:
      'Close each door until it sits flush. Look along the rubber gasket for '
      'gaps, tears, or food in the seal. A dollar-bill tug at the gasket '
      'should feel snug, not slide out freely.',
  okMeans:
      'Each door stays shut and the gasket looks clean, intact, and seated.',
  notOkMeans:
      'A door pops open, or the gasket has a gap, tear, or sticky food in '
      'the seal.',
  diagramAsset: 'diagram:fridge-front',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'fridge',
  evidenceTemplateId: 'fridge-door-seal',
  relatedEasyCheckTemplateId: 'fridge-door-seal',
  failureModeIds: fridgeSealInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes',
    inspectDoesntMatchChip: 'No',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.12,
    top: 0.28,
    width: 0.22,
    height: 0.44,
  ),
);

/// Internal vents — food/bins covering the openings.
const InspectStep fridgeVentsInspectStep = InspectStep(
  id: 'inspect-fridge-vents',
  title: 'Look at the internal air vents',
  safetyPreamble:
      'Stay inside the compartments. Do not open the sealed cooling system. '
      'No live electrical testing. No compressor live diagnostics.',
  lookFor:
      'Inside the fridge and freezer, find the slotted air vents on a back or '
      'side wall. Look whether bins, bottles, or food cover those openings.',
  okMeans: 'The vent slots are visible and not covered by food or bins.',
  notOkMeans: 'Food, bins, or a sheet of ice covers the vent openings.',
  diagramAsset: 'diagram:fridge-front',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'fridge',
  evidenceTemplateId: 'fridge-internal-vents',
  relatedEasyCheckTemplateId: 'fridge-internal-vents',
  failureModeIds: fridgeVentsInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.66,
    top: 0.28,
    width: 0.24,
    height: 0.28,
  ),
);

/// Toe-kick / accessible coils — look before pulling the cabinet.
const InspectStep fridgeCoilsInspectStep = InspectStep(
  id: 'inspect-fridge-coils',
  title: 'Look at the accessible coils or grille',
  safetyPreamble:
      'Unplug before pulling the fridge out. This look is from outside. Do '
      'not open the sealed cooling system, pierce tubes, or handle '
      'refrigerant. No compressor live diagnostics.',
  lookFor:
      'At the toe-kick grille under the doors, or at the rear after a short '
      'pull, look for a mat of dust on accessible condenser coils. See whether '
      'the cabinet is packed tight to the wall. Do not vacuum yet.',
  okMeans:
      'The grille or coils look clear and the cabinet has a few inches of '
      'space behind it.',
  notOkMeans:
      'Dust is packed on the accessible coils or grille, or the fridge is '
      'tight against the wall.',
  diagramAsset: 'diagram:fridge-rear',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'fridge',
  evidenceTemplateId: 'fridge-coils-or-space',
  relatedEasyCheckTemplateId: 'fridge-coils-or-space',
  failureModeIds: ['blocked-fridge-coils-or-airflow'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.28,
    top: 0.68,
    width: 0.44,
    height: 0.22,
  ),
);

/// Package order: temps, gasket, vents, then coils (coils mode only).
const List<InspectStep> fridgePackageInspectSteps = [
  fridgeTempsInspectStep,
  fridgeDoorSealInspectStep,
  fridgeVentsInspectStep,
  fridgeCoilsInspectStep,
];
