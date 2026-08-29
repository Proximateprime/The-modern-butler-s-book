import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  const reasoning = DiagnosticReasoning();

  Evidence evidence({
    required String templateId,
    required String observation,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-$answer',
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

  group('Path 1 — no-heat golden path', () {
    test('drum turns + no warmth elevates heat modes', () {
      final result = reasoning.evaluate(
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

      expect(result.standings['broken-drive-belt']!.isWeakened, isTrue);
      expect(result.standings['heating-element-failed']!.isSupported, isTrue);
      expect(result.standings['thermal-fuse-open']!.isSupported, isTrue);
      expect(
        result.orderedFailureModes.take(8).any(
          (mode) => mode.id == 'heating-element-failed',
        ),
        isTrue,
      );
    });

    test('primary heat mode surfaces close verification pending', () {
      final result = reasoning.evaluate(
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
        primaryFailureModeId: 'heating-element-failed',
      );

      expect(result.closePath, isNotNull);
      expect(result.verificationOutcome, VerificationOutcome.pending);
      expect(result.canResolveAsFixed, isFalse);
      expect(
        result.resolveEligibility,
        CloseResolveEligibility.pendingVerification,
      );
      expect(result.closePath!.safeGuidanceSteps, isNotEmpty);
    });

    test('verification Confirmed on heating-element still needs a professional', () {
      final result = reasoning.evaluate(
        package: package,
        evidence: [
          evidence(
            templateId: 'heat-observed',
            observation:
                'Is there any warmth after the dryer has run briefly?',
            answer: 'No warmth',
          ),
          evidence(
            templateId: closeVerificationTemplateId('heating-element-failed'),
            observation: closePathForFailureMode(
              'heating-element-failed',
            )!.verificationAsk,
            answer: 'Confirmed',
          ),
        ],
        primaryFailureModeId: 'heating-element-failed',
      );

      expect(result.verificationOutcome, VerificationOutcome.supported);
      expect(result.canResolveAsFixed, isFalse);
      expect(
        result.resolveEligibility,
        CloseResolveEligibility.needsProfessional,
      );
    });

    test('verification Not confirmed does not allow Resolved', () {
      final result = reasoning.evaluate(
        package: package,
        evidence: [
          evidence(
            templateId: 'heat-observed',
            observation:
                'Is there any warmth after the dryer has run briefly?',
            answer: 'No warmth',
          ),
          evidence(
            templateId: closeVerificationTemplateId('heating-element-failed'),
            observation: closePathForFailureMode(
              'heating-element-failed',
            )!.verificationAsk,
            answer: 'Not confirmed',
          ),
        ],
        primaryFailureModeId: 'heating-element-failed',
      );

      expect(result.verificationOutcome, VerificationOutcome.contradicted);
      expect(result.canResolveAsFixed, isFalse);
      expect(
        result.resolveEligibility,
        CloseResolveEligibility.needsProfessional,
      );
    });
  });

  group('Path 2 — vent restriction', () {
    test('damp + weak airflow elevates restricted vent and close path works', () {
      final before = reasoning.evaluate(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-remain-damp',
            observation: 'After a full cycle, are the clothes still damp?',
            answer: 'Still damp',
          ),
          evidence(
            templateId: 'exterior-airflow',
            observation: 'Is exterior vent airflow weak?',
            answer: 'Weak',
          ),
        ],
      );
      expect(
        before.standings['restricted-exhaust-airflow']!.isSupported,
        isTrue,
      );

      final pending = reasoning.evaluate(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-remain-damp',
            observation: 'After a full cycle, are the clothes still damp?',
            answer: 'Still damp',
          ),
          evidence(
            templateId: 'exterior-airflow',
            observation: 'Is exterior vent airflow weak?',
            answer: 'Weak',
          ),
        ],
        primaryFailureModeId: 'restricted-exhaust-airflow',
      );
      expect(pending.verificationOutcome, VerificationOutcome.pending);
      expect(pending.closePath!.safeGuidanceSteps.first.toLowerCase(), contains('lint filter'));

      final confirmed = reasoning.evaluate(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-remain-damp',
            observation: 'After a full cycle, are the clothes still damp?',
            answer: 'Still damp',
          ),
          evidence(
            templateId: 'exterior-airflow',
            observation: 'Is exterior vent airflow weak?',
            answer: 'Weak',
          ),
          evidence(
            templateId: closeVerificationTemplateId(
              'restricted-exhaust-airflow',
            ),
            observation: closePathForFailureMode(
              'restricted-exhaust-airflow',
            )!.verificationAsk,
            answer: 'Confirmed',
          ),
        ],
        primaryFailureModeId: 'restricted-exhaust-airflow',
      );
      expect(confirmed.canResolveAsFixed, isTrue);
      expect(
        confirmed.resolveEligibility,
        CloseResolveEligibility.allowResolved,
      );
    });
  });

  group('Path 3 — safety absolute', () {
    test('safety stop forces Needs professional eligibility', () {
      final result = reasoning.evaluate(
        package: package,
        evidence: [
          evidence(
            templateId: 'hazard-observation',
            observation: 'Do you smell burning or see smoke?',
            answer: 'Yes',
          ),
        ],
        primaryFailureModeId: 'heating-element-failed',
        safetyStopActive: true,
      );

      expect(
        result.resolveEligibility,
        CloseResolveEligibility.safetyStop,
      );
      expect(result.canResolveAsFixed, isFalse);
      expect(result.prefersProfessional, isTrue);
    });
  });

  group('Path 4 — weak evidence', () {
    test('no forced diagnosis; unresolved remains available', () {
      final result = reasoning.evaluate(package: package, evidence: const []);
      expect(result.clearLeaderFailureModeId, isNull);
      expect(result.verificationOutcome, VerificationOutcome.notApplicable);
      expect(
        result.resolveEligibility,
        CloseResolveEligibility.unresolvedOnly,
      );
      expect(result.canResolveAsFixed, isFalse);
    });
  });
}
