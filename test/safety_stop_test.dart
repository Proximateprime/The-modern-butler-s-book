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

  test('stops on burning or smoke language in evidence', () {
    final stop = evaluateSafetyStop(
      evidence: [
        evidence(
          'Do you observe a burning smell, smoke, or repeated stopping?',
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

  test('stops when primary hypothesis requires a professional', () {
    final stop = evaluateSafetyStop(
      evidence: const [],
      primaryFailureModeId: 'electric-supply-connection-fault',
    );

    expect(stop?.reason, 'Requires professional electrical work');
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
