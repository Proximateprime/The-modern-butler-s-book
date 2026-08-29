import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/forbidden_guidance.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_inspect_steps.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_record.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_batch_importer.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/inspect_step.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/household_how_to_text.dart';
import 'package:modern_butlers_book/ui/inspect_step_card.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

InspectStep _lintLookFor(String lookFor) {
  return InspectStep(
    id: dryerLintFilterInspectStep.id,
    title: dryerLintFilterInspectStep.title,
    safetyPreamble: dryerLintFilterInspectStep.safetyPreamble,
    lookFor: lookFor,
    okMeans: dryerLintFilterInspectStep.okMeans,
    notOkMeans: dryerLintFilterInspectStep.notOkMeans,
    diagramAsset: dryerLintFilterInspectStep.diagramAsset,
    cameraMode: dryerLintFilterInspectStep.cameraMode,
    appliesTo: dryerLintFilterInspectStep.appliesTo,
    evidenceTemplateId: dryerLintFilterInspectStep.evidenceTemplateId,
    evidenceAnswerByChip: dryerLintFilterInspectStep.evidenceAnswerByChip,
    failureModeIds: dryerLintFilterInspectStep.failureModeIds,
    relatedEasyCheckTemplateId:
        dryerLintFilterInspectStep.relatedEasyCheckTemplateId,
    beginnerSafe: dryerLintFilterInspectStep.beginnerSafe,
    noLiveElectrical: dryerLintFilterInspectStep.noLiveElectrical,
    frameHint: dryerLintFilterInspectStep.frameHint,
  );
}

