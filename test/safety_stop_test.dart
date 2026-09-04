import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';

void main() {
  Evidence evidence(String observation) {
    return Evidence(
      id: 'e-1',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.textObservation,
      observation: observation,
      collectedAt: DateTime.utc(2026, 7, 22),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  test('returns null when no safety condition is present', () {
    final stop = evaluateSafetyStop(
      evidence: [evidence('Does the drum turn during the cycle?')],
      primaryFailureModeId: 'restricted-exhaust-airflow',
    );

    expect(stop, isNull);
  });

  test('stops on gas-like odor answers', () {
    final stop = evaluateSafetyStop(
      evidence: [
        Evidence(
          id: 'e-1',
          sessionId: 'session-1',
          applianceId: 'appliance-1',
          type: EvidenceType.structuredAnswer,
          observation: 'What kind of smell?',
          answer: 'Gas-like odor',
          collectedAt: DateTime.utc(2026, 7, 22),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ],
    );

    expect(stop?.reason, 'Possible gas hazard');
  });

  test('stops on gas language in evidence', () {
    final stop = evaluateSafetyStop(
      evidence: [evidence('There is a gas smell near the dryer.')],
    );

    expect(stop?.reason, 'Possible gas hazard');
  });

  test('hazard-observation Other runs the gas matcher and does not skip', () {
    Evidence hazardOther(String answer) {
      return Evidence(
        id: 'e-h',
        sessionId: 'session-1',
        applianceId: 'appliance-1',
        type: EvidenceType.structuredAnswer,
        observation: 'Do you observe a burning smell or smoke?',
        answer: answer,
        templateId: 'hazard-observation',
        collectedAt: DateTime.utc(2026, 9, 4),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      );
    }

    expect(
      evaluateSafetyStop(
        evidence: [hazardOther('Other / describe: I smell gas')],
      )?.reason,
      'Possible gas hazard',
    );
    expect(
      evaluateSafetyStop(
        evidence: [hazardOther('Other / describe: gas leak by the valve')],
      )?.reason,
      'Possible gas hazard',
    );
    expect(
      evaluateSafetyStop(
        evidence: [hazardOther('Other / describe: propane odor')],
      )?.reason,
      'Possible gas hazard',
    );
    expect(
      evaluateSafetyStop(evidence: [hazardOther('No')]),
      isNull,
    );
  });

  test('stops on burning or smoke language in evidence', () {
    final stop = evaluateSafetyStop(
      evidence: [
        evidence(
          'Do you observe a burning smell or smoke?',
        ),
      ],
    );

    expect(stop?.reason, 'Possible fire or smoke hazard');
  });

  test('stops on live electrical language in evidence', () {
    final stop = evaluateSafetyStop(
      evidence: [evidence('I measured live voltage at the terminal.')],
    );

    expect(stop?.reason, 'Requires professional electrical work');
  });

  test('gated professional Primary is not a hazard hard-stop', () {
    expect(
      evaluateSafetyStop(
        evidence: const [],
        primaryFailureModeId: 'electric-supply-connection-fault',
      ),
      isNull,
    );
    expect(
      evaluateSafetyStop(
        evidence: const [],
        primaryFailureModeId: 'motor-failure',
      ),
      isNull,
    );
  });

  test('electrical-burning-smell-hazard Primary remains a hard stop', () {
    final stop = evaluateSafetyStop(
      evidence: const [],
      primaryFailureModeId: 'electrical-burning-smell-hazard',
    );

    expect(stop?.reason, 'Possible fire or smoke hazard');
  });

  test('sessionSafetyLevelFor emits professional for gated FMs, stop for hard stop', () {
    expect(
      sessionSafetyLevelFor(
        evidence: const [],
        primaryFailureModeId: 'thermal-fuse-open',
      ),
      'professional',
    );
    expect(
      sessionSafetyLevelFor(
        evidence: const [],
        primaryFailureModeId: 'electric-supply-connection-fault',
      ),
      'professional',
    );
    expect(
      sessionSafetyLevelFor(
        evidence: const [],
        primaryFailureModeId: 'motor-failure',
      ),
      'professional',
    );
    expect(
      sessionSafetyLevelFor(
        evidence: const [],
        primaryFailureModeId: 'electrical-burning-smell-hazard',
      ),
      'stop',
    );
    expect(
      sessionSafetyLevelFor(
        evidence: const [],
        primaryFailureModeId: 'restricted-exhaust-airflow',
      ),
      'clear',
    );
    expect(
      sessionSafetyLevelFor(
        evidence: [evidence('There is a burning smell near the dryer.')],
        primaryFailureModeId: 'thermal-fuse-open',
      ),
      'stop',
    );
  });

  test('thermal-fuse-open Primary is not a hazard hard-stop', () {
    final stop = evaluateSafetyStop(
      evidence: const [],
      primaryFailureModeId: 'thermal-fuse-open',
    );

    expect(stop, isNull);
  });

  test('heating-element-failed Primary is not a hazard hard-stop', () {
    final stop = evaluateSafetyStop(
      evidence: const [],
      primaryFailureModeId: 'heating-element-failed',
    );

    expect(stop, isNull);
  });
}
