import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

/// Guards that Safe Guidance and the verification question key off the leading
/// failure mode, and that over-temp protection modes never present vent
/// cleaning as proof of a completed repair.
void main() {
  setUp(() {
    clearImportedClosePaths();
    // Seeding the repository registers the authored (imported) close paths,
    // which are what the running app uses.
    KnowledgePackageRepository().loadById('dryer-core');
  });

  FailureModeClosePath pathFor(String id) {
    final path = closePathForFailureMode(id);
    expect(path, isNotNull, reason: 'missing close path for $id');
    return path!;
  }

  group('airflow-leading path', () {
    test('keeps vent-clean warmth restoration as valid verification', () {
      final path = pathFor('restricted-exhaust-airflow');
      final ask = path.verificationAsk.toLowerCase();

      expect(ask, contains('clean'));
      expect(ask, anyOf(contains('airflow'), contains('vent')));
      expect(path.allowResolvedWhenConfirmed, isTrue);
    });
  });

  group('over-temp protection paths', () {
    for (final id in const ['thermal-fuse-open', 'high-limit-thermostat-open']) {
      test('$id does not verify itself with vent-clean warmth restoration', () {
        final ask = pathFor(id).verificationAsk.toLowerCase();

        expect(
          ask,
          isNot(contains('is warmth restored')),
          reason:
              '$id cannot be proven fixed by cleaning the vent — the '
              'protective device does not reset.',
        );
        expect(
          ask,
          anyOf(contains('still no warmth'), contains('still produce no')),
          reason: '$id should verify the still-cold pattern, not a repair.',
        );
      });

      test('$id confirmation escalates instead of resolving', () {
        final path = pathFor(id);
        expect(path.allowResolvedWhenConfirmed, isFalse);

        expect(
          closeResolveEligibility(
            safetyStopActive: false,
            primaryFailureModeId: id,
            verificationOutcome: VerificationOutcome.supported,
            closePath: path,
          ),
          CloseResolveEligibility.needsProfessional,
        );
      });

      test('$id keeps airflow cleaning as cause context, not as proof', () {
        if (id == 'high-limit-thermostat-open') {
          return;
        }
        final steps = pathFor(id).safeGuidanceSteps.join(' ').toLowerCase();

        expect(steps, contains('lint'));
        expect(
          steps,
          anyOf(
            contains('will not restore heat'),
            contains('not the opened protection'),
            contains('without fixing restricted airflow'),
            contains('can open again'),
          ),
          reason:
              'Cleaning must be framed as fixing the overheating cause, not '
              'as the fix for the opened device.',
        );
      });

      test('$id preserves power-off safety language', () {
        final steps = pathFor(id).safeGuidanceSteps.join(' ').toLowerCase();

        if (id == 'thermal-fuse-open') {
          expect(steps, anyOf(contains('unplug'), contains('breaker')));
          expect(steps, contains('technician'));
          expect(steps, isNot(contains('heater service panel')));
        }
        expect(
          steps,
          anyOf(contains('do not measure live'), contains('never bypass')),
        );
      });
    }

    test('thermal fuse guidance never instructs metering or jumpering', () {
      final steps = pathFor('thermal-fuse-open').safeGuidanceSteps;

      for (final step in steps) {
        final lower = step.toLowerCase();
        if (lower.contains('jumper') ||
            lower.contains('measure') ||
            lower.contains('meter')) {
          expect(
            lower,
            anyOf(contains('do not'), contains('never')),
            reason: 'meter/jumper may only appear as a prohibition: $step',
          );
        }
      }
    });
  });

  group('ranking-to-close-path binding', () {
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
        collectedAt: DateTime.utc(2026, 7, 25),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      );
    }

    test(
      'thermal fuse ranking leader binds fuse path even when Primary is restricted vent',
      () {
        final package = KnowledgePackageRepository().loadById('dryer-core')!;
        final overheatEvidence = [
          evidence(
            templateId: 'heat-observed',
            answer: 'No warmth',
          ),
          evidence(
            templateId: 'cycle-heat-setting',
            answer: 'Yes, heat cycle',
          ),
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

        final result = reasoning.evaluate(
          package: package,
          evidence: overheatEvidence,
          primaryFailureModeId: 'restricted-exhaust-airflow',
        );

        expect(result.recommendPrimaryFailureModeId, 'thermal-fuse-open');
        expect(result.closePath, isNotNull);
        expect(result.closePath!.failureModeId, 'thermal-fuse-open');

        final ask = result.closePath!.verificationAsk.toLowerCase();
        expect(ask, isNot(contains('is warmth restored')));
        expect(
          ask,
          anyOf(contains('still no warmth'), contains('still produce no')),
        );

        final ventPath = closePathForFailureMode('restricted-exhaust-airflow')!;
        expect(
          result.closePath!.verificationAsk,
          isNot(equals(ventPath.verificationAsk)),
        );
      },
    );

    test(
      'ranking leader binds when no confirmed Primary but overheat evidence is clear',
      () {
        final package = KnowledgePackageRepository().loadById('dryer-core')!;
        final overheatEvidence = [
          evidence(
            templateId: 'heat-observed',
            answer: 'No warmth',
          ),
          evidence(
            templateId: 'cycle-heat-setting',
            answer: 'Yes, heat cycle',
          ),
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

        final result = reasoning.evaluate(
          package: package,
          evidence: overheatEvidence,
        );

        expect(result.closePath?.failureModeId, 'thermal-fuse-open');
      },
    );
  });

  group('guidance display', () {
    test('no dryer safe-guidance step renders placeholder copy', () {
      const modeIds = [
        'restricted-exhaust-airflow',
        'clogged-lint-pathway',
        'thermal-fuse-open',
        'high-limit-thermostat-open',
        'heating-element-failed',
        'electric-supply-connection-fault',
        'broken-drive-belt',
        'door-switch-failure',
        'motor-failure',
      ];

      for (final id in modeIds) {
        final path = closePathForFailureMode(id);
        if (path == null) {
          continue;
        }
        for (final step in path.safeGuidanceSteps) {
          final block = guidanceForSafeStep(step);
          expect(
            block.what,
            isNot('What to do next'),
            reason: 'placeholder title on "$step" ($id)',
          );
          expect(block.what.trim(), isNotEmpty);
          expect(block.how.trim(), isNotEmpty);
          expect(block.resultMeans.trim(), isNotEmpty);
          expect(block.whenToStop.trim(), isNotEmpty);
          expect(
            block.resultMeans,
            isNot(
              'This step either supports the diagnosis or tells you when to '
              'escalate.',
            ),
            reason: 'boilerplate result on "$step" ($id)',
          );
        }
      }
    });

    test('fuse-specific step gets fuse-specific guidance', () {
      final block = guidanceForSafeStep(
        'Locate the thermal fuse on the heater housing or blower path. '
        'Replace with an exact-match part for your model.',
      );

      expect(block.what.toLowerCase(), contains('thermal fuse'));
      expect(block.how.toLowerCase(), contains('replace'));
      expect(block.whenToStop.toLowerCase(), contains('live'));
    });
  });
}
