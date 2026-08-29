import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/fridge_easy_checks.dart';
import 'package:modern_butlers_book/knowledge_factory/fridge_mvp_v01.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

Evidence _fridgeAnswer({
  required String templateId,
  required String observation,
  required String answer,
}) {
  return Evidence(
    id: 'e-$templateId',
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: observation,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 16, 18),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

bool _forbidsSealedSystemWork(String text) {
  final lower = text.toLowerCase();
  expect(lower, isNot(contains('recharge')));
  expect(lower, isNot(contains('freon')));
  expect(lower, isNot(contains('manifold')));
  expect(lower, isNot(contains('evacuate the')));
  expect(lower, isNot(contains('add gas')));
  expect(lower, isNot(contains('pierce the refrigerant')));
  return lower.contains('sealed') && lower.contains('refrigerant');
}

const _allFridgeModeIds = [
  fridgeBlockedCoilsId,
  fridgeBlockedInternalVentsId,
  fridgeDoorGasketId,
  fridgeTempControlsId,
  fridgeCloggedDefrostDrainId,
  fridgeIceMakerSupplyId,
  fridgeIceBinJamId,
  fridgeUnlevelVibrationId,
  fridgeNoPowerId,
];

void main() {
  test('fridge package is a v1 observational catalog', () {
    final package =
        KnowledgePackageRepository().loadByCategory('fridge').single;
    expect(package.id, fridgePackageId);
    expect(package.version, '1.0.1');
    expect(package.failureModes, hasLength(9));
    expect(
      package.failureModes.map((mode) => mode.id),
      containsAll(_allFridgeModeIds),
    );
    expect(package.symptoms, hasLength(8));
    expect(
      package.symptoms.map((item) => item.id),
      containsAll([
        'not-cooling',
        'fridge-warm-freezer-cold',
        'too-cold',
        'water-leak',
        'ice-maker',
        'noisy',
        'door-wont-close',
        'wont-run',
      ]),
    );
    for (final mode in package.failureModes) {
      expect(_forbidsSealedSystemWork(mode.safetyNotes), isTrue);
      expect(mode.safetyNotes.toLowerCase(), contains('compressor'));
    }
    final catalog = [
      ...package.failureModes.map((mode) => mode.description),
      ...package.evidenceTemplates.map((item) => item.promptText),
      ...package.safeChecks.map((item) => '${item.label} ${item.description}'),
    ].join(' ');
    expect(_forbidsSealedSystemWork(catalog), isTrue);
    var steps = 0;
    for (final mode in package.failureModes) {
      steps += closePathForFailureMode(mode.id)!.safeGuidanceSteps.length;
    }
    expect(steps, 42);
  });

  test('dryer package depth is unchanged', () {
    final dryer = KnowledgePackageRepository().loadById('dryer-core')!;
    expect(dryer.failureModes, hasLength(41));
    expect(dryer.version, '1.4.2');
  });

  test('not-cooling supports dirty coils, not the leak path', () {
    final package = buildFridgeMvpPackage();
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        _fridgeAnswer(
          templateId: fridgeComplaintTemplateId,
          observation: 'What is the fridge doing?',
          answer: 'Not cooling',
        ),
      ],
    );
    expect(standings[fridgeBlockedCoilsId]!.isSupported, isTrue);
    expect(standings[fridgeCloggedDefrostDrainId]!.isSupported, isFalse);
  });

  test('fridge warm/freezer cold, too cold, door, and power map to modes', () {
    final package = buildFridgeMvpPackage();

    FailureModeStanding standing(String answer, String modeId) {
      return evaluateFailureModeStandings(
        package: package,
        evidence: [
          _fridgeAnswer(
            templateId: fridgeComplaintTemplateId,
            observation: 'What is the fridge doing?',
            answer: answer,
          ),
        ],
      )[modeId]!;
    }

    expect(
      standing('Fridge warm, freezer cold', fridgeBlockedInternalVentsId)
          .isSupported,
      isTrue,
    );
    expect(standing('Too cold', fridgeTempControlsId).isSupported, isTrue);
    expect(standing("Door won't close", fridgeDoorGasketId).isSupported, isTrue);
    expect(standing("Won't run", fridgeNoPowerId).isSupported, isTrue);
    expect(standing('Ice maker', fridgeIceBinJamId).isSupported, isTrue);
  });

  test('coil path hides vacuum until observational looks are done', () {
    final path = closePathForFailureMode(fridgeBlockedCoilsId)!;
    expect(closePathNeedsFridgeEasyChecksFirst(path), isTrue);
    final ordered = orderFridgeEasyChecksFirst(path.safeGuidanceSteps);
    expect(ordered.first.toLowerCase(), contains('temperature'));
    final gated = guidanceStepsForFridgeEasyGate(
      steps: ordered,
      easyChecksSatisfied: false,
    );
    expect(gated.join(' ').toLowerCase(), isNot(contains('vacuum')));
    expect(
      gated.join(' ').toLowerCase(),
      isNot(contains('unplug the fridge')),
    );
  });

  test('fridge easy checks offer Already checked', () {
    final package = buildFridgeMvpPackage();
    for (final id in fridgeEasyCheckTemplateIds) {
      final template =
          package.evidenceTemplates.firstWhere((item) => item.id == id);
      final choices = answerChoicesFor(template);
      expect(choices, contains(alreadyCheckedEasyCheckAnswer));
      expect(choices, contains('Not sure'));
    }
  });

  test('fridge close paths never instruct refrigerant or sealed-system work', () {
    for (final id in _allFridgeModeIds) {
      final path = closePathForFailureMode(id)!;
      final joined = [
        path.verificationAsk,
        path.verificationWhy,
        ...path.safeGuidanceSteps,
      ].join(' ').toLowerCase();
      expect(joined, contains('unplug'));
      expect(_forbidsSealedSystemWork(joined), isTrue);
      expect(joined, contains('do not add, recover, or handle refrigerant'));
      expect(joined, isNot(contains('live voltage')));
      expect(joined, isNot(contains('multimeter')));
      expect(joined, isNot(contains('start relay')));
    }
  });

  test('add fridge starts a fridge-package session', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 18));
    deps.createHousehold('Fridge House');
    final fridge = deps.addFridge();
    expect(fridge.category, 'fridge');
    expect(fridge.name, 'Kitchen Fridge');
    expect(fridge.location, 'Kitchen');

    final sessionId = deps.startOrResumeSession(fridge);
    final session = deps.repairSessionRepository.getSession(sessionId)!;
    expect(session.packageId, fridgePackageId);
    expect(session.packageVersion, fridgePackageVersion);

    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the accessible coils',
    );
    expect(outcome.closeKind, SessionCloseKind.fixed);
    expect(deps.repairHistoryForAppliance(fridge.id), hasLength(1));
  });

  testWidgets('home add fridge opens a session without dryer starter', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 18));
    await openFridgeSession(tester, deps, 'Fridge UI House');
    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('What is the fridge doing?'), findsOneWidget);
  });

  testWidgets('fridge not-cooling path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 18, 1));
    await openFridgeSession(tester, deps, 'Fridge Fixed House');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-not-cooling')),
    );
    await selectFailureMode(tester, fridgeBlockedCoilsId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Unplug the fridge'), findsNothing);
    await walkGuidanceUntilContaining(tester, 'Unplug the fridge');
    expect(find.textContaining('Unplug the fridge'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsOneWidget);
    await saveSessionOutcome(tester);

    final fridge = deps.appliancesForCurrentHousehold().single;
    final history = deps.repairHistoryForAppliance(fridge.id);
    expect(history, hasLength(1));
    expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
  });
}
