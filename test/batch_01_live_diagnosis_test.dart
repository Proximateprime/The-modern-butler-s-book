import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/observation_prompt_quality.dart';
import 'package:modern_butlers_book/helpers/package_authoring_index.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_batch_01.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_batch_02.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_batch_importer.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  final authoringIndex = PackageAuthoringIndex.fromPackage(
    package,
    records: [
      ...const FailureModeBatchImporter().parseBatchJson(dryerBatch01Json),
      ...const FailureModeBatchImporter().parseBatchJson(dryerBatch02Json),
    ],
  );
  const reasoning = DiagnosticReasoning();

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

  group('Batch 01 live diagnosis', () {
    test('support-hit: air-fluff cycle answer supports Batch 01 mode', () {
      final recorded = [
        evidence(
          templateId: 'cycle-heat-setting',
          answer: 'No, air-only / fluff',
        ),
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: recorded,
      );

      expect(standings['air-fluff-cycle-selected']!.isSupported, isTrue);
      expect(standings['heating-element-failed']!.isWeakened, isTrue);
      expect(standings['thermal-fuse-open']!.isWeakened, isTrue);
    });

    test('exclude-hit: heat cycle answer excludes air-fluff leader', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: recorded,
      );

      expect(standings['air-fluff-cycle-selected']!.isWeakened, isTrue);
      expect(standings['heating-element-failed']!.isSupported, isTrue);
      expect(standings['thermal-fuse-open']!.isSupported, isTrue);
    });

    test('no-heat path prefers heat/airflow Batch 01 modes in top set', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
      ];
      final result = reasoning.evaluate(
        package: package,
        evidence: recorded,
        authoringIndex: authoringIndex,
      );

      expect(
        result.topFailureModeIds,
        anyElement(
          anyOf(
            'heating-element-failed',
            'thermal-fuse-open',
            'restricted-exhaust-airflow',
            'high-limit-thermostat-open',
          ),
        ),
      );
      expect(result.topFailureModeIds, isNot(contains('air-fluff-cycle-selected')));
    });

    test('authoring index boosts useful observations for top modes', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
      ];
      final ranked = reasoning.evaluate(
        package: package,
        evidence: recorded,
        authoringIndex: authoringIndex,
      );
      final next = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        topFailureModeIds: ranked.topFailureModeIds,
        authoringIndex: authoringIndex,
        energySource: ApplianceEnergySource.electric,
      );

      expect(
        next?.id,
        isIn([
          'drum-turns',
          'lint-filter-condition',
          'exterior-airflow',
          'recent-overheat',
          'clothes-feel-after-cycle',
        ]),
      );
    });

    test('Batch 01 symptom phrasing activates heat family for interview', () {
      final families = inferActiveObservationFamilies(
        recordedEvidence: [
          evidence(
            templateId: problemStarterComplaintTemplateId,
            answer: 'only cold air after fluff cycle',
          ),
        ],
        templates: package.evidenceTemplates,
        authoringIndex: authoringIndex,
      );

      expect(families, contains(ObservationFamily.heat));
    });

    test('root cause registry still resolves Batch 01 thermal fuse mode', () {
      final summary = FailureModeAuthoringRegistry.lookup('thermal-fuse-open');
      expect(summary, isNotNull);
      expect(summary!.rootCause, isNotEmpty);
      expect(summary.preventionActions, isNotEmpty);
    });

    test('hazard mode still hard-stops immediately', () {
      final stop = evaluateSafetyStop(
        evidence: [
          evidence(templateId: 'hazard-observation', answer: 'Yes'),
        ],
      );
      expect(stop?.reason, 'Possible fire or smoke hazard');
    });

    test('repository exposes authoring index for dryer-core', () {
      final index =
          KnowledgePackageRepository().authoringIndexFor('dryer-core');
      expect(index, isNotNull);
      expect(
        index!.supportTemplatesFor('restricted-exhaust-airflow'),
        contains('exterior-airflow'),
      );
      expect(
        index.observationFamiliesFor('restricted-exhaust-airflow'),
        contains(ObservationFamily.airflow),
      );
    });
  });
}
