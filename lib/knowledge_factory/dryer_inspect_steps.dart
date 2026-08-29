import '../helpers/easy_check_already_checked.dart';
import '../models/inspect_step.dart';

/// Packaged dryer schematics (typical location only — not a model photo).
const String dryerFrontInspectAsset = 'assets/inspect/dryer-front.svg';
const String dryerRearInspectAsset = 'assets/inspect/dryer-rear.svg';

/// Failure modes that must run lint → hood → hose inspect before panel work.
///
/// Matches `dryerEasyAirflowBeforePartsModeIds` (kept local to avoid a
/// circular import through close-path helpers).
const List<String> dryerEasyAirflowInspectModeIds = [
  'restricted-exhaust-airflow',
  'clogged-lint-pathway',
  'thermal-fuse-open',
  'heating-element-failed',
  'high-limit-thermostat-open',
  'thermistor-fault-electronic',
  'cycling-thermostat-failed',
  'cycling-thermostat-stuck-open',
  'cycling-thermostat-stuck-closed',
  'relay-or-control-no-heat-output',
  'timer-advanced-no-heat-portion',
  'motor-overheat-protector-open',
  'accessible-thermal-reset',
];

/// Lint filter: packed vs clear mesh at the typical door opening.
const InspectStep dryerLintFilterInspectStep = InspectStep(
  id: 'inspect-lint-filter',
  title: 'Look at the lint filter',
  safetyPreamble:
      'Unplug the dryer before reaching into the filter slot. Do not open the '
      'cabinet or probe wiring.',
  lookFor:
      'Pull the rectangular mesh screen from the slot in the door opening '
      '(or just inside the drum lip). Hold it up to a light and look through '
      'both sides of the mesh for packed lint you cannot see through.',
  okMeans:
      'You can see through the mesh. It is clear or only lightly dusted.',
  notOkMeans:
      'The mesh is packed with lint you cannot see through, missing, or torn.',
  diagramAsset: dryerFrontInspectAsset,
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dryer',
  evidenceTemplateId: 'lint-filter-condition',
  relatedEasyCheckTemplateId: 'lint-filter-condition',
  failureModeIds: dryerEasyAirflowInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Clean',
    inspectDoesntMatchChip: 'Heavily clogged',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.37,
    top: 0.26,
    width: 0.26,
    height: 0.11,
    label: 'Lint filter',
  ),
);

/// Outside vent hood: strong vs weak exhaust while the dryer runs.
const InspectStep dryerVentHoodInspectStep = InspectStep(
  id: 'inspect-vent-hood',
  title: 'Check the outside vent hood',
  safetyPreamble:
      'Stand to the side of the hood — not in the airstream. Keep hands and '
      'face clear of the flap. Do not reach into the duct. The dryer may run '
      'for this check; stop if you smell burning.',
  lookFor:
      'Find the plastic or metal vent flap on the house wall or soffit that '
      'the dryer duct feeds. Stand one step to the side. On a heat cycle, '
      'watch whether the flap opens and feel for a strong warm stream. Do not '
      'put your face in the airstream.',
  okMeans:
      'The flap moves and you feel a steady, strong stream of warm exhaust.',
  notOkMeans:
      'Little or no air, a stuck flap, or only a weak puff even on a heat cycle.',
  diagramAsset: dryerRearInspectAsset,
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dryer',
  evidenceTemplateId: 'exterior-airflow',
  relatedEasyCheckTemplateId: 'exterior-airflow',
  failureModeIds: dryerEasyAirflowInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Normal',
    inspectDoesntMatchChip: 'Weak',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.70,
    top: 0.28,
    width: 0.24,
    height: 0.26,
    label: 'Outside vent',
  ),
);

/// Visible flexible vent hose behind the dryer.
const InspectStep dryerVentHoseInspectStep = InspectStep(
  id: 'inspect-vent-hose',
  title: 'Look at the visible vent hose',
  safetyPreamble:
      'Unplug the dryer before pulling it out or reaching behind it. Do not '
      'run the dryer while you are behind it. Do not pinch cords or open the '
      'cabinet.',
  lookFor:
      'From behind the unplugged dryer, look at the flexible duct between the '
      'dryer’s rear exhaust collar and the wall. Check the full visible '
      'length for a flattened section, a sharp kink, lint packed in the ribs, '
      'or a long thin plastic run.',
  okMeans:
      'The hose is short, round, and open — not crushed, kinked, or packed.',
  notOkMeans:
      'It is flattened, sharply bent, packed with lint, or a long thin '
      'plastic run that can sag and trap lint.',
  diagramAsset: dryerRearInspectAsset,
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'dryer',
  evidenceTemplateId: 'vent-hose-condition',
  relatedEasyCheckTemplateId: 'vent-hose-condition',
  failureModeIds: dryerEasyAirflowInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Looks clear',
    inspectDoesntMatchChip: 'Yes, restricted',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.46,
    top: 0.40,
    width: 0.30,
    height: 0.22,
    label: 'Vent hose',
  ),
);

/// Ordered easy-airflow inspect chain: filter, outside hood, visible hose.
const List<InspectStep> dryerPackageInspectSteps = [
  dryerLintFilterInspectStep,
  dryerVentHoodInspectStep,
  dryerVentHoseInspectStep,
];
