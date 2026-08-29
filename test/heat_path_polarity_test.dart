import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/power_steering.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  const ranking = RankingService();
  const reasoning = DiagnosticReasoning();

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
      collectedAt: DateTime.utc(2026, 8, 12),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  Evidence starter(String answer) {
    return Evidence(
      id: 'e-starter',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.textObservation,
      observation: "What's going on with the dryer?",
      answer: answer,
      templateId: problemStarterComplaintTemplateId,
      collectedAt: DateTime.utc(2026, 8, 12),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('heat path polarity', () {
    test('too-hot starter is excess_heat, not no_heat', () {
      final recorded = [starter('Clothes way too hot')];
      expect(
        inferHeatPathPolarity(recordedEvidence: recorded),
        HeatPathPolarity.excessHeat,
      );
      expect(
        isNoHeatEstablished(recordedEvidence: recorded, templates: const []),
        isFalse,
      );
    });

    test('no-heat starter stays no_heat even after overheat history', () {
      final recorded = [
        starter('No heat'),
        evidence(templateId: 'recent-overheat', answer: recentOverheatYesAnswer),
      ];
      expect(
        inferHeatPathPolarity(recordedEvidence: recorded),
        HeatPathPolarity.noHeat,
      );
    });

    test('excess-heat start does not schedule warmth re-ask or overheat loop', () {
      final recorded = [starter('Clothes way too hot')];
      final next = starterInterviewTemplate(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        firstTemplateId: 'lint-filter-condition',
        starterMatchedSymptomIds: {'dryer-very-hot'},
      );
      expect(next?.id, isNot('heat-observed'));
      expect(next?.id, isNot('recent-overheat'));
      expect(
        next?.id,
        anyOf(
          'exterior-airflow',
          'dry-time-change',
          'clothes-feel-after-cycle',
          'lint-filter-condition',
          'vent-hose-condition',
        ),
      );
    });

    test('excess-heat path schedules exterior airflow as a discriminator', () {
      final recorded = [
        starter('Runs too hot'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Warm or hot but still damp',
        ),
      ];
      final next = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
      );
      expect(next?.id, isNot('heat-observed'));
      expect(
        next?.id,
        anyOf('exterior-airflow', 'dry-time-change', 'lint-filter-condition'),
      );
    });

    test('maps too-hot free text to dryer-very-hot and airflow first question', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: const {},
        freeText: 'clothes way too hot',
      );
      expect(result.matchedSymptomIds, contains('dryer-very-hot'));
      expect(result.firstTemplateId, 'lint-filter-condition');
    });

    test('excess-heat clothes-feel chips include dry but unusually hot', () {
      final template = package.evidenceTemplates.firstWhere(
        (item) => item.id == 'clothes-feel-after-cycle',
      );
      expect(template.answerChoices, contains(clothesFeelDryUnusuallyHotAnswer));
      expect(
        inferHeatPathPolarity(
          recordedEvidence: [
            starter('Clothes way too hot'),
            evidence(
              templateId: 'clothes-feel-after-cycle',
              answer: clothesFeelDryUnusuallyHotAnswer,
            ),
          ],
        ),
        HeatPathPolarity.excessHeat,
      );
      expect(
        noHeatFailureModeIds.contains(
          ranking
              .evaluate(
                package: package,
                evidence: [
                  starter('Clothes way too hot'),
                  evidence(
                    templateId: 'clothes-feel-after-cycle',
                    answer: clothesFeelDryUnusuallyHotAnswer,
                  ),
                ],
              )
              .orderedFailureModes
              .first
              .id,
        ),
        isFalse,
      );
    });
  });

  group('excess-heat ranking and close path', () {
    test('too-hot + weak airflow does not bind no-heat fuse verification', () {
      clearImportedClosePaths();
      KnowledgePackageRepository().loadById('dryer-core');
      final recorded = [
        starter('Clothes way too hot'),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(
          templateId: 'recent-overheat',
          answer: recentOverheatYesAnswer,
        ),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Warm or hot but still damp',
        ),
      ];
      final snapshot = ranking.evaluate(package: package, evidence: recorded);
      expect(
        snapshot.orderedFailureModes.first.id,
        isNot('heating-element-failed'),
      );
      expect(
        noHeatFailureModeIds.contains(snapshot.orderedFailureModes.first.id),
        isFalse,
      );

      final result = reasoning.evaluate(package: package, evidence: recorded);
      expect(result.closePath, isNotNull);
      expect(result.closePath!.failureModeId, isNot('thermal-fuse-open'));
      expect(result.closePath!.failureModeId, isNot('heating-element-failed'));
      final ask = result.closePath!.verificationAsk.toLowerCase();
      expect(ask, isNot(contains('still no warmth')));
      expect(
        ask,
        anyOf(
          contains('airflow'),
          contains('vent'),
          contains('dry'),
          contains('hot'),
        ),
      );
    });

    test(
      'no-heat answering No to unusually hot does not alone crown heating element',
      () {
        final recorded = [
          starter('No heat'),
          evidence(templateId: 'recent-overheat', answer: 'No'),
        ];
        final snapshot = ranking.evaluate(package: package, evidence: recorded);
        expect(snapshot.clearLeaderFailureModeId, isNot('heating-element-failed'));
        expect(snapshot.recommendPrimaryFailureModeId, isNull);
      },
    );

    test('no-heat + overheat history still uses fuse still-no-warmth verify', () {
      clearImportedClosePaths();
      KnowledgePackageRepository().loadById('dryer-core');
      final recorded = [
        starter('No heat'),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(
          templateId: 'recent-overheat',
          answer: recentOverheatYesAnswer,
        ),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Cold and still damp',
        ),
      ];
      final result = reasoning.evaluate(package: package, evidence: recorded);
      expect(result.closePath?.failureModeId, 'thermal-fuse-open');
      expect(
        result.closePath!.verificationAsk.toLowerCase(),
        contains('still no warmth'),
      );
    });
  });
}
