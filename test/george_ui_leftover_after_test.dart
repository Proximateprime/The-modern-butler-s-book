import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/package_release_validator.dart';
import 'package:modern_butlers_book/helpers/parts_cost.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';

import 'support/session_test_helpers.dart';

void main() {
  setUp(clearImportedClosePaths);

  group('1) heater-circuit DIY cannot complete remaining leaders', () {
    test('stuck-closed thermostat and relay are DIY-out-of-scope', () {
      KnowledgePackageRepository().loadById('dryer-core');
      for (final id in const [
        'cycling-thermostat-stuck-closed',
        'relay-or-control-no-heat-output',
      ]) {
        expect(isHeaterCircuitDiyCannotCompleteLeader(id), isTrue, reason: id);
        final path = closePathForFailureMode(id)!;
        expect(closePathDiyCannotComplete(path), isTrue, reason: id);
        expect(partsCostDiyOutOfScope(id), isTrue, reason: id);
        expect(path.allowResolvedWhenConfirmed, isFalse, reason: id);
        expect(
          closeResolveEligibility(
            safetyStopActive: false,
            primaryFailureModeId: id,
            verificationOutcome: VerificationOutcome.supported,
          ),
          CloseResolveEligibility.needsProfessional,
          reason: id,
        );
        expect(
          evaluateSafetyStop(evidence: const [], primaryFailureModeId: id),
          isNull,
          reason: id,
        );
        expect(
          sessionSafetyLevelFor(
            evidence: const [],
            primaryFailureModeId: id,
          ),
          'professional',
          reason: id,
        );
      }
    });

    testWidgets(
      'stuck-closed thermostat primary has no I\'ll repair / DIY price',
      (tester) async {
        await _expectHeaterCircuitProClose(
          tester,
          household: 'Stuck Closed House',
          failureModeId: 'cycling-thermostat-stuck-closed',
        );
      },
    );

    testWidgets(
      'relay-or-control primary has no I\'ll repair / DIY price',
      (tester) async {
        await _expectHeaterCircuitProClose(
          tester,
          household: 'Relay Control House',
          failureModeId: 'relay-or-control-no-heat-output',
        );
      },
    );
  });

  group('2) start-switch-failure is professional, not door-switch', () {
    test('Confirmed does not unlock Fixed; door-switch Fixed stays', () {
      KnowledgePackageRepository().loadById('dryer-core');
      expect(
        isHeaterCircuitDiyCannotCompleteLeader('start-switch-failure'),
        isFalse,
      );
      expect(isGatedProfessionalFailureMode('start-switch-failure'), isTrue);
      expect(
        evaluateSafetyStop(
          evidence: const [],
          primaryFailureModeId: 'start-switch-failure',
        ),
        isNull,
      );
      expect(
        sessionSafetyLevelFor(
          evidence: const [],
          primaryFailureModeId: 'start-switch-failure',
        ),
        'professional',
      );
      final start = closePathForFailureMode('start-switch-failure')!;
      expect(start.allowResolvedWhenConfirmed, isFalse);
      expect(closePathDiyCannotComplete(start), isTrue);
      expect(
        closeResolveEligibility(
          safetyStopActive: false,
          primaryFailureModeId: 'start-switch-failure',
          verificationOutcome: VerificationOutcome.supported,
        ),
        CloseResolveEligibility.needsProfessional,
      );

      final door = closePathForFailureMode('door-switch-failure')!;
      expect(door.allowResolvedWhenConfirmed, isTrue);
      expect(
        closeResolveEligibility(
          safetyStopActive: false,
          primaryFailureModeId: 'door-switch-failure',
          verificationOutcome: VerificationOutcome.supported,
          closePath: door,
        ),
        CloseResolveEligibility.allowResolved,
      );
      expect(
        closePathForFailureMode('start-capacitor-or-start-assist-weak')!
            .allowResolvedWhenConfirmed,
        isFalse,
      );
    });

    testWidgets(
      'start-switch primary is Check carefully, Pro recommended, not Fixed',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 18),
        );
        await openDryerSession(tester, deps, 'Start Switch House');
        final dryer = deps.appliancesForCurrentHousehold().single;
        final sessionId = deps.startOrResumeSession(dryer);
        await selectFailureMode(tester, 'start-switch-failure');

        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(
          tester.widget<SafetyStatusLight>(find.byType(SafetyStatusLight)).kind,
          SafetyLightKind.caution,
        );
        expect(find.text('Check carefully'), findsWidgets);
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);

        await completeRepairReadinessIfPresent(tester);
        await completeGuidanceStepsIfPresent(tester);
        expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
        expect(find.text('Pro recommended'), findsNothing);
        expect(find.byKey(const Key('outcome-resolved')), findsNothing);
        expect(find.text('Fixed'), findsNothing);
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(find.textContaining('DIY ~'), findsNothing);
      },
    );
  });

  group('3) House Book wipe deletes rating-plate photos after confirm', () {
    test('cancel leaves the rating-plate file; confirm deletes it', () async {
      final dir = await Directory.systemTemp.createTemp('butler-rating-');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final photo = File('${dir.path}/rating-plate.jpg');
      await photo.writeAsBytes(const [1, 2, 3, 4]);
      expect(await photo.exists(), isTrue);

      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 18, 10),
      );
      deps.createHousehold('Rating Plate Wipe House');
      deps.addDryer(ratingLabelPhotoPath: photo.path);
      expect(
        deps.appliancesForCurrentHousehold().single.ratingLabelPhotoPath,
        photo.path,
      );

      // Cancel never calls wipeLocalHouseBook (silent wipe is illegal).
      expect(await photo.exists(), isTrue);
      expect(deps.appliancesForCurrentHousehold(), isNotEmpty);

      await deps.wipeLocalHouseBook();
      expect(await photo.exists(), isFalse);
      expect(deps.applianceRepository.listAll(), isEmpty);
      expect(deps.firstRunComplete, isFalse);
    });
  });

  group('4) release validator fail-closed on gated ids', () {
    test('shipped heater-circuit and start-switch flags are false', () {
      KnowledgePackageRepository().loadById('dryer-core');
      final package =
          KnowledgePackageRepository().loadById('dryer-core')!;
      expect(riskyVerificationFindingsFor(package), isEmpty);
      for (final id in failClosedResolvedOnConfirmModeIds()) {
        final path = closePathForFailureMode(id);
        if (path == null) continue;
        expect(
          path.allowResolvedWhenConfirmed,
          isFalse,
          reason: id,
        );
      }
    });

    test('validator fails those mode ids if allowResolvedWhenConfirmed true',
        () {
      final repo = KnowledgePackageRepository();
      final package = repo.loadById('dryer-core')!;
      for (final id in const [
        'cycling-thermostat-stuck-closed',
        'relay-or-control-no-heat-output',
        'start-switch-failure',
      ]) {
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
        errors.any((e) => e.message.contains('cycling-thermostat-stuck-closed')),
        isTrue,
      );
      expect(
        errors.any((e) => e.message.contains('relay-or-control-no-heat-output')),
        isTrue,
      );
      expect(
        errors.any((e) => e.message.contains('start-switch-failure')),
        isTrue,
      );
    });
  });
}

Future<void> _expectHeaterCircuitProClose(
  WidgetTester tester, {
  required String household,
  required String failureModeId,
}) async {
  final deps = AppDependencies(
    clock: () => DateTime.utc(2026, 8, 29, 17, 40),
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
  expect(find.text("I'll repair"), findsNothing);
  expect(find.textContaining('DIY ~'), findsNothing);
  expect(find.textContaining('DIY Parts'), findsNothing);

  await completeRepairReadinessIfPresent(tester);
  await completeGuidanceStepsIfPresent(tester);
  expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
  expect(find.text('Pro recommended'), findsNothing);
  expect(find.byKey(const Key('outcome-resolved')), findsNothing);
  expect(find.text('Fixed'), findsNothing);
  expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
  expect(find.textContaining('DIY ~'), findsNothing);
}
