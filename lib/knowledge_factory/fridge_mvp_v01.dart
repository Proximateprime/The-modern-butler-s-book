import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'fridge_inspect_steps.dart';

/// Fridge v1 — beginner-safe. Never sealed-system, refrigerant, compressor
/// live diagnostics, or piercing lines.
const String fridgePackageId = 'fridge-core';
const String fridgePackageVersion = '1.0.1';

const String fridgeBlockedCoilsId = 'blocked-fridge-coils-or-airflow';
const String fridgeBlockedInternalVentsId = 'blocked-fridge-internal-vents';
const String fridgeDoorGasketId = 'fridge-door-gasket-or-ajar';
const String fridgeTempControlsId = 'fridge-temp-controls-set-wrong';
const String fridgeCloggedDefrostDrainId = 'clogged-fridge-defrost-drain';
const String fridgeIceMakerSupplyId = 'ice-maker-supply-or-switch';
const String fridgeIceBinJamId = 'fridge-ice-bin-or-dispenser-jam';
const String fridgeUnlevelVibrationId = 'fridge-unlevel-or-vibration';
const String fridgeNoPowerId = 'fridge-no-power-or-control';

const String fridgeComplaintTemplateId = 'fridge-complaint';

const String fridgeBeginnerSafety =
    'Beginner-safe only: unplug first. Do not open the sealed cooling system. '
    'Do not add, recover, or handle refrigerant. Do not pierce, cut, or '
    'puncture cooling tubes. No live electrical testing. No compressor live '
    'diagnostics.';

