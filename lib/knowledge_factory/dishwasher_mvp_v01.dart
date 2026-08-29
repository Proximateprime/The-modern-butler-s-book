import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dishwasher_inspect_steps.dart';

/// Dishwasher primary-path package. No sealed pump, live electrical, or
/// refrigerant work. Easy checks first on drain, fill, poor clean, leak, door.
/// Release: docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md (does not auto-publish).
const String dishwasherPackageId = 'dishwasher-core';
const String dishwasherPackageVersion = '0.2.3';

const String dishwasherCloggedFilterId = 'clogged-dishwasher-filter';
const String dishwasherDrainPathId = 'kinked-or-clogged-dishwasher-drain';
const String dishwasherDoorNotLatchedId = 'dishwasher-door-not-latched';
const String dishwasherCloggedSprayArmsId = 'clogged-dishwasher-spray-arms';
const String dishwasherClosedSupplyId = 'closed-dishwasher-supply-or-air-gap';
const String dishwasherDoorSealLeakId = 'dishwasher-door-seal-or-loose-connection';

const String dishwasherComplaintTemplateId = 'dishwasher-complaint';

const String dishwasherBeginnerSafety =
    'Beginner-safe only: unplug first. Do not open a sealed pump or motor. '
    'Do not do live electrical testing. Do not reach inside while it is running. '
    'No gas or sealed-system work.';

