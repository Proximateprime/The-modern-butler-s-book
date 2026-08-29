import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'washer_inspect_steps.dart';

/// Washer primary-path package — beginner-safe, no sealed-system or live
/// electrical work. Easy checks first on drain, fill, spin, leak, and start.
/// Release: docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md (does not auto-publish).
const String washerPackageId = 'washer-core';
const String washerPackageVersion = '0.2.3';

const String washerCloggedDrainFilterId = 'clogged-washer-drain-filter';
const String washerDrainHoseId = 'kinked-or-clogged-washer-drain-hose';
const String washerClosedTapsId = 'closed-taps-or-kinked-inlet';
const String washerCloggedInletScreensId = 'clogged-washer-inlet-screens';
const String washerUnbalancedLoadId = 'unbalanced-washer-load';
const String washerLooseInletHoseId = 'loose-inlet-hose';
const String washerDrainHoseNotSeatedId = 'washer-drain-hose-not-seated';
const String washerDoorNotLatchedId = 'washer-door-not-latched';
const String washerNoPowerOrLockId = 'washer-no-power-or-control-lock';

const String washerComplaintTemplateId = 'washer-complaint';

const String _beginnerSafety =
    'Beginner-safe only: unplug first. Do not open a sealed tub or pump, '
    'and do not do live electrical testing. No gas work.';