void main() {
  setUp(clearImportedClosePaths);

  group('1) heater-circuit DIY-cannot-complete leaders', () {
    test('heating-element is professional, not a hard stop, Confirmed ≠ Fixed',
        () {
      KnowledgePackageRepository().loadById('dryer-core');
      expect(
        evaluateSafetyStop(
          evidence: const [],
          primaryFailureModeId: 'heating-element-failed',
        ),
        isNull,
      );
      expect(
        sessionSafetyLevelFor(
          evidence: const [],
          primaryFailureModeId: 'heating-element-failed',
        ),
        'professional',
      );
      expect(
        closePathForFailureMode('heating-element-failed')!
            .allowResolvedWhenConfirmed,
        isFalse,
      );
      expect(
        closeResolveEligibility(
          safetyStopActive: false,
          primaryFailureModeId: 'heating-element-failed',
          verificationOutcome: VerificationOutcome.supported,
        ),
        CloseResolveEligibility.needsProfessional,
      );
    });

    test('door-switch Confirmed still allows Fixed', () {
      KnowledgePackageRepository().loadById('dryer-core');
      final path = closePathForFailureMode('door-switch-failure')!;
      expect(path.allowResolvedWhenConfirmed, isTrue);
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
        evaluateSafetyStop(
          evidence: const [],
          primaryFailureModeId: 'door-switch-failure',
        ),
        isNull,
      );
    });

    testWidgets(
      'heating-element primary shows Check carefully, not Stop or calm',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 16),
        );
        await openDryerSession(tester, deps, 'Element Lamp House');
        final dryer = deps.appliancesForCurrentHousehold().single;
        final sessionId = deps.startOrResumeSession(dryer);
        await selectFailureMode(tester, 'heating-element-failed');

        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(find.text('Safe to continue'), findsNothing);
        expect(
          tester.widget<SafetyStatusLight>(find.byType(SafetyStatusLight)).kind,
          SafetyLightKind.caution,
        );
        expect(find.text('Check carefully'), findsWidgets);
      },
    );

    testWidgets(
      'heating-element close is Pro recommended, not Fixed',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 16, 5),
        );
        await openDryerSession(tester, deps, 'Element Close House');
        await selectFailureMode(tester, 'heating-element-failed');
        await completeRepairReadinessIfPresent(tester);
        await completeGuidanceStepsIfPresent(tester);
        expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
        expect(find.text('Pro recommended'), findsWidgets);
        expect(find.byKey(const Key('outcome-resolved')), findsNothing);
        expect(find.text('Fixed'), findsNothing);
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
      },
    );

    testWidgets(
      'door-switch primary is not a heater-circuit professional gate',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 16, 8),
        );
        await openDryerSession(tester, deps, 'Door Switch Lamp House');
        final dryer = deps.appliancesForCurrentHousehold().single;
        final sessionId = deps.startOrResumeSession(dryer);
        await selectFailureMode(tester, 'door-switch-failure');

        expect(deps.buildDecisionContext(sessionId).safetyLevel, 'clear');
        expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
        expect(
          isHeaterCircuitDiyCannotCompleteLeader('door-switch-failure'),
          isFalse,
        );
        expect(
          closePathForFailureMode('door-switch-failure')!
              .allowResolvedWhenConfirmed,
          isTrue,
        );
      },
    );

    test('remaining heater-circuit leaders are professional, not a hard stop',
        () {
      KnowledgePackageRepository().loadById('dryer-core');
      const leaders = [
        'high-limit-thermostat-open',
        'cycling-thermostat-failed',
        'cycling-thermostat-stuck-open',
        'cycling-thermostat-stuck-closed',
        'relay-or-control-no-heat-output',
        'thermistor-fault-electronic',
        'timer-advanced-no-heat-portion',
      ];
      for (final id in leaders) {
        expect(isHeaterCircuitDiyCannotCompleteLeader(id), isTrue, reason: id);
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
          closeResolveEligibility(
            safetyStopActive: false,
            primaryFailureModeId: id,
            verificationOutcome: VerificationOutcome.supported,
          ),
          CloseResolveEligibility.needsProfessional,
          reason: id,
        );
      }
    });
  });

  group('2) authoring import must not default DIY-resolve', () {
    test('omitted allowResolvedWhenConfirmed is false', () {
      final record = FailureModeAuthoringRecord.fromJson({
        'id': 'imported-pro-sibling',
        'title': 'Imported pro sibling',
        'applianceFamily': 'dryer',
        'symptomPhrasings': ['cold'],
        'immediateCause': 'cause',
        'rootCause': 'root',
        'contributingFactors': ['factor'],
        'evidenceSupports': [
          {'templateId': 'heat-observed', 'answer': 'No warmth'},
        ],
        'evidenceExcludes': [
          {'templateId': 'heat-observed', 'answer': 'Normal heat'},
        ],
        'commonMisdiagnoses': ['mis'],
        'firstLineQuestions': <Map<String, dynamic>>[],
        'verificationAsk': 'Still cold?',
        'verificationWhy': 'Pattern only',
        'verificationSteps': ['Look'],
        'safeGuidanceBoundary': ['Do not probe live terminals'],
        'stopProfessionalConditions': ['Any live testing'],
        'preventionActions': ['Keep the vent clear'],
        'toolsRequired': ['None'],
        'difficultyNotes': 'notes',
        'commonality': 'common',
        'safetyNotes': 'No live testing',
      });
      expect(record.allowResolvedWhenConfirmed, isFalse);
      expect(parseAllowResolvedWhenConfirmed(const {}), isFalse);
      expect(
        parseAllowResolvedWhenConfirmed({'allowResolvedWhenConfirmed': true}),
        isTrue,
      );
    });

    test('explicit true stays on DIY airflow; resettable cutoff stays DIY', () {
      KnowledgePackageRepository().loadById('dryer-core');
      expect(
        closePathForFailureMode('restricted-exhaust-airflow')!
            .allowResolvedWhenConfirmed,
        isTrue,
      );
      expect(
        closePathForFailureMode('accessible-thermal-reset')!
            .allowResolvedWhenConfirmed,
        isTrue,
      );
      const importer = FailureModeBatchImporter();
      final diy = importer.parseBatchJson('''
{
  "id": "explicit-diy-vent",
  "title": "Explicit DIY vent",
  "applianceFamily": "dryer",
  "symptomPhrasings": ["slow dry"],
  "immediateCause": "vent",
  "rootCause": "lint",
  "contributingFactors": ["filter"],
  "evidenceSupports": [
    { "templateId": "exterior-airflow", "answer": "Weak" }
  ],
  "evidenceExcludes": [
    { "templateId": "exterior-airflow", "answer": "Normal" }
  ],
  "commonMisdiagnoses": ["element"],
  "firstLineQuestions": [],
  "verificationAsk": "Stronger airflow?",
  "verificationWhy": "Vent was the cause",
  "verificationSteps": ["Clean the lint filter"],
  "safeGuidanceBoundary": ["Clean the lint filter"],
  "stopProfessionalConditions": ["Smoke"],
  "preventionActions": ["Clean the lint filter"],
  "toolsRequired": ["None"],
  "difficultyNotes": "DIY",
  "commonality": "common",
  "safetyNotes": "Unplug before moving the dryer",
  "allowResolvedWhenConfirmed": true
}
''').single;
      expect(diy.allowResolvedWhenConfirmed, isTrue);
    });

    testWidgets(
      'shipped heating-element (false, same as omitted import) is Pro recommended',
      (tester) async {
        final deps = AppDependencies(
          clock: () => DateTime.utc(2026, 8, 29, 16, 12),
        );
        await openDryerSession(tester, deps, 'Import Default House');
        await selectFailureMode(tester, 'heating-element-failed');
        await completeRepairReadinessIfPresent(tester);
        await completeGuidanceStepsIfPresent(tester);
        expect(
          closePathForFailureMode('heating-element-failed')!
              .allowResolvedWhenConfirmed,
          isFalse,
        );
        expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
        expect(find.text('Fixed'), findsNothing);
      },
    );
  });

  group('3) Safety Validator on household how-to before paint', () {
    const forbidden =
        'Measure live voltage at the heater terminals with a multimeter.';
    const prohibition =
        'Do not measure live voltage or bypass the thermal fuse.';

    test('filter strips forbidden how-to and keeps prohibition lines', () {
      expect(
        visibleHouseholdHowTo(forbidden, expertMode: false),
        isEmpty,
      );
      expect(
        visibleHouseholdHowTo(prohibition, expertMode: false),
        prohibition,
      );
      expect(isAlwaysForbiddenInstruction(forbidden), isTrue);
      expect(isSafetyLimitLanguage(prohibition), isTrue);
      final blocked = visibleGuidanceDisplayBlock(
        const GuidanceDisplayBlock(
          what: 'Live meter',
          how: forbidden,
          resultMeans: 'A reading',
          whenToStop: prohibition,
        ),
        expertMode: false,
      )!;
      expect(blocked.how, isEmpty);
      expect(blocked.whenToStop, prohibition);
    });

    testWidgets('forbidden LOOK FOR is not painted; do-not line stays',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectStepCard(
                step: _lintLookFor(forbidden),
                onChip: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(forbidden), findsNothing);
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectStepCard(
                step: _lintLookFor(prohibition),
                onChip: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(prohibition), findsOneWidget);
    });

    testWidgets('forbidden observation HOW is not painted; do-not stays',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HouseholdHowToText(
                  key: Key('observation-how'),
                  text: forbidden,
                  expertMode: false,
                ),
                HouseholdHowToText(
                  key: Key('observation-how-keep'),
                  text: prohibition,
                  expertMode: false,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text(forbidden), findsNothing);
      expect(find.text(prohibition), findsOneWidget);
      expect(
        tester.widget<HouseholdHowToText>(find.byKey(const Key('observation-how'))).text,
        forbidden,
      );
    });
  });

  group('4) Settings House Book wipe', () {
    testWidgets('cancel keeps data; confirm wipes and returns to first-run',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 16, 10),
        store: store,
      );
      deps.createHousehold('Wipe House');
      deps.addDryer(name: 'Laundry Room Dryer');
      expect(deps.appliancesForCurrentHousehold(), isNotEmpty);

      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));
      await tester.tap(find.byKey(const Key('home-settings-button')));
      await tester.pumpAndSettle();
      await scrollSettingsUntil(tester, const Key('settings-wipe-house-book'));
      expect(find.byKey(const Key('settings-wipe-house-book')), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-wipe-house-book')));
      await tester.pumpAndSettle();
      expect(find.text(UserFacingCopy.wipeHouseBookConfirmTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings-wipe-cancel')));
      await tester.pumpAndSettle();
      expect(deps.appliancesForCurrentHousehold(), isNotEmpty);
      expect(deps.firstRunComplete, isTrue);
      expect(find.byKey(const Key('first-run-screen')), findsNothing);

      await tester.tap(find.byKey(const Key('settings-wipe-house-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-wipe-confirm')));
      await tester.pumpAndSettle();

      expect(deps.householdRepository.listAll(), isEmpty);
      expect(deps.applianceRepository.listAll(), isEmpty);
      expect(deps.currentHousehold, isNull);
      expect(deps.firstRunComplete, isFalse);
      expect(find.byKey(const Key('first-run-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('first-run-skip-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create-household-button')), findsOneWidget);
      expect(find.byKey(const Key('empty-home-appliances')), findsNothing);
    });
  });
}
