import '../helpers/easy_check_already_checked.dart';
import '../models/inspect_step.dart';

/// Won't-drain modes that run door-click then coin-trap look before opening.
const List<String> washerDrainInspectModeIds = [
  'clogged-washer-drain-filter',
  'kinked-or-clogged-washer-drain-hose',
];

/// Door latch look before any switch bypass or seal teardown.
const List<String> washerDoorInspectModeIds = [
  'clogged-washer-drain-filter',
  'kinked-or-clogged-washer-drain-hose',
  'washer-door-not-latched',
];

/// Prior install / drain-hose setup: not seated, stuffed too deep, or disconnected.
const List<String> washerDrainSetupInspectModeIds = [
  'washer-drain-hose-not-seated',
  'kinked-or-clogged-washer-drain-hose',
];

/// Door latched / solid click — no switch bypass.
const InspectStep washerDoorClickInspectStep = InspectStep(
  id: 'inspect-washer-door-click',
  title: 'Check that the door latches',
  safetyPreamble:
      'Do not bypass the door switch or probe latch wiring. No live electrical '
      'testing.',
  lookFor:
      'Close the door or lid all the way. Press at the handle until you feel '
      'or hear one solid click at the latch (front-load: catch at the right of '
      'the opening; top-load: lid catch). Nothing should be caught in the seal.',
  okMeans:
      'The door stays shut and you feel or hear a firm click. Nothing is '
      'caught in the seal.',
  notOkMeans:
      'It springs back, will not click, or something in the seal keeps it '
      'from latching.',
  diagramAsset: 'diagram:washer-front',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-door-click',
  relatedEasyCheckTemplateId: 'washer-door-click',
  failureModeIds: washerDoorInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes',
    inspectDoesntMatchChip: 'No',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.68,
    top: 0.28,
    width: 0.26,
    height: 0.32,
  ),
);

/// Accessible drain filter / coin trap — look only until this chip is answered.
const InspectStep washerDrainFilterInspectStep = InspectStep(
  id: 'inspect-washer-drain-filter',
  title: 'Look at the drain filter or coin trap',
  safetyPreamble:
      'Unplug the washer (or switch off its breaker) before opening a filter '
      'cover. Do not split a sealed tub or pump. Place a pan only after this '
      'look if you later open the access.',
  lookFor:
      'At the lower front corner of the cabinet, find the small square access '
      'door or twist-off knob for the coin trap / drain filter. From outside, '
      'look whether lint or coins are packed in that opening. Do not unscrew a '
      'sealed pump.',
  okMeans:
      'You can see the typical access, and from outside it is not stuffed with '
      'lint, coins, or sludge.',
  notOkMeans:
      'The trap looks packed with lint, coins, or sludge, or the cover cannot '
      'seat. Still do not split a sealed pump.',
  diagramAsset: 'diagram:washer-front',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-drain-filter-access',
  relatedEasyCheckTemplateId: 'washer-drain-filter-access',
  failureModeIds: washerDrainInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.08,
    top: 0.62,
    width: 0.28,
    height: 0.28,
  ),
);

/// Drain hose actually in the standpipe — common after a move or new install.
const InspectStep washerStandpipeInspectStep = InspectStep(
  id: 'inspect-washer-standpipe',
  title: 'Look at the drain hose in the standpipe',
  safetyPreamble:
      'Unplug the washer before pulling it out or reaching behind it. Do not '
      'split a sealed tub or pump. No live electrical testing.',
  lookFor:
      'Behind the washer, find the drain hose end. It should sit inside the '
      'vertical standpipe (or hooked over a laundry tub) with a clip or hook '
      'holding it so it cannot slip out onto the floor.',
  okMeans:
      'The hose is seated in the standpipe (or tub) and looks clipped or '
      'hooked so it cannot drop out.',
  notOkMeans:
      'The hose is hanging free, barely hooked, or water would pour on the '
      'floor instead of into the pipe — a common after-move or new-install miss.',
  diagramAsset: 'diagram:washer-rear',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-standpipe-hose',
  relatedEasyCheckTemplateId: 'washer-standpipe-hose',
  failureModeIds: ['washer-drain-hose-not-seated'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.62,
    top: 0.40,
    width: 0.30,
    height: 0.32,
  ),
);

/// Hose run: stuffed too deep, disconnected, crushed, or no rise.
const InspectStep washerDrainHoseConfigInspectStep = InspectStep(
  id: 'inspect-washer-drain-hose-config',
  title: 'Look at how the drain hose is run',
  safetyPreamble:
      'Unplug before pulling the washer out. This is a look-only check. Do not '
      'cut plumbing or open a sealed pump. No live electrical testing.',
  lookFor:
      'Follow the drain hose from the washer cabinet to the standpipe. Check '
      'that it is connected at both ends, stays round (not crushed), has no '
      'sharp kink, and that only a short length sits in the pipe — not stuffed '
      'deep.',
  okMeans:
      'The hose is connected, not crushed, and only a short length sits in '
      'the standpipe — not jammed down the pipe.',
  notOkMeans:
      'It is disconnected, flattened, sharply bent, or stuffed deep into the '
      'standpipe (a common incorrect setup).',
  diagramAsset: 'diagram:washer-rear',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-drain-hose-look',
  relatedEasyCheckTemplateId: 'washer-drain-hose-look',
  failureModeIds: washerDrainSetupInspectModeIds,
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
  frameHint: InspectFrameHint(
    left: 0.62,
    top: 0.40,
    width: 0.30,
    height: 0.32,
  ),
);