KnowledgePackage buildFridgeMvpPackage() {
  return KnowledgePackage(
    id: fridgePackageId,
    category: 'fridge',
    version: fridgePackageVersion,
    displayName: 'Fridge Knowledge Package',
    schemaVersion: '1.0',
    createdAt: DateTime.utc(2026, 8, 19),
    source: 'Fridge Knowledge Package V1.0.1 — observational paths plus '
        'temps/gasket/vents/coils inspect before pulling the cabinet',
    status: KnowledgePackageStatus.production,
    inspectSteps: fridgePackageInspectSteps,
    failureModes: const [
      FailureMode(
        id: fridgeBlockedCoilsId,
        label: 'Dirty coils or blocked airflow around the fridge',
        description:
            'Dust on accessible condenser coils, or the cabinet packed tight '
            'to the wall, can leave food warmer than it should be.',
        commonality: FailureModeCommonality.veryHigh,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeBlockedInternalVentsId,
        label: 'Blocked internal air vents',
        description:
            'Food covering the vents between freezer and fridge can leave the '
            'fridge warm while the freezer still feels cold.',
        commonality: FailureModeCommonality.high,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeDoorGasketId,
        label: 'Door ajar or worn door seal',
        description:
            'A door that does not close, or a torn, dirty, or flattened gasket, '
            'lets warm air in. Frost at the opening is a common clue.',
        commonality: FailureModeCommonality.high,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeTempControlsId,
        label: 'Temperature controls set too warm or too cold',
        description:
            'A dial or digital setpoint on the wrong number can freeze lettuce '
            'or leave milk warm. This is a look-and-set check, not a sealed-'
            'system repair.',
        commonality: FailureModeCommonality.common,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeCloggedDefrostDrainId,
        label: 'Clogged defrost drain or drip pan',
        description:
            'A blocked user-accessible drain or a full drip pan can leave '
            'water on the floor or in the compartment.',
        commonality: FailureModeCommonality.high,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeIceMakerSupplyId,
        label: 'Ice maker off or water supply closed',
        description:
            'The ice maker switch may be off, or the accessible water tap or '
            'line behind the fridge may be closed or kinked.',
        commonality: FailureModeCommonality.high,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeIceBinJamId,
        label: 'Ice bin jammed or dispenser blocked',
        description:
            'Clumped ice in the bin or a visible jam at the dispenser can stop '
            'ice even when the maker is on. Do not dismantle the sealed ice '
            'maker body.',
        commonality: FailureModeCommonality.common,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeUnlevelVibrationId,
        label: 'Fridge not level or items rattling',
        description:
            'A rocking cabinet or bottles against the wall can sound loud. '
            'Ice dropping into the bin can be normal.',
        commonality: FailureModeCommonality.common,
        safetyNotes: fridgeBeginnerSafety,
      ),
      FailureMode(
        id: fridgeNoPowerId,
        label: 'No power or display off',
        description:
            'The fridge stays dark if the cord is unplugged or the breaker is '
            'off. Do not test live voltage or the compressor while it is live.',
        commonality: FailureModeCommonality.common,
        safetyNotes: fridgeBeginnerSafety,
      ),
    ],
    symptoms: const [
      Symptom(
        id: 'not-cooling',
        label: 'Not cooling',
        description: 'The fridge or freezer is warmer than it should be.',
      ),
      Symptom(
        id: 'fridge-warm-freezer-cold',
        label: 'Fridge warm, freezer cold',
        description:
            'The freezer still feels cold, but the fresh-food side is warm.',
      ),
      Symptom(
        id: 'too-cold',
        label: 'Too cold',
        description: 'Food in the fridge freezes, or drinks turn slushy.',
      ),
      Symptom(
        id: 'water-leak',
        label: 'Water leak',
        description: 'Water pools inside or on the floor.',
      ),
      Symptom(
        id: 'ice-maker',
        label: 'Ice maker',
        description: 'The ice maker is not making ice, or ice will not dispense.',
      ),
      Symptom(
        id: 'noisy',
        label: 'Noisy',
        description: 'The fridge rattles, hums loudly, or shakes.',
      ),
      Symptom(
        id: 'door-wont-close',
        label: "Door won't close",
        description: 'A door pops open, or the seal does not sit flat.',
      ),
      Symptom(
        id: 'wont-run',
        label: "Won't run",
        description: 'Lights, fans, or the display stay off.',
      ),
    ],
    evidenceTemplates: [
      EvidenceTemplate(
        id: fridgeComplaintTemplateId,
        promptText: 'What is the fridge doing?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [
          fridgeBlockedCoilsId,
          fridgeBlockedInternalVentsId,
          fridgeDoorGasketId,
          fridgeTempControlsId,
          fridgeCloggedDefrostDrainId,
          fridgeIceMakerSupplyId,
          fridgeIceBinJamId,
          fridgeUnlevelVibrationId,
          fridgeNoPowerId,
        ],
        answerChoices: const [
          'Not cooling',
          'Fridge warm, freezer cold',
          'Too cold',
          'Water leak',
          'Ice maker',
          'Noisy',
          "Door won't close",
          "Won't run",
        ],
        supportByAnswer: const {
          'Not cooling': [
            fridgeBlockedCoilsId,
            fridgeDoorGasketId,
            fridgeTempControlsId,
          ],
          'Fridge warm, freezer cold': [
            fridgeBlockedInternalVentsId,
            fridgeDoorGasketId,
          ],
          'Too cold': [fridgeTempControlsId],
          'Water leak': [fridgeCloggedDefrostDrainId],
          'Ice maker': [fridgeIceMakerSupplyId, fridgeIceBinJamId],
          'Noisy': [fridgeUnlevelVibrationId],
          "Door won't close": [fridgeDoorGasketId],
          "Won't run": [fridgeNoPowerId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-temps-or-settings',
        promptText:
            'Are the fridge and freezer temperature controls set to a normal '
            'mid-range (not the warmest or coldest stop)?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeTempControlsId],
        answerChoices: const ['Yes — mid-range', 'No — at an extreme', 'Not sure'],
        supportByAnswer: const {
          'No — at an extreme': [fridgeTempControlsId],
        },
        excludeByAnswer: const {
          'Yes — mid-range': [fridgeTempControlsId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-door-seal',
        promptText:
            'Does each door close fully, and does the gasket look clean, '
            'intact, and seated (no gaps, tears, or sticky food)?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeDoorGasketId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'No': [fridgeDoorGasketId],
        },
        excludeByAnswer: const {
          'Yes': [fridgeDoorGasketId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-internal-vents',
        promptText:
            'Are the air vents inside the fridge or freezer blocked by food '
            'or bins?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeBlockedInternalVentsId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [fridgeBlockedInternalVentsId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-coils-or-space',
        promptText:
            'After unplugging, can you see dust on accessible coils or a '
            'grille, or is the fridge packed tight against the wall?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeBlockedCoilsId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [fridgeBlockedCoilsId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-drain-or-pan',
        promptText:
            'Is water coming from the visible freezer drain, drip pan, or '
            'inside the compartment — not from a cut tube?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeCloggedDefrostDrainId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [fridgeCloggedDefrostDrainId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-ice-maker-supply',
        promptText:
            'Is the ice maker switched on, and is the water tap behind the '
            'fridge open with the accessible line unkinked?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeIceMakerSupplyId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'No': [fridgeIceMakerSupplyId],
        },
        excludeByAnswer: const {
          'Yes': [fridgeIceMakerSupplyId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-ice-bin-jam',
        promptText:
            'Is the ice in the bin clumped, or is the dispenser opening '
            'blocked by visible ice?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeIceBinJamId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [fridgeIceBinJamId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-level-or-rattle',
        promptText:
            'Is the fridge rocking, or are bottles and pans rattling against '
            'the cabinet or wall?',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeUnlevelVibrationId],
        answerChoices: const ['Yes', 'No', 'Not sure'],
        supportByAnswer: const {
          'Yes': [fridgeUnlevelVibrationId],
        },
      ),
      EvidenceTemplate(
        id: 'fridge-power-or-plug',
        promptText:
            'Is the fridge plugged in, and is the breaker on? Do not test '
            'live voltage or the compressor while it is live.',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [fridgeNoPowerId],
        answerChoices: const [
          'Yes — looks powered',
          'No — unplugged or breaker off',
          'Not sure',
        ],
        supportByAnswer: const {
          'No — unplugged or breaker off': [fridgeNoPowerId],
        },
        excludeByAnswer: const {
          'Yes — looks powered': [fridgeNoPowerId],
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
        id: 'fridge-unplug-first',
        label: 'Unplug before moving or cleaning coils',
        description:
            'Unplug the fridge (or switch off its breaker) before pulling it '
            'out or touching accessible coils or a drip pan.',
        requiredTools: const [],
        safetyLevel: 'beginner',
      ),
      SafeCheck(
        id: 'fridge-no-sealed-system',
        label: 'Do not open the sealed cooling system',
        description:
            'Never open, cut, or puncture cooling tubes, the compressor, or '
            'any sealed refrigerant circuit. Do not add, recover, or handle '
            'refrigerant. Do not pierce lines.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
      SafeCheck(
        id: 'fridge-no-live-electrical',
        label: 'No live electrical work',
        description:
            'Do not test live voltage, probe wiring, or work in an energized '
            'control box. Do not do compressor live diagnostics.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
      SafeCheck(
        id: 'fridge-no-compressor-live',
        label: 'No compressor live diagnostics',
        description:
            'Do not test the compressor, start relay, or windings while the '
            'fridge is energized. Call a technician if you suspect compressor '
            'failure.',
        requiredTools: const [],
        safetyLevel: 'stop',
      ),
    ],
  );
}
