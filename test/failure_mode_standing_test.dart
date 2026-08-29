import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  Evidence evidence({
    required String templateId,
    required String observation,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: observation,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 7, 22),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  test('drum Yes weakens belt/motor; heat No supports no-heat modes', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        evidence(
          templateId: 'drum-turns',
          observation: 'Does the drum turn during the cycle?',
          answer: 'Turns normally',
        ),
        evidence(
          templateId: 'heat-observed',
          observation:
              'Is there any warmth after the dryer has run briefly?',
          answer: 'No warmth',
        ),
      ],
    );

    expect(standings['broken-drive-belt']!.isWeakened, isTrue);
    expect(standings['motor-failure']!.isWeakened, isTrue);
    expect(standings['heating-element-failed']!.isSupported, isTrue);
    expect(standings['thermal-fuse-open']!.isSupported, isTrue);
    expect(
      standings['electric-supply-connection-fault']!.isSupported,
      isTrue,
    );
    expect(standings['heating-element-failed']!.rankLabelText, 'Possible');
    expect(clearLeaderFailureModeId(standings: standings), isNull);

    final ordered = orderFailureModesByStanding(
      failureModes: package.failureModes,
      standings: standings,
    );
    final topIds = ordered.take(3).map((mode) => mode.id).toSet();
    expect(
      topIds.any(
        (id) =>
            id == 'thermal-fuse-open' ||
            id == 'heating-element-failed',
      ),
      isTrue,
    );
    expect(topIds.contains('relay-or-control-no-heat-output'), isFalse);
    expect(topIds.contains('broken-drive-belt'), isFalse);
  });
}