KnowledgePackage buildDishwasherMvpPackage() {
  return KnowledgePackage(
    id: dishwasherPackageId,
    category: 'dishwasher',
    version: dishwasherPackageVersion,
    displayName: 'Dishwasher Knowledge Package',
    schemaVersion: '1.0',
    createdAt: DateTime.utc(2026, 8, 19),
    source:
        'Dishwasher Knowledge Package V0.2.3 — primary paths; filter-first drain '
        'easy checks; against-evidence on filter/hose/spray',
    status: KnowledgePackageStatus.production,
    inspectSteps: dishwasherPackageInspectSteps,
    failureModes: const [
      FailureMode(
        id: dishwasherCloggedFilterId,
        label: 'Clogged tub filter',
        description:
            'Food debris in the accessible filter at the tub bottom can leave '
            'standing water after a cycle.',
        commonality: FailureModeCommonality.veryHigh,
        safetyNotes: dishwasherBeginnerSafety,
      ),
      FailureMode(
        id: dishwasherDrainPathId,
        label: 'Kinked drain hose or blocked drain path',
        description:
            'A kinked hose, a closed air gap, or a disposal knockout left in '
            'place can stop the dishwasher from draining.',
        commonality: FailureModeCommonality.high,
        safetyNotes: dishwasherBeginnerSafety,
      ),
      FailureMode(
        id: dishwasherClosedSupplyId,
        label: 'Closed supply or air-gap blockage',
        description:
            'The dishwasher cannot fill if the under-sink supply is closed or '
            'the air gap is packed. Stay with accessible taps and the air-gap '
            'cap — do not open a sealed pump.',
        commonality: FailureModeCommonality.high,
        safetyNotes: dishwasherBeginnerSafety,
      ),
      FailureMode(
        id: dishwasherCloggedSprayArmsId,
        label: 'Clogged spray arms or dirty filter',
        description:
            'Blocked spray holes or a dirty filter can leave dishes poorly '
            'cleaned even when the cycle runs.',
        commonality: FailureModeCommonality.common,
        safetyNotes: dishwasherBeginnerSafety,
      ),
      FailureMode(
        id: dishwasherDoorSealLeakId,
        label: 'Door seal drip or loose visible connection',
        description:
            'Water on the floor at the door is often food in the seal or a '
            'loose visible hose at the sink. Do not split a sealed tub.',
        commonality: FailureModeCommonality.common,
        safetyNotes: dishwasherBeginnerSafety,
      ),
      FailureMode(
        id: dishwasherDoorNotLatchedId,
        label: 'Door not fully latched',
        description:
            'The dishwasher will not start if the door is not closed firmly '
            'until it clicks. Do not bypass the door switch.',
        commonality: FailureModeCommonality.high,
        safetyNotes: dishwasherBeginnerSafety,
      ),
    ],
    symptoms: const [
      Symptom(
        id: 'standing-water',
        label: 'Standing water',
        description: 'Water remains in the tub after a cycle.',
      ),
      Symptom(
        id: 'wont-drain',
        label: "Won't drain",
        description: 'The cycle does not empty the tub.',
      ),
      Symptom(
        id: 'wont-fill',
        label: "Won't fill",
        description: 'Little or no water enters when a cycle starts.',
      ),
      Symptom(
        id: 'poor-clean',
        label: 'Poor clean',
        description: 'Dishes come out dirty or filmed after a full cycle.',
      ),
      Symptom(
        id: 'leaks',
        label: 'Leaks',
        description: 'Water appears on the floor at the door or under the sink.',
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
        id: dishwasherComplaintTemplateId,
        promptText: 'What is the dishwasher doing?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [
          dishwasherCloggedFilterId,
          dishwasherDrainPathId,
          dishwasherClosedSupplyId,
          dishwasherCloggedSprayArmsId,
          dishwasherDoorSealLeakId,
          dishwasherDoorNotLatchedId,
        ],
        answerChoices: const [
          'Standing water',
          "Won't drain",
          "Won't fill",
          'Poor clean',
          'Leaks',
          "Won't start",
          "Door won't close",
        ],
        supportByAnswer: const {
          'Standing water': [dishwasherCloggedFilterId],
          "Won't drain": [
            dishwasherDrainPathId,
            dishwasherCloggedFilterId,
          ],
          "Won't fill": [dishwasherClosedSupplyId],
          'Poor clean': [
            dishwasherCloggedSprayArmsId,
            dishwasherCloggedFilterId,
          ],
          'Leaks': [dishwasherDoorSealLeakId],
          "Won't start": [dishwasherDoorNotLatchedId],
          "Door won't close": [dishwasherDoorNotLatchedId],
        },
      ),
      EvidenceTemplate(
        id: 'dishwasher-door-click',
        promptText:
            'Does the door close firmly until you feel or hear a solid click?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [dishwasherDoorNotLatchedId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'No': [dishwasherDoorNotLatchedId],
        },
        excludeByAnswer: const {
          'Yes': [dishwasherDoorNotLatchedId],
        },
      ),
      EvidenceTemplate(
        id: 'dishwasher-filter-debris',
        promptText:
            'After unplugging, can you see food debris in the accessible '
            'filter at the bottom of the tub — without opening a sealed pump?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [
          dishwasherCloggedFilterId,
          dishwasherCloggedSprayArmsId,
        ],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [dishwasherCloggedFilterId, dishwasherCloggedSprayArmsId],
        },
        excludeByAnswer: const {
          'No': [dishwasherCloggedFilterId],
        },
      ),
      EvidenceTemplate(
        id: 'dishwasher-drain-hose',
        promptText:
            'Is the drain hose kinked, or is the air gap / disposal inlet '
            'blocked (without opening a sealed pump)?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [dishwasherDrainPathId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [dishwasherDrainPathId],
        },
        excludeByAnswer: const {
          'No': [dishwasherDrainPathId],
        },
      ),
      EvidenceTemplate(
        id: 'dishwasher-supply-open',
        promptText:
            'Is the under-sink dishwasher supply tap open, and is the air-gap '
            'cap clear of debris?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [dishwasherClosedSupplyId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'No': [dishwasherClosedSupplyId],
        },
        excludeByAnswer: const {
          'Yes': [dishwasherClosedSupplyId],
        },
      ),
      EvidenceTemplate(
        id: 'dishwasher-spray-holes',
        promptText:
            'Are the spray-arm holes clogged with food, or was the load packed '
            'so water could not reach the dishes?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [dishwasherCloggedSprayArmsId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [dishwasherCloggedSprayArmsId],
        },
        excludeByAnswer: const {
          'No': [dishwasherCloggedSprayArmsId],
        },
      ),
      EvidenceTemplate(
        id: 'dishwasher-door-seal-leak',
        promptText:
            'Is the leak at the door seal, or at a visible hose under the sink?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [dishwasherDoorSealLeakId],
        answerChoices: const [
          'Door seal',
          'Under the sink',
          'Not leaking',
          'Not sure',
        ],
        supportByAnswer: const {
          'Door seal': [dishwasherDoorSealLeakId],
          'Under the sink': [dishwasherDoorSealLeakId],
        },
        excludeByAnswer: const {
          'Not leaking': [dishwasherDoorSealLeakId],
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
        id: 'dishwasher-unplug-first',
        label: 'Unplug before filter or hose checks',
        description:
            'Unplug the dishwasher (or switch off its breaker) before '
            'removing the tub filter or moving the unit to inspect the hose.',
        requiredTools: const [],
        safetyLevel: 'beginner',
      ),
      SafeCheck(
        id: 'dishwasher-no-sealed-pump',
        label: 'Do not open a sealed pump or motor',
        description:
            'Stay with the accessible filter, spray arms, door latch, and '
            'visible drain hose. Do not split a sealed pump housing.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
      SafeCheck(
        id: 'dishwasher-no-live-electrical',
        label: 'No live electrical work',
        description:
            'Do not test live voltage, probe wiring, or work in an energized '
            'control box.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
      SafeCheck(
        id: 'dishwasher-no-gas-or-sealed',
        label: 'No gas or sealed-system work',
        description:
            'Do not work on gas lines or any sealed refrigerant system. This '
            'guide is dishwasher plumbing and accessible parts only.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
    ],
  );
}