KnowledgePackage buildWasherMvpPackage() {
  return KnowledgePackage(
    id: washerPackageId,
    category: 'washer',
    version: washerPackageVersion,
    displayName: 'Washer Knowledge Package',
    schemaVersion: '1.0',
    createdAt: DateTime.utc(2026, 8, 19),
    source:
        'Washer Knowledge Package V0.2.3 — primary paths; drain-filter packed vs '
        'clear inspect; standpipe/hose-setup looks',
    status: KnowledgePackageStatus.production,
    inspectSteps: washerPackageInspectSteps,
    failureModes: const [
      FailureMode(
        id: washerCloggedDrainFilterId,
        label: 'Clogged drain filter or pump trap',
        description:
            'Lint, coins, or debris in the accessible drain filter can leave '
            'water in the drum after a cycle.',
        commonality: FailureModeCommonality.veryHigh,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerDrainHoseId,
        label: 'Kinked or clogged drain hose',
        description:
            'A pinched drain hose behind the washer, or a hose stuffed too far '
            'into the standpipe, can stop drain even when the filter is clear.',
        commonality: FailureModeCommonality.high,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerClosedTapsId,
        label: 'Closed taps or kinked inlet hose',
        description:
            'The washer cannot fill if the water taps are closed or the inlet '
            'hose is kinked.',
        commonality: FailureModeCommonality.high,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerCloggedInletScreensId,
        label: 'Packed inlet-hose screens',
        description:
            'Grit in the small screens at the hose ends can starve fill even '
            'when the taps are open. Stay at the hose ends — do not open the '
            'inlet valve body.',
        commonality: FailureModeCommonality.common,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerUnbalancedLoadId,
        label: 'Unbalanced load',
        description:
            'A bunched load can stop or shake the spin. Redistribute clothes; '
            'do not force the motor.',
        commonality: FailureModeCommonality.high,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerLooseInletHoseId,
        label: 'Loose inlet hose at the tap',
        description:
            'A loose coupling at the tap or inlet hose can drip onto the floor.',
        commonality: FailureModeCommonality.high,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerDrainHoseNotSeatedId,
        label: 'Drain hose not seated in the standpipe',
        description:
            'If the drain hose slipped out of the standpipe or is not clipped, '
            'water can pour behind the washer during drain.',
        commonality: FailureModeCommonality.common,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerDoorNotLatchedId,
        label: 'Door not fully latched',
        description:
            'The washer may not start or drain if the door is not closed '
            'firmly until it clicks. Do not bypass the door switch.',
        commonality: FailureModeCommonality.high,
        safetyNotes: _beginnerSafety,
      ),
      FailureMode(
        id: washerNoPowerOrLockId,
        label: 'No power, breaker off, or control lock',
        description:
            'Start does nothing if the cord is unplugged, the breaker is off, '
            'or a child-lock / control-lock light is on. Do not test live '
            'voltage.',
        commonality: FailureModeCommonality.common,
        safetyNotes: _beginnerSafety,
      ),
    ],
    symptoms: const [
      Symptom(
        id: 'wont-drain',
        label: "Won't drain",
        description: 'Water remains in the drum after the cycle.',
      ),
      Symptom(
        id: 'wont-fill',
        label: "Won't fill",
        description: 'Little or no water enters when a wash starts.',
      ),
      Symptom(
        id: 'wont-spin',
        label: "Won't spin",
        description: 'The drum does not spin, or shakes hard and stops.',
      ),
      Symptom(
        id: 'leaks',
        label: 'Leaks',
        description: 'Water appears on the floor during fill or wash.',
      ),
      Symptom(
        id: 'wont-start',
        label: "Won't start",
        description: 'Controls do nothing, or Start does not begin a cycle.',
      ),
      Symptom(
        id: 'door-wont-close',
        label: "Door won't close",
        description: 'The door will not click shut, or Start does nothing.',
      ),
    ],
    evidenceTemplates: [
      EvidenceTemplate(
        id: washerComplaintTemplateId,
        promptText: 'What is the washer doing?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [
          washerCloggedDrainFilterId,
          washerDrainHoseId,
          washerClosedTapsId,
          washerCloggedInletScreensId,
          washerUnbalancedLoadId,
          washerLooseInletHoseId,
          washerDrainHoseNotSeatedId,
          washerDoorNotLatchedId,
          washerNoPowerOrLockId,
        ],
        answerChoices: const [
          "Won't drain",
          "Won't fill",
          "Won't spin",
          'Leaks',
          "Won't start",
          "Door won't close", // Front-load default; top-load overlay uses lid.
        ],
        supportByAnswer: const {
          "Won't drain": [
            washerCloggedDrainFilterId,
            washerDrainHoseId,
          ],
          "Won't fill": [
            washerClosedTapsId,
            washerCloggedInletScreensId,
          ],
          "Won't spin": [washerUnbalancedLoadId],
          'Leaks': [
            washerLooseInletHoseId,
            washerDrainHoseNotSeatedId,
          ],
          "Won't start": [
            washerDoorNotLatchedId,
            washerNoPowerOrLockId,
          ],
          "Door won't close": [washerDoorNotLatchedId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-door-click',
        promptText:
            'Does the door or lid close firmly until you feel or hear a solid click?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerDoorNotLatchedId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'No': [washerDoorNotLatchedId],
        },
        excludeByAnswer: const {
          'Yes': [washerDoorNotLatchedId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-drain-filter-access',
        promptText:
            'After unplugging, looking at the accessible coin trap / drain '
            'filter from outside (do not split a sealed pump), does it look '
            'packed with lint, coins, or sludge?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerCloggedDrainFilterId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [washerCloggedDrainFilterId],
        },
        excludeByAnswer: const {
          'No': [washerCloggedDrainFilterId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-drain-hose-look',
        promptText:
            'Looking behind the washer without opening the cabinet, is the '
            'drain hose kinked, crushed, or stuffed deep into the standpipe?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [
          washerDrainHoseId,
          washerDrainHoseNotSeatedId,
        ],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [washerDrainHoseId, washerDrainHoseNotSeatedId],
        },
        excludeByAnswer: const {
          'No': [washerDrainHoseId, washerDrainHoseNotSeatedId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-taps-open',
        promptText:
            'Are both water taps fully open, and is the inlet hose unkinked?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerClosedTapsId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'No': [washerClosedTapsId],
        },
        excludeByAnswer: const {
          'Yes': [washerClosedTapsId],
          'No': [washerCloggedInletScreensId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-inlet-screens-look',
        promptText:
            'After unplugging and closing the taps, do the small screens at '
            'the hose ends look packed with grit? Stay at the hose — do not '
            'open the valve body.',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerCloggedInletScreensId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [washerCloggedInletScreensId],
        },
        excludeByAnswer: const {
          'No': [washerCloggedInletScreensId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-load-bunched',
        promptText: 'Is the load bunched on one side of the drum?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerUnbalancedLoadId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [washerUnbalancedLoadId],
        },
        excludeByAnswer: const {
          'No': [washerUnbalancedLoadId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-water-in-drum',
        promptText:
            'Is there still a pool of water in the drum (so spin cannot start)?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerCloggedDrainFilterId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [washerCloggedDrainFilterId],
        },
        excludeByAnswer: const {
          'Yes': [washerUnbalancedLoadId],
          'No': [washerCloggedDrainFilterId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-leak-at-tap',
        promptText: 'Is the leak at the tap or the inlet hose coupling?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerLooseInletHoseId],
        answerChoices: const ['Yes', 'No', 'Not sure', 'Not leaking'],
        supportByAnswer: const {
          'Yes': [washerLooseInletHoseId],
        },
        excludeByAnswer: const {
          'Not leaking': [washerLooseInletHoseId],
          'Yes': [washerDrainHoseNotSeatedId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-standpipe-hose',
        promptText:
            'Is the leak behind the washer at the standpipe, or has the drain '
            'hose slipped out?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerDrainHoseNotSeatedId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [washerDrainHoseNotSeatedId],
        },
        excludeByAnswer: const {
          'Yes': [washerLooseInletHoseId],
          'No': [washerDrainHoseNotSeatedId],
        },
      ),
      EvidenceTemplate(
        id: 'washer-power-or-lock',
        promptText:
            'Is the washer plugged in, the breaker on, and is a child-lock or '
            'control-lock light off? Do not test live voltage.',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [washerNoPowerOrLockId],
        answerChoices: const ['Yes — looks powered', 'No — unplugged, off, or locked', 'Not sure'],
        supportByAnswer: const {
          'No — unplugged, off, or locked': [washerNoPowerOrLockId],
        },
        excludeByAnswer: const {
          'Yes — looks powered': [washerNoPowerOrLockId],
        },
      ),
      EvidenceTemplate(
        id: 'hazard-observation',
        promptText:
            'Do you notice smoke, sparking, or a sharp burning-electrical smell?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [],
        answerChoices: const ['No', 'Yes'],
      ),
    ],
    safeChecks: [
      SafeCheck(
        id: 'washer-unplug-first',
        label: 'Unplug before any filter or hose check',
        description:
            'Unplug the washer (or switch off its breaker) before opening a '
            'drain filter or touching inlet fittings.',
        requiredTools: const [],
        safetyLevel: 'beginner',
      ),
      SafeCheck(
        id: 'washer-no-sealed-system',
        label: 'Do not open a sealed tub or pump',
        description:
            'Stay with accessible filters, hoses, and taps. Do not split a '
            'sealed tub, pump housing, or transmission.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
      SafeCheck(
        id: 'washer-no-live-electrical',
        label: 'No live electrical work',
        description:
            'Do not test live voltage, probe wiring, or work in an energized '
            'control box.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
      SafeCheck(
        id: 'washer-no-gas',
        label: 'No gas work',
        description:
            'This guide is not for gas dryers or gas lines. Call a technician '
            'for any gas smell or gas appliance work.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
    ],
  );
}