/// Fill: both taps open, inlet hose not kinked — look only.
const InspectStep washerTapsInletInspectStep = InspectStep(
  id: 'inspect-washer-taps-inlet',
  title: 'Look at the taps and inlet hose',
  safetyPreamble:
      'This is a look at the taps and the visible hose. Do not open the '
      'cabinet, inlet valve body, or any wiring. No live electrical testing.',
  lookFor:
      'At the wall behind the washer, both hot and cold taps should be fully '
      'open (handles in line with the pipe). The inlet hose should be round, '
      'not sharply kinked or crushed.',
  okMeans:
      'Both taps look fully open and the visible inlet hose is not kinked.',
  notOkMeans:
      'A tap is closed or only partly open, or the inlet hose is kinked or '
      'crushed.',
  diagramAsset: 'diagram:washer-rear',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-taps-open',
  relatedEasyCheckTemplateId: 'washer-taps-open',
  failureModeIds: [
    'closed-taps-or-kinked-inlet',
    'clogged-washer-inlet-screens',
  ],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes',
    inspectDoesntMatchChip: 'No',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Fill discriminator: grit in hose-end screens — look after unplug, stay at hose.
const InspectStep washerInletScreensInspectStep = InspectStep(
  id: 'inspect-washer-inlet-screens',
  title: 'Look at the inlet-hose screens',
  safetyPreamble:
      'Unplug the washer and close both taps before loosening a coupling. Stay '
      'at the hose ends. Do not open the inlet valve body or cabinet wiring. '
      'No live electrical testing.',
  lookFor:
      'At the tap end of each inlet hose, look at the small screen or washer '
      'in the coupling. Packed grit or scale can starve fill even when taps '
      'are open.',
  okMeans:
      'The small screens at the hose ends look clear — not packed with grit.',
  notOkMeans:
      'A screen looks packed with grit or scale. Still do not open the valve '
      'body.',
  diagramAsset: 'diagram:washer-rear',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-inlet-screens-look',
  relatedEasyCheckTemplateId: 'washer-inlet-screens-look',
  failureModeIds: ['clogged-washer-inlet-screens'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'No',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Leak at the tap coupling — look only until this chip is answered.
const InspectStep washerLeakTapInspectStep = InspectStep(
  id: 'inspect-washer-leak-tap',
  title: 'Look at the inlet coupling for drips',
  safetyPreamble:
      'Look at the tap and hose nut. Do not open the cabinet or a sealed valve '
      'body. Unplug before you later tighten anything. No live electrical '
      'testing.',
  lookFor:
      'At the wall tap, watch the hose coupling during fill (or wipe it and '
      'look for fresh drips). A drip at the nut is a loose coupling — not a '
      'split tub.',
  okMeans:
      'The tap coupling stays dry. Any water on the floor is not coming from '
      'that nut.',
  notOkMeans:
      'Water drips at the tap or inlet-hose nut.',
  diagramAsset: 'diagram:washer-rear',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-leak-at-tap',
  relatedEasyCheckTemplateId: 'washer-leak-at-tap',
  failureModeIds: ['loose-inlet-hose'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Not leaking',
    inspectDoesntMatchChip: 'Yes',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Won't-start: plug, breaker look, control-lock light — never a meter.
const InspectStep washerPowerLockInspectStep = InspectStep(
  id: 'inspect-washer-power-lock',
  title: 'Look at power and control lock',
  safetyPreamble:
      'Look only: plug seated, breaker position, control-lock or child-lock '
      'light. Do not test live voltage, probe wiring, or open the control box.',
  lookFor:
      'The cord is fully in the outlet. The breaker or switch for this circuit '
      'is on. Any child-lock or control-lock light on the console is off. Do '
      'not use a meter.',
  okMeans:
      'The plug looks seated, the breaker looks on, and no lock light is on.',
  notOkMeans:
      'The plug is loose or out, the breaker is off, or a control-lock / '
      'child-lock light is on.',
  diagramAsset: 'diagram:washer-front',
  cameraMode: InspectCameraMode.viewOnly,
  appliesTo: 'washer',
  evidenceTemplateId: 'washer-power-or-lock',
  relatedEasyCheckTemplateId: 'washer-power-or-lock',
  failureModeIds: ['washer-no-power-or-control-lock'],
  evidenceAnswerByChip: {
    inspectMatchesOkChip: 'Yes — looks powered',
    inspectDoesntMatchChip: 'No — unplugged, off, or locked',
    inspectCantSeeChip: 'Not sure',
    alreadyCheckedEasyCheckAnswer: alreadyCheckedEasyCheckAnswer,
  },
  beginnerSafe: true,
  noLiveElectrical: true,
);

/// Door/filter on won't-drain; standpipe + hose on leak setup; taps/screens on
/// fill; tap drip on leak; power/lock on won't-start. No AR.
const List<InspectStep> washerPackageInspectSteps = [
  washerDoorClickInspectStep,
  washerDrainFilterInspectStep,
  washerStandpipeInspectStep,
  washerDrainHoseConfigInspectStep,
  washerTapsInletInspectStep,
  washerInletScreensInspectStep,
  washerLeakTapInspectStep,
  washerPowerLockInspectStep,
];
