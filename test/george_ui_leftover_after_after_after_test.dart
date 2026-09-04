import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/package_release_validator.dart';
import 'package:modern_butlers_book/helpers/parts_cost.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_batch_01.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_batch_02.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_record.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_batch_importer.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';

import 'support/session_test_helpers.dart';

const _doorSwitchAsk =
    'After firmly closing the door until it clicks, does the dryer now '
    'start normally when you press Start?';

const _gatedPackIds = [
  'internal-duct-lint-collapse',
  'blower-wheel-obstruction',
];

void main() {
  setUp(clearImportedClosePaths);

  group('1) door-switch imported ask is now-starts polarity', () {
    test('imported ask is now-starts; still-dead is Not confirmed → professional',
        () {
      KnowledgePackageRepository().loadById('dryer-core');
      final path = closePathForFailureMode('door-switch-failure')!;
      final ask = path.verificationAsk.toLowerCase();
      expect(path.verificationAsk, _doorSwitchAsk);
      expect(ask, contains('now start normally'));
      expect(ask, isNot(contains('still do nothing')));
      expect(path.allowResolvedWhenConfirmed, isTrue);
      expect(closePathDiyCannotComplete(path), isFalse);
      expect(isGatedProfessionalFailureMode('door-switch-failure'), isFalse);
      expect(
        failClosedResolvedOnConfirmModeIds(),
        isNot(contains('door-switch-failure')),
      );
      expect(
        closeResolveEligibility(
          safetyStopActive: false,
          primaryFailureModeId: 'door-switch-failure',
          verificationOutcome: VerificationOutcome.supported,
          closePath: path,
        ),
        CloseResolveEligibility.allowResolved,
      );
      expect(
        closeResolveEligibility(
          safetyStopActive: false,
          primaryFailureModeId: 'door-switch-failure',
          verificationOutcome: VerificationOutcome.contradicted,
          closePath: path,
        ),
        CloseResolveEligibility.needsProfessional,
      );
      expect(
        sessionSafetyLevelFor(
          evidence: const [],
          primaryFailureModeId: 'door-switch-failure',
        ),
        'clear',
      );
    });

    test('JSON data file stays aligned with dart embedding for door-switch', () {
      const importer = FailureModeBatchImporter();
      final fromFile = importer
          .parseBatchJson(
            File('lib/knowledge_factory/data/dryer_batch_01.v1.json')
                .readAsStringSync(),
          )
          .firstWhere((r) => r.id == 'door-switch-failure');
      final fromDart = importer
          .parseBatchJson(dryerBatch01Json)
          .firstWhere((r) => r.id == 'door-switch-failure');
      expect(fromFile.verificationAsk, fromDart.verificationAsk);
      expect(fromFile.verificationAsk, _doorSwitchAsk);
      expect(fromFile.allowResolvedWhenConfirmed, isTrue);
      expect(fromDart.allowResolvedWhenConfirmed, isTrue);
      expect(fromFile.toJson(), fromDart.toJson());
      expect(
        fromFile.verificationAsk.toLowerCase(),
        isNot(contains('still do nothing')),
      );
    });

    testWidgets(
      'Q: now-starts ask; Confirmed Fixed; lamp is not Check carefully from gate',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 20, 10),
        );
        await openDryerSession(tester, deps, 'Door Switch Polarity House');
        final dryer = deps.appliancesForCurrentHousehold().single;
        final sessionId = deps.startOrResumeSession(dryer);
        await selectFailureMode(tester, 'door-switch-failure');

        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'clear');
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(isGatedProfessionalFailureMode('door-switch-failure'), isFalse);
        // closePathActive lights Check carefully; the door-switch gate does not.
        expect(
          sessionSafetyLevelFor(
            evidence: const [],
            primaryFailureModeId: 'door-switch-failure',
          ),
          isNot('professional'),
        );

        await reachClosePathVerificationIfPresent(tester);
        expect(find.byKey(const Key('verification-ask')), findsOneWidget);
        expect(find.text(_doorSwitchAsk), findsWidgets);
        expect(find.textContaining('still do nothing'), findsNothing);
        expect(find.byKey(const Key('close-answer-choice-panel')), findsOneWidget);

        await tapVisible(
          tester,
          find.byKey(const Key('answer-choice-confirmed')),
        );
        expect(find.text('Fixed'), findsWidgets);
        await tapVisible(tester, find.byKey(const Key('end-session-button')));
        expect(find.byKey(const Key('outcome-resolved')), findsOneWidget);
      },
    );

    testWidgets(
      'Q: Not confirmed (still-dead Start) is not Fixed — Needs a professional',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 20, 15),
        );
        await openDryerSession(tester, deps, 'Door Switch Still Dead House');
        await selectFailureMode(tester, 'door-switch-failure');
        await reachClosePathVerificationIfPresent(tester);
        expect(find.text(_doorSwitchAsk), findsWidgets);
        await tapVisible(
          tester,
          find.byKey(const Key('answer-choice-not-confirmed')),
        );
        expect(find.byKey(const Key('outcome-resolved')), findsNothing);
        expect(
          find.byKey(const Key('end-session-button')),
          findsWidgets,
        );
        expect(find.text('Needs a professional'), findsWidgets);
        expect(find.byKey(const Key('outcome-resolved')), findsNothing);
      },
    );
  });

  group('2) internal-duct and blower-wheel are gated professional', () {
    for (final id in _gatedPackIds) {
      test('$id is id-based gate, fail-closed, not a hard stop, not door-switch',
          () {
        KnowledgePackageRepository().loadById('dryer-core');
        expect(isGatedProfessionalFailureMode(id), isTrue, reason: id);
        expect(failClosedResolvedOnConfirmModeIds(), contains(id), reason: id);
        expect(
          evaluateSafetyStop(evidence: const [], primaryFailureModeId: id),
          isNull,
          reason: id,
        );
        expect(
          sessionSafetyLevelFor(evidence: const [], primaryFailureModeId: id),
          'professional',
          reason: id,
        );
        expect(
          closePathForFailureMode(id)!.allowResolvedWhenConfirmed,
          isFalse,
          reason: id,
        );
        expect(partsCostDiyOutOfScope(id), isTrue, reason: id);
        expect(
          closeResolveEligibility(
            safetyStopActive: false,
            primaryFailureModeId: id,
            verificationOutcome: VerificationOutcome.supported,
          ),
          CloseResolveEligibility.needsProfessional,
          reason: id,
        );
      });
    }

    test('id-based gate and DIY-out-of-scope hold when imported path is null',
        () {
      clearImportedClosePaths();
      for (final id in _gatedPackIds) {
        expect(closePathForFailureMode(id), isNull, reason: id);
        expect(isGatedProfessionalFailureMode(id), isTrue, reason: id);
        expect(partsCostDiyOutOfScope(id), isTrue, reason: id);
      }
      expect(isGatedProfessionalFailureMode('door-switch-failure'), isFalse);
    });

    test('JSON data files stay aligned with dart embeddings for gated ids', () {
      const importer = FailureModeBatchImporter();
      final file01 = importer.parseBatchJson(
        File('lib/knowledge_factory/data/dryer_batch_01.v1.json')
            .readAsStringSync(),
      );
      final dart01 = importer.parseBatchJson(dryerBatch01Json);
      final file02 = importer.parseBatchJson(
        File('lib/knowledge_factory/data/dryer_batch_02.v1.json')
            .readAsStringSync(),
      );
      final dart02 = importer.parseBatchJson(dryerBatch02Json);

      FailureModeAuthoringRecord pick(
        List<FailureModeAuthoringRecord> records,
        String id,
      ) {
        return records.firstWhere((r) => r.id == id);
      }

      final blowerFile = pick(file01, 'blower-wheel-obstruction');
      final blowerDart = pick(dart01, 'blower-wheel-obstruction');
      expect(blowerFile.allowResolvedWhenConfirmed, isFalse);
      expect(blowerDart.allowResolvedWhenConfirmed, isFalse);
      expect(blowerFile.toJson(), blowerDart.toJson());

      final ductFile = pick(file02, 'internal-duct-lint-collapse');
      final ductDart = pick(dart02, 'internal-duct-lint-collapse');
      expect(ductFile.allowResolvedWhenConfirmed, isFalse);
      expect(ductDart.allowResolvedWhenConfirmed, isFalse);
      expect(ductFile.toJson(), ductDart.toJson());
    });

    testWidgets(
      'R: internal-duct is Check carefully, Pro recommended, not Fixed',
      (tester) async {
        await _expectGatedProfessionalClose(
          tester,
          household: 'Internal Duct House',
          failureModeId: 'internal-duct-lint-collapse',
        );
      },
    );

    testWidgets(
      'S: blower-wheel is Check carefully, Pro recommended, not Fixed',
      (tester) async {
        await _expectGatedProfessionalClose(
          tester,
          household: 'Blower Wheel House',
          failureModeId: 'blower-wheel-obstruction',
        );
      },
    );
  });

  group('3) failClosed includes internal-duct and blower-wheel', () {
    test('T: failClosed set contains both ids; door-switch is not in it', () {
      expect(
        failClosedResolvedOnConfirmModeIds(),
        containsAll(_gatedPackIds),
      );
      expect(
        failClosedResolvedOnConfirmModeIds(),
        isNot(contains('door-switch-failure')),
      );
    });

    test('T: shipped dryer-core findings are empty', () {
      final package = KnowledgePackageRepository().loadById('dryer-core')!;
      expect(riskyVerificationFindingsFor(package), isEmpty);
      for (final id in _gatedPackIds) {
        expect(
          closePathForFailureMode(id)!.allowResolvedWhenConfirmed,
          isFalse,
          reason: id,
        );
      }
    });

    test(
      'T: riskyVerificationFindingsFor errors if allowResolved is true',
      () {
        final package =
            KnowledgePackageRepository().loadById('dryer-core')!;
        for (final id in _gatedPackIds) {
          final original = closePathForFailureMode(id)!;
          registerImportedClosePath(
            FailureModeClosePath(
              failureModeId: original.failureModeId,
              verificationAsk: original.verificationAsk,
              verificationWhy: original.verificationWhy,
              safeGuidanceSteps: original.safeGuidanceSteps,
              allowResolvedWhenConfirmed: true,
              preferProfessionalWhenNotConfirmed: true,
            ),
          );
        }
        final errors = riskyVerificationFindingsFor(package);
        expect(
          errors.any((e) => e.message.contains('internal-duct-lint-collapse')),
          isTrue,
        );
        expect(
          errors.any((e) => e.message.contains('blower-wheel-obstruction')),
          isTrue,
        );
      },
    );
  });
}

