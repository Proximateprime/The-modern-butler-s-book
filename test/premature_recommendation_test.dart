import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  final commonalityById = {
    for (final mode in package.failureModes) mode.id: mode.commonality,
  };

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: templateId,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 7, 24),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('recommendPrimaryFailureModeId', () {
    test('does not recommend after 1–2 early answers', () {
      final one = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
      ];
      final two = [
        ...one,
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
      ];

      final standingsOne = evaluateFailureModeStandings(
        package: package,
        evidence: one,
      );
      final standingsTwo = evaluateFailureModeStandings(
        package: package,
        evidence: two,
      );

      expect(
        recommendPrimaryFailureModeId(
          standings: standingsOne,
          evidence: one,
          templates: package.evidenceTemplates,
        ),
        isNull,
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: standingsTwo,
          evidence: two,
          templates: package.evidenceTemplates,
        ),
        isNull,
      );
    });

    test('does not recommend with only generic early answers', () {
      final recorded = [
        evidence(templateId: 'dryer-response', answer: 'Starts normally'),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'panel-lights', answer: 'Yes, panel responds'),
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: recorded,
      );

      expect(
        countDiscriminatingInterviewAnswers(
          evidence: recorded,
          templates: package.evidenceTemplates,
        ),
        1,
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: standings,
          evidence: recorded,
          templates: package.evidenceTemplates,
        ),
        isNull,
      );
    });

    test('recommends thermal-fuse-open after enough discriminating overheat evidence', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(
          templateId: 'recent-overheat',
          answer: 'Yes, very hot or shut off from heat',
        ),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Cold and still damp',
        ),
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: recorded,
      );

      expect(
        recommendPrimaryFailureModeId(
          standings: standings,
          evidence: recorded,
          templates: package.evidenceTemplates,
          commonalityByModeId: commonalityById,
        ),
        'thermal-fuse-open',
      );
    });

    test('recommends heating-element after enough discriminating no-heat evidence', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(templateId: 'recent-overheat', answer: 'No'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Cold and still damp',
        ),
        evidence(
          templateId: 'wall-plug-seated',
          answer: 'Fully seated, looks normal',
        ),
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: recorded,
      );

      expect(
        recommendPrimaryFailureModeId(
          standings: standings,
          evidence: recorded,
          templates: package.evidenceTemplates,
          commonalityByModeId: commonalityById,
        ),
        'heating-element-failed',
      );
    });

    test('keeps interviewing when leader margin is weak', () {
      final standings = {
        'heating-element-failed': const FailureModeStanding(
          supportCount: 3,
          excludeCount: 0,
        ),
        'thermal-fuse-open': const FailureModeStanding(
          supportCount: 2,
          excludeCount: 0,
        ),
      };
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(templateId: 'recent-overheat', answer: 'No'),
        evidence(templateId: 'exterior-airflow', answer: 'Normal'),
      ];

      expect(clearLeaderFailureModeId(standings: standings), isNotNull);
      expect(
        recommendPrimaryFailureModeId(
          standings: standings,
          evidence: recorded,
          templates: package.evidenceTemplates,
        ),
        isNull,
      );
    });

    test('hazard answer still hard-stops immediately', () {
      final stop = evaluateSafetyStop(
        evidence: [
          evidence(templateId: 'hazard-observation', answer: 'Yes'),
        ],
      );
      expect(stop?.reason, 'Possible fire or smoke hazard');
    });
  });
}
