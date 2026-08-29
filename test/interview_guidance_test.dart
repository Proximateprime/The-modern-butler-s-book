import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/observation_prompt_quality.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  group('observation prompt quality', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;

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

    test('no-heat path deprioritizes noise prompt early', () {
      final active = inferActiveObservationFamilies(
        recordedEvidence: [
          evidence(templateId: 'heat-observed', answer: 'No warmth'),
        ],
        templates: package.evidenceTemplates,
      );
      expect(active, contains(ObservationFamily.heat));

      final noiseScore = scoreObservationPrompt(
        template: package.evidenceTemplates.firstWhere(
          (t) => t.id == 'running-noise',
        ),
        activeFamilies: active,
        topFailureModeIds: const ['heating-element-failed'],
        recordedCount: 1,
        packageIndex: 0,
      );
      final heatScore = scoreObservationPrompt(
        template: package.evidenceTemplates.firstWhere(
          (t) => t.id == 'cycle-heat-setting',
        ),
        activeFamilies: active,
        topFailureModeIds: const ['heating-element-failed'],
        recordedCount: 1,
        packageIndex: 1,
      );
      expect(heatScore, greaterThan(noiseScore));
    });

    test('won’t-start path keeps start-family prompts on topic', () {
      final active = inferActiveObservationFamilies(
        recordedEvidence: [
          evidence(templateId: 'dryer-response', answer: 'Nothing happens'),
        ],
        templates: package.evidenceTemplates,
      );
      expect(active, contains(ObservationFamily.start));
      expect(active, isNot(contains(ObservationFamily.noise)));
    });
  });

  group('guidance display', () {
    test('observation guidance includes how and stop guidance', () {
      final block = observationGuidanceForTemplate('heat-observed');
      expect(block, isNotNull);
      expect(block!.what, isNotEmpty);
      expect(block.how, isNotEmpty);
      expect(block.whenToStop, isNotEmpty);
    });

    test('clothes-feel copy uses when you took clothes out, not cycle-end open', () {
      final package = KnowledgePackageRepository().loadById('dryer-core')!;
      final template = package.evidenceTemplates.firstWhere(
        (item) => item.id == 'clothes-feel-after-cycle',
      );
      expect(template.promptText.toLowerCase(), contains('when you took'));
      expect(template.promptText.toLowerCase(), isNot(contains('open the drum')));

      final block = observationGuidanceForTemplate('clothes-feel-after-cycle');
      expect(block, isNotNull);
      expect(block!.how.toLowerCase(), contains('when you took'));
      expect(block.how.toLowerCase(), contains('not the instant'));
      expect(block.how.toLowerCase(), isNot(contains('open the drum')));
    });

    test('safe step guidance never returns bare one-liner only', () {
      final block = guidanceForSafeStep('Clean the lint filter.');
      expect(block.what, isNotEmpty);
      expect(block.how, contains('lint'));
      expect(block.resultMeans, isNotEmpty);
      expect(block.whenToStop, isNotEmpty);
    });
  });

  group('authoring registry', () {
    test('thermal fuse has root cause insight', () {
      final insight = FailureModeAuthoringRegistry.lookup('thermal-fuse-open');
      expect(insight, isNotNull);
      expect(insight!.rootCause, contains('overheating'));
      expect(insight.preventionActions, isNotEmpty);
      expect(insight.hasRootCauseInsight, isTrue);
    });

    test('unknown mode returns null quietly', () {
      expect(FailureModeAuthoringRegistry.lookup('missing-mode'), isNull);
    });
  });
}
