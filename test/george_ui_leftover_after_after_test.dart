import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/dryer_energy_source.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/package_release_validator.dart';
import 'package:modern_butlers_book/helpers/parts_cost.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/thermal_reset_scope.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/parts_cost_card.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';
import 'package:modern_butlers_book/main.dart';

import 'support/session_test_helpers.dart';

Evidence _fuelEvidence(String answer) {
  return Evidence(
    id: 'e-fuel-$answer',
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: gasDryerTypeHouseholdPrompt,
    answer: answer,
    templateId: gasDryerTypeTemplateId,
    collectedAt: DateTime.utc(2026, 8, 29, 19),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  setUp(clearImportedClosePaths);

  group('1) electricHeatGenerationModeIds fuel steering', () {
    test('set is heater-circuit leaders plus missing-leg and loose cord', () {
      expect(
        electricHeatGenerationModeIds,
        containsAll(heaterCircuitDiyCannotCompleteLeaderIds),
      );
      expect(
        electricHeatGenerationModeIds,
        containsAll([
          'missing-leg-240v-supply',
          'loose-power-cord-connection-electric',
        ]),
      );
      expect(
        electricHeatGenerationModeIds.contains(accessibleThermalResetModeId),
        isFalse,
      );
      expect(
        electricHeatGenerationModeIds.contains(motorOverheatProtectorModeId),
        isFalse,
      );
    });

    test('gas dryer extra-excludes the missing heater-circuit siblings', () {
      const siblings = [
        'high-limit-thermostat-open',
        'cycling-thermostat-failed',
        'cycling-thermostat-stuck-open',
        'cycling-thermostat-stuck-closed',
        'thermistor-fault-electronic',
        'timer-advanced-no-heat-portion',
      ];
      final standings = <String, FailureModeStanding>{
        for (final id in [
          ...siblings,
          'heating-element-failed',
          'thermal-fuse-open',
          accessibleThermalResetModeId,
          'gas-dryer-no-ignition-professional-only',
        ])
          id: const FailureModeStanding(supportCount: 2, excludeCount: 0),
      };
      final steered = applyFuelTypeSteering(
        standings: standings,
        evidence: [_fuelEvidence(gasDryerTypeGasAnswer)],
      );
      for (final id in [
        ...siblings,
        'heating-element-failed',
        'thermal-fuse-open',
      ]) {
        expect(steered[id]!.excludeCount, 3, reason: id);
        expect(steered[id]!.supportCount, 2, reason: id);
      }
      expect(steered[accessibleThermalResetModeId]!.excludeCount, 0);
      expect(
        steered['gas-dryer-no-ignition-professional-only']!.excludeCount,
        0,
      );
    });

    test('electric dryer does not extra-exclude heater-circuit siblings', () {
      final standings = <String, FailureModeStanding>{
        for (final id in [
          'cycling-thermostat-stuck-closed',
          'heating-element-failed',
          'high-limit-thermostat-open',
          'gas-dryer-no-ignition-professional-only',
        ])
          id: const FailureModeStanding(supportCount: 2, excludeCount: 0),
      };
      final steered = applyFuelTypeSteering(
        standings: standings,
        evidence: [_fuelEvidence(gasDryerTypeElectricAnswer)],
      );
      expect(steered['cycling-thermostat-stuck-closed']!.excludeCount, 0);
      expect(steered['heating-element-failed']!.excludeCount, 0);
      expect(steered['high-limit-thermostat-open']!.excludeCount, 0);
      expect(
        steered['gas-dryer-no-ignition-professional-only']!.excludeCount,
        2,
      );
    });
  });

  group('2) start-capacitor is gated professional, fail-closed, not a hard stop',
      () {
    const id = 'start-capacitor-or-start-assist-weak';

    test('id-based gate, fail-closed, not door-switch or motor-overheat', () {
      KnowledgePackageRepository().loadById('dryer-core');
      expect(isGatedProfessionalFailureMode(id), isTrue);
      expect(failClosedResolvedOnConfirmModeIds(), contains(id));
      expect(isHeaterCircuitDiyCannotCompleteLeader(id), isFalse);
      expect(
        evaluateSafetyStop(evidence: const [], primaryFailureModeId: id),
        isNull,
      );
      expect(
        sessionSafetyLevelFor(evidence: const [], primaryFailureModeId: id),
        'professional',
      );
      expect(
        closePathForFailureMode(id)!.allowResolvedWhenConfirmed,
        isFalse,
      );
      expect(
        closeResolveEligibility(
          safetyStopActive: false,
          primaryFailureModeId: id,
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
        isGatedProfessionalFailureMode('door-switch-failure'),
        isFalse,
      );
      expect(
        isGatedProfessionalFailureMode(motorOverheatProtectorModeId),
        isFalse,
      );
    });

    testWidgets(
      'start-capacitor primary is Check carefully, Pro recommended, not Fixed',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 19, 10),
        );
        await openDryerSession(tester, deps, 'Start Capacitor House');
        final dryer = deps.appliancesForCurrentHousehold().single;
        final sessionId = deps.startOrResumeSession(dryer);
        await selectFailureMode(tester, id);

        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(find.text('Safe to continue'), findsNothing);
        expect(
          tester.widget<SafetyStatusLight>(find.byType(SafetyStatusLight)).kind,
          SafetyLightKind.caution,
        );
        expect(find.text('Check carefully'), findsWidgets);
        expect(find.text('Pro recommended'), findsNothing);
        expect(find.text("I'll repair"), findsNothing);
        expect(find.textContaining('DIY ~'), findsNothing);

        await completeRepairReadinessIfPresent(tester);
        await completeGuidanceStepsIfPresent(tester);
        expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
        expect(find.text('Pro recommended'), findsWidgets);
        expect(find.byKey(const Key('outcome-resolved')), findsNothing);
        expect(find.text('Fixed'), findsNothing);
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
      },
    );
  });

  group('3) gas-dryer-no-ignition is gated professional, not a hard stop', () {
    const id = 'gas-dryer-no-ignition-professional-only';

    test('id-based gate, not a hard stop; gas smell still Stop', () {
      KnowledgePackageRepository().loadById('dryer-core');
      expect(isGatedProfessionalFailureMode(id), isTrue);
      expect(riskyVerificationModeIds, contains(id));
      expect(
        evaluateSafetyStop(evidence: const [], primaryFailureModeId: id),
        isNull,
      );
      expect(
        sessionSafetyLevelFor(evidence: const [], primaryFailureModeId: id),
        'professional',
      );

      final smell = Evidence(
        id: 'e-gas-smell',
        sessionId: 'session-1',
        applianceId: 'appliance-1',
        type: EvidenceType.textObservation,
        observation: 'gas smell',
        answer: 'propane',
        collectedAt: DateTime.utc(2026, 8, 29, 19, 20),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      );
      expect(
        evaluateSafetyStop(evidence: [smell], primaryFailureModeId: id),
        isNotNull,
      );
      expect(
        sessionSafetyLevelFor(evidence: [smell], primaryFailureModeId: id),
        'stop',
      );

      final path = closePathForFailureMode(id)!;
      expect(path.allowResolvedWhenConfirmed, isFalse);
      final joined = path.safeGuidanceSteps.join(' ').toLowerCase();
      expect(joined, contains('external gas supply valve'));
      expect(joined, contains('do not attempt gas ignition repair'));
      expect(joined, isNot(contains('replace igniter')));
      expect(joined, isNot(contains('replace the gas valve')));
      expect(joined, isNot(contains('test the flame sensor')));
      expect(joined, isNot(contains('light the burner')));
    });

    testWidgets(
      'gas no-ignition primary is Check carefully, I\'ll repair hidden',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 19, 25),
        );
        await openDryerSession(tester, deps, 'Gas Ignition House');
        final dryer = deps.appliancesForCurrentHousehold().single;
        final sessionId = deps.startOrResumeSession(dryer);
        await selectFailureMode(tester, id);

        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(find.text('Safe to continue'), findsNothing);
        expect(
          tester.widget<SafetyStatusLight>(find.byType(SafetyStatusLight)).kind,
          SafetyLightKind.caution,
        );
        expect(find.text('Check carefully'), findsWidgets);
        expect(find.text("I'll repair"), findsNothing);
        expect(find.textContaining('DIY ~'), findsNothing);
        expect(find.textContaining('replace igniter'), findsNothing);
        expect(find.textContaining('replace the gas valve'), findsNothing);

        await completeRepairReadinessIfPresent(tester);
        await completeGuidanceStepsIfPresent(tester);
        expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
        expect(find.text('Pro recommended'), findsWidgets);
        expect(find.byKey(const Key('outcome-resolved')), findsNothing);
        expect(find.text('Fixed'), findsNothing);
      },
    );
  });

  group('4) partsCostDiyOutOfScope is id-based when imported path is null', () {
    test('gated ids are DIY-out-of-scope even with a null imported path', () {
      clearImportedClosePaths();
      for (final id in const [
        'start-capacitor-or-start-assist-weak',
        'gas-dryer-no-ignition-professional-only',
      ]) {
        expect(closePathForFailureMode(id), isNull, reason: id);
        expect(isGatedProfessionalFailureMode(id), isTrue, reason: id);
        expect(partsCostDiyOutOfScope(id), isTrue, reason: id);
      }
      expect(
        partsCostDiyOutOfScope('cycling-thermostat-stuck-closed'),
        isTrue,
      );
      expect(partsCostDiyOutOfScope('not-a-real-mode'), isFalse);
    });

    test('resettable thermal cutoff stays DIY; motor-overheat stays DIY', () {
      KnowledgePackageRepository().loadById('dryer-core');
      expect(isResettableThermalPath(accessibleThermalResetModeId), isTrue);
      expect(
        closePathForFailureMode(accessibleThermalResetModeId)!
            .allowResolvedWhenConfirmed,
        isTrue,
      );
      expect(partsCostDiyOutOfScope(accessibleThermalResetModeId), isFalse);
      expect(isGatedProfessionalFailureMode(accessibleThermalResetModeId), isFalse);
      expect(partsCostDiyOutOfScope(motorOverheatProtectorModeId), isFalse);
      expect(
        isGatedProfessionalFailureMode(motorOverheatProtectorModeId),
        isFalse,
      );
    });

    testWidgets(
      'Phone P: gated id + absent close path hides I\'ll repair / DIY ~',
      (tester) async {
        clearImportedClosePaths();
        const quoted = PartCostEstimate(
          name: 'Quoted part',
          diyEstimate: r'$20–40',
          proEstimate: r'$150–280',
        );
        for (final id in const [
          'start-capacitor-or-start-assist-weak',
          'gas-dryer-no-ignition-professional-only',
        ]) {
          expect(isGatedProfessionalFailureMode(id), isTrue, reason: id);
          expect(closePathForFailureMode(id), isNull, reason: id);
          expect(partsCostDiyOutOfScope(id), isTrue, reason: id);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PartsCostCard(
                  parts: const [quoted],
                  diyOutOfScope: partsCostDiyOutOfScope(id),
                  onIllRepair: () {},
                  onCallPro: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text("I'll repair"), findsNothing, reason: id);
          expect(find.textContaining('DIY ~'), findsNothing, reason: id);
          expect(find.textContaining('Pro ~'), findsOneWidget, reason: id);
          expect(find.byKey(const Key('parts-cost-call-pro')), findsOneWidget);
          expect(find.text('Call a pro'), findsOneWidget);
          expect(find.byKey(const Key('parts-cost-ill-repair')), findsNothing);
        }

        KnowledgePackageRepository().loadById('dryer-core');
        expect(
          isGatedProfessionalFailureMode(accessibleThermalResetModeId),
          isFalse,
        );
        expect(isResettableThermalPath(accessibleThermalResetModeId), isTrue);
        expect(
          closePathForFailureMode(accessibleThermalResetModeId)!
              .allowResolvedWhenConfirmed,
          isTrue,
        );
        expect(partsCostDiyOutOfScope(accessibleThermalResetModeId), isFalse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PartsCostCard(
                parts: const [quoted],
                diyOutOfScope: partsCostDiyOutOfScope(
                  accessibleThermalResetModeId,
                ),
                onIllRepair: () {},
                onCallPro: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('DIY ~'), findsWidgets);
        expect(find.byKey(const Key('parts-cost-ill-repair')), findsOneWidget);
        expect(find.text("I'll repair"), findsOneWidget);
      },
    );
  });

  group('M) gas dryer no-heat ranking and lamp', () {
    testWidgets(
      'gas no-heat Most likely is not heater-circuit; lamp not Safe to continue',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 19, 40),
        );
        deps.createHousehold('Gas No Heat House');
        final dryer = deps.addDryer(energySource: ApplianceEnergySource.gas);
        expect(dryer.energySource, ApplianceEnergySource.gas);

        await prepareTallSurface(tester);
        await tester.pumpWidget(ModernButlerApp(dependencies: deps));
        await tester.pumpAndSettle();
        await tester.tap(find.text(dryer.name));
        await tester.pumpAndSettle();
        expect(find.textContaining('Energy: Gas'), findsWidgets);
        await startRepairFromDetail(tester);

        final sessionId = deps.startOrResumeSession(dryer);
        // Seeded gas-dryer-type evidence hides the problem starter.
        if (find.byKey(const Key('starter-chip-no-heat')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('problem-starter-confirm')));
          await tester.pumpAndSettle();
        } else {
          await selectObservation(tester, 'heat-observed');
          await tapInspectOrAnswerChoice(tester, 'no-warmth');
        }

        expect(find.byKey(const Key('starter-chip-hazard-signs')), findsNothing);
        expect(
          find.byKey(const Key('observation-prompt-gas-dryer-type')),
          findsNothing,
        );

        final context = deps.buildDecisionContext(sessionId);
        final snapshot = const RankingService().evaluate(
          package: context.package!,
          evidence: context.evidence,
          authoringIndex: context.authoringIndex,
          energySource: ApplianceEnergySource.gas,
        );
        expect(snapshot.orderedFailureModes, isNotEmpty);
        expect(
          snapshot.orderedFailureModes.first.id,
          isNot('cycling-thermostat-stuck-closed'),
        );
        expect(
          snapshot.orderedFailureModes.first.id,
          isNot('heating-element-failed'),
        );
        expect(
          snapshot.orderedFailureModes.first.id,
          isNot('high-limit-thermostat-open'),
        );
        expect(
          find.byKey(
            const Key(
              'recommended-primary-label-cycling-thermostat-stuck-closed',
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const Key('recommended-primary-label-heating-element-failed'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const Key('recommended-primary-label-high-limit-thermostat-open'),
          ),
          findsNothing,
        );

        await selectFailureMode(
          tester,
          'gas-dryer-no-ignition-professional-only',
        );
        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
        expect(find.text('Safe to continue'), findsNothing);
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(find.text('Check carefully'), findsWidgets);
      },
    );
  });
}
