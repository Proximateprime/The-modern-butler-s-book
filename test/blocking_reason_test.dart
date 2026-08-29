import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/blocking_reason.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';

void main() {
  const screwdriver = RepairReadinessItem(
    id: 'screwdriver',
    label: 'Screwdriver',
    optional: false,
    liveElectrical: false,
  );
  const pan = RepairReadinessItem(
    id: 'shallow-pan',
    label: 'Shallow pan and towel',
    optional: false,
    liveElectrical: false,
  );

  test('tool gate names the missing tool in one sentence', () {
    expect(
      blockingReasonMissingTools(const [screwdriver]),
      'You need a screwdriver for the next steps.',
    );
    expect(
      blockingReasonMissingTools(const [pan]),
      'You need a shallow pan and towel for the next steps.',
    );
    expect(
      blockingReasonLine(
        safetyStop: false,
        phase: ClosePathPhase.tools,
        missingRequiredTools: const [screwdriver],
        toolsChecklistComplete: true,
        continueWithCaution: false,
        easyAirflowGateActive: false,
        easyAirflowSatisfied: false,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        currentGuidanceStep: null,
      ),
      'You need a screwdriver for the next steps.',
    );
    expect(
      blockingReasonLine(
        safetyStop: false,
        phase: ClosePathPhase.tools,
        missingRequiredTools: const [],
        toolsChecklistComplete: true,
        continueWithCaution: false,
        easyAirflowGateActive: false,
        easyAirflowSatisfied: false,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        currentGuidanceStep: null,
      ),
      isNull,
    );
  });

  test('incomplete inspect blocks skip into invasive guidance', () {
    expect(
      blockingReasonLine(
        safetyStop: false,
        phase: ClosePathPhase.inspect,
        missingRequiredTools: const [],
        toolsChecklistComplete: true,
        continueWithCaution: false,
        easyAirflowGateActive: false,
        easyAirflowSatisfied: false,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        hasIncompleteInspect: true,
        currentGuidanceStep: null,
      ),
      blockingReasonInspectIncompleteLine,
    );
    expect(
      blockingReasonLine(
        safetyStop: false,
        phase: ClosePathPhase.guidance,
        missingRequiredTools: const [],
        toolsChecklistComplete: true,
        continueWithCaution: false,
        easyAirflowGateActive: true,
        easyAirflowSatisfied: false,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        hasIncompleteInspect: true,
        currentGuidanceStep: 'Open the heater service panel.',
      ),
      blockingReasonInspectIncompleteLine,
    );
  });

  test('easy-check gate points at the next airflow check', () {
    expect(
      blockingReasonLine(
        safetyStop: false,
        phase: ClosePathPhase.guidance,
        missingRequiredTools: const [],
        toolsChecklistComplete: true,
        continueWithCaution: false,
        easyAirflowGateActive: true,
        easyAirflowSatisfied: false,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        currentGuidanceStep:
            'Check airflow before opening the cabinet. Go outside to the vent '
            'hood while the dryer runs.',
      ),
      'Next: check outside vent before opening the cabinet.',
    );
    expect(
      blockingReasonLine(
        safetyStop: false,
        phase: ClosePathPhase.guidance,
        missingRequiredTools: const [],
        toolsChecklistComplete: true,
        continueWithCaution: false,
        easyAirflowGateActive: true,
        easyAirflowSatisfied: true,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        currentGuidanceStep: 'Open the heater service panel.',
      ),
      isNull,
    );
  });

  test('safety stop uses a single non-blaming line', () {
    expect(
      blockingReasonLine(
        safetyStop: true,
        phase: ClosePathPhase.guidance,
        missingRequiredTools: const [screwdriver],
        toolsChecklistComplete: false,
        continueWithCaution: false,
        easyAirflowGateActive: true,
        easyAirflowSatisfied: false,
        washerEasyGateActive: false,
        washerEasySatisfied: false,
        currentGuidanceStep: null,
      ),
      blockingReasonSafetyLine,
    );
  });
}
