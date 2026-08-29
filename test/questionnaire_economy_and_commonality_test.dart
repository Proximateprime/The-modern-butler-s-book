import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  const ranking = RankingService();

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-${answer.hashCode}',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: templateId,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 8, 5),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('commonality ranking', () {
    test(
      'tied no-heat nets rank thermal fuse above element via veryHigh commonality',
      () {
        final recorded = [
          evidence(templateId: 'drum-turns', answer: 'Turns normally'),
          evidence(templateId: 'heat-observed', answer: 'No warmth'),
          evidence(
            templateId: 'cycle-heat-setting',
            answer: 'Yes, heat cycle',
          ),
        ];
        final standings = evaluateFailureModeStandings(
          package: package,
          evidence: recorded,
        );
        expect(standings['thermal-fuse-open']!.net, standings['heating-element-failed']!.net);

        final ordered = orderFailureModesByStanding(
          failureModes: package.failureModes,
          standings: standings,
        );
        final fuseIndex = ordered.indexWhere((m) => m.id == 'thermal-fuse-open');
        final elementIndex =
            ordered.indexWhere((m) => m.id == 'heating-element-failed');
        expect(fuseIndex, lessThan(elementIndex));

        expect(
          clearLeaderFailureModeId(
            standings: standings,
            commonalityByModeId: {
              for (final mode in package.failureModes) mode.id: mode.commonality,
            },
          ),
          'thermal-fuse-open',
        );
      },
    );

    test(
      'overheat + weak vent path still favors thermal fuse over heating element',
      () {
        final snapshot = ranking.evaluate(
          package: package,
          evidence: [
            evidence(templateId: 'drum-turns', answer: 'Turns normally'),
            evidence(templateId: 'heat-observed', answer: 'No warmth'),
            evidence(
              templateId: 'cycle-heat-setting',
              answer: 'Yes, heat cycle',
            ),
            evidence(
              templateId: 'recent-overheat',
              answer: recentOverheatYesAnswer,
            ),
            evidence(templateId: 'exterior-airflow', answer: 'Weak'),
          ],
        );

        expect(
          snapshot.standings['thermal-fuse-open']!.net,
          greaterThan(snapshot.standings['heating-element-failed']!.net),
        );
        expect(
          snapshot.orderedFailureModes.first.id,
          isNot('heating-element-failed'),
        );
      },
    );

    test(
      'RankingService treats starter No heat like no warmth for fuse vs element tie',
      () {
        final snapshot = ranking.evaluate(
          package: package,
          evidence: [
            Evidence(
              id: 'e-starter',
              sessionId: 'session-1',
              applianceId: 'appliance-1',
              type: EvidenceType.textObservation,
              observation: "What's going on with the dryer?",
              answer: 'No heat',
              templateId: problemStarterComplaintTemplateId,
              collectedAt: DateTime.utc(2026, 8, 5),
              collectedInState: RepairSessionState.evidenceCollection,
              source: EvidenceSource.user,
              schemaVersion: '1.0',
            ),
            evidence(templateId: 'drum-turns', answer: 'Turns normally'),
            evidence(
              templateId: 'cycle-heat-setting',
              answer: 'Yes, heat cycle',
            ),
          ],
        );
        expect(
          snapshot.standings['thermal-fuse-open']!.net,
          snapshot.standings['heating-element-failed']!.net,
        );
        expect(snapshot.clearLeaderFailureModeId, 'thermal-fuse-open');
        expect(
          snapshot.orderedFailureModes.first.id,
          'thermal-fuse-open',
        );
      },
    );
  });

  group('question economy', () {
    test('starter no-heat complaint schedules discriminator, not heat-observed', () {
      final recorded = [
        Evidence(
          id: 'e-starter',
          sessionId: 'session-1',
          applianceId: 'appliance-1',
          type: EvidenceType.textObservation,
          observation: "What's going on with the dryer?",
          answer: 'No heat',
          templateId: problemStarterComplaintTemplateId,
          collectedAt: DateTime.utc(2026, 8, 5),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ];
      final next = starterInterviewTemplate(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        firstTemplateId: 'cycle-heat-setting',
        starterMatchedSymptomIds: {'no-heat'},
        energySource: ApplianceEnergySource.electric,
      );
      expect(next?.id, isNot('heat-observed'));
      expect(
        next?.id,
        anyOf(
          'lint-filter-condition',
          'exterior-airflow',
          'dry-time-change',
          'recent-overheat',
          'cycle-heat-setting',
          'drum-turns',
          'clothes-feel-after-cycle',
        ),
      );
    });

    test('no-heat established boosts airflow / dry-time / overheat discriminators', () {
      final recorded = [
        Evidence(
          id: 'e-starter',
          sessionId: 'session-1',
          applianceId: 'appliance-1',
          type: EvidenceType.textObservation,
          observation: "What's going on with the dryer?",
          answer: 'No heat',
          templateId: problemStarterComplaintTemplateId,
          collectedAt: DateTime.utc(2026, 8, 5),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ];
      final next = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        energySource: ApplianceEnergySource.electric,
      );
      expect(next?.id, isNot('heat-observed'));
      expect(
        next?.id,
        anyOf(
          'lint-filter-condition',
          'exterior-airflow',
          'dry-time-change',
          'recent-overheat',
          'cycle-heat-setting',
          'drum-turns',
          'clothes-feel-after-cycle',
        ),
      );
    });

    test('does not re-ask heat-observed when no warmth is already known', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(
          templateId: 'cycle-heat-setting',
          answer: 'Yes, heat cycle',
        ),
      ];
      final next = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        topFailureModeIds: ranking
            .evaluate(package: package, evidence: recorded)
            .topFailureModeIds,
        energySource: ApplianceEnergySource.electric,
      );
      expect(next?.id, isNot('heat-observed'));
    });

    test('prefers lint filter then airflow when no heat and drum turns are known', () {
      final recorded = [
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(
          templateId: 'cycle-heat-setting',
          answer: 'Yes, heat cycle',
        ),
      ];
      final topIds =
          ranking.evaluate(package: package, evidence: recorded).topFailureModeIds;
      final next = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        topFailureModeIds: topIds,
        energySource: ApplianceEnergySource.electric,
      );
      expect(next?.id, 'lint-filter-condition');
    });

    test('recent-overheat prompt uses simple heat language, not vent neglect chip', () {
      final template = package.evidenceTemplates.firstWhere(
        (t) => t.id == 'recent-overheat',
      );
      expect(template.promptText.toLowerCase(), isNot(contains('clogged vent')));
      expect(
        template.answerChoices,
        contains(recentOverheatYesAnswer),
      );
      expect(
        template.answerChoices,
        isNot(contains('Yes, recent overheat / vent neglect')),
      );
    });

    test('exterior-airflow prompt is a present-tense hand check', () {
      final template = package.evidenceTemplates.firstWhere(
        (t) => t.id == 'exterior-airflow',
      );
      expect(template.promptText.toLowerCase(), contains('outside vent'));
      expect(template.promptText.toLowerCase(), isNot(contains('clogged')));
    });
  });

  group('thermal fuse actionable guidance', () {
    test('safe guidance escalates; panel replace is Expert Mode only', () {
      clearImportedClosePaths();
      KnowledgePackageRepository().loadById('dryer-core');
      final path = closePathForFailureMode('thermal-fuse-open');
      expect(path, isNotNull);
      final beginner = path!.safeGuidanceSteps.join(' ').toLowerCase();

      expect(beginner, anyOf(contains('unplug'), contains('breaker')));
      expect(beginner, contains('technician'));
      expect(beginner, contains('vent'));
      expect(beginner, isNot(contains('heater service panel')));
      expect(
        path.expertOkSteps.join(' ').toLowerCase(),
        contains('heater service panel'),
      );
      expect(beginner, isNot(contains('is warmth restored after cleaning')));
    });
  });
}