Future<void> _expectGatedProfessionalClose(
  WidgetTester tester, {
  required String household,
  required String failureModeId,
}) async {
  final deps = AppDependencies(
    clock: () => DateTime.utc(2026, 8, 29, 20, 20),
  );
  await openDryerSession(tester, deps, household);
  final dryer = deps.appliancesForCurrentHousehold().single;
  final sessionId = deps.startOrResumeSession(dryer);
  await selectFailureMode(tester, failureModeId);

  expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
  expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
  expect(find.text('Safe to continue'), findsNothing);
  expect(
    tester.widget<SafetyStatusLight>(find.byType(SafetyStatusLight)).kind,
    SafetyLightKind.caution,
  );
  expect(find.text('Check carefully'), findsWidgets);
  expect(find.byKey(const Key('pro-scope-notice-line')), findsOneWidget);
  expect(find.text('A full fix likely needs a pro'), findsWidgets);
  expect(find.text("I'll repair"), findsNothing);
  expect(find.textContaining('DIY ~'), findsNothing);

  await completeRepairReadinessIfPresent(tester);
  await completeGuidanceStepsIfPresent(tester);
  expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
  expect(find.text('Pro recommended'), findsNothing);
  expect(find.byKey(const Key('outcome-resolved')), findsNothing);
  expect(find.text('Fixed'), findsNothing);
  expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
}
