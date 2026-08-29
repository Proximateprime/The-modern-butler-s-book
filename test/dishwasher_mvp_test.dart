import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dishwasher_easy_checks.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/knowledge_factory/dishwasher_mvp_v01.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

Evidence _dishwasherAnswer({
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
    collectedAt: DateTime.utc(2026, 8, 16, 19),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  test('dishwasher package is a primary-path v0.2 catalog', () {
    final package =
        KnowledgePackageRepository().loadByCategory('dishwasher').single;
    expect(package.id, dishwasherPackageId);
    expect(package.version, '0.2.3');
    expect(package.failureModes, hasLength(6));
    expect(
      package.failureModes.map((mode) => mode.id),
      containsAll([
        dishwasherCloggedFilterId,
        dishwasherDrainPathId,
        dishwasherDoorNotLatchedId,
        dishwasherCloggedSprayArmsId,
        dishwasherClosedSupplyId,
        dishwasherDoorSealLeakId,
      ]),
    );
    expect(
      package.symptoms.map((item) => item.id),
      containsAll([
        'standing-water',
        'wont-drain',
        'wont-fill',
        'wont-start',
        'poor-clean',
        'leaks',
        'door-wont-close',
      ]),
    );
    for (final mode in package.failureModes) {
      expect(mode.safetyNotes.toLowerCase(), contains('unplug'));
      expect(mode.safetyNotes.toLowerCase(), contains('electrical'));
      expect(mode.safetyNotes.toLowerCase(), contains('pump'));
    }
    var dishwasherSteps = 0;
    for (final mode in package.failureModes) {
      dishwasherSteps +=
          closePathForFailureMode(mode.id)!.safeGuidanceSteps.length;
    }
    expect(dishwasherSteps, 28);
  });

  test('dishwasher easy checks offer Already checked and keep Not sure', () {
    final package = buildDishwasherMvpPackage();
    for (final id in dishwasherEasyCheckTemplateIds) {
      final template =
          package.evidenceTemplates.firstWhere((item) => item.id == id);
      final choices = answerChoicesFor(template);
      expect(choices, contains(alreadyCheckedEasyCheckAnswer));
      expect(choices, contains('Not sure'));
    }
    expect(
      answerChoicesFor(
        package.evidenceTemplates.firstWhere(
          (item) => item.id == dishwasherComplaintTemplateId,
        ),
      ),
      isNot(contains(alreadyCheckedEasyCheckAnswer)),
    );
    expect(
      isDishwasherEasyCheckStep(
        'Look at the accessible tub filter under the lower rack. Do not open a '
        'sealed pump.',
      ),
      isTrue,
    );
    expect(
      isDishwasherEasyCheckStep(
        'Remove and rinse only the user-accessible filter at the tub bottom. '
        'Do not open a sealed pump or motor.',
      ),
      isFalse,
    );
    expect(
      isDishwasherEasyCheckStep(
        'Unplug the dishwasher (or switch off its breaker) before reaching into '
        'the tub.',
      ),
      isFalse,
    );
  });

  test('dryer package depth is unchanged', () {
    final dryer = KnowledgePackageRepository().loadById('dryer-core')!;
    expect(dryer.failureModes, hasLength(41));
    expect(dryer.version, '1.4.2');
  });

  test('standing water supports the filter path, not start', () {
    final package = buildDishwasherMvpPackage();
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        _dishwasherAnswer(
          templateId: dishwasherComplaintTemplateId,
          observation: 'What is the dishwasher doing?',
          answer: 'Standing water',
        ),
      ],
    );
    expect(standings[dishwasherCloggedFilterId]!.isSupported, isTrue);
    expect(standings[dishwasherDoorNotLatchedId]!.isSupported, isFalse);
  });

  test('drain easy checks start with the tub filter look', () {
    expect(
      dishwasherEasyCheckOrderForEvidence([
        _dishwasherAnswer(
          templateId: dishwasherComplaintTemplateId,
          observation: 'What is the dishwasher doing?',
          answer: "Won't drain",
        ),
      ]),
      [
        'dishwasher-filter-debris',
        'dishwasher-door-click',
        'dishwasher-drain-hose',
      ],
    );
  });

  test('clear tub filter excludes the filter mode', () {
    final package = buildDishwasherMvpPackage();
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        _dishwasherAnswer(
          templateId: dishwasherComplaintTemplateId,
          observation: 'What is the dishwasher doing?',
          answer: 'Standing water',
        ),
        _dishwasherAnswer(
          templateId: 'dishwasher-filter-debris',
          observation: 'filter',
          answer: 'No',
        ),
      ],
    );
    expect(standings[dishwasherCloggedFilterId]!.isSupported, isFalse);
  });

  test('dishwasher fill, leak, and door answers support matching modes', () {
    final package = buildDishwasherMvpPackage();

    FailureModeStanding standing(String answer, String modeId) {
      return evaluateFailureModeStandings(
        package: package,
        evidence: [
          _dishwasherAnswer(
            templateId: dishwasherComplaintTemplateId,
            observation: 'What is the dishwasher doing?',
            answer: answer,
          ),
        ],
      )[modeId]!;
    }

    expect(standing("Won't fill", dishwasherClosedSupplyId).isSupported, isTrue);
    expect(standing('Leaks', dishwasherDoorSealLeakId).isSupported, isTrue);
    expect(
      standing("Door won't close", dishwasherDoorNotLatchedId).isSupported,
      isTrue,
    );
    expect(standing('Poor clean', dishwasherCloggedSprayArmsId).isSupported, isTrue);
  });

  test('fill, spray, and leak close paths hide teardown until their own looks', () {
    expect(
      dishwasherEasyCheckOrderForEvidence([
        _dishwasherAnswer(
          templateId: dishwasherComplaintTemplateId,
          observation: 'What is the dishwasher doing?',
          answer: "Won't fill",
        ),
      ]),
      ['dishwasher-supply-open'],
    );
    expect(
      dishwasherEasyCheckOrderForEvidence([
        _dishwasherAnswer(
          templateId: dishwasherComplaintTemplateId,
          observation: 'What is the dishwasher doing?',
          answer: 'Poor clean',
        ),
      ]),
      ['dishwasher-filter-debris', 'dishwasher-spray-holes'],
    );
    expect(
      dishwasherEasyCheckOrderForEvidence([
        _dishwasherAnswer(
          templateId: dishwasherComplaintTemplateId,
          observation: 'What is the dishwasher doing?',
          answer: 'Leaks',
        ),
      ]),
      ['dishwasher-door-seal-leak'],
    );
    final door = closePathForFailureMode(dishwasherDoorNotLatchedId)!;
    expect(
      door.safeGuidanceSteps.join(' ').toLowerCase(),
      isNot(contains('tub filter')),
    );
  });

  test('dishwasher filter path hides rinse until the look check is done', () {
    final path = closePathForFailureMode(dishwasherCloggedFilterId)!;
    expect(closePathNeedsDishwasherEasyChecksFirst(path), isTrue);
    final ordered = orderDishwasherEasyChecksFirst(path.safeGuidanceSteps);
    expect(ordered.first.toLowerCase(), contains('look'));
    final gated = guidanceStepsForDishwasherEasyGate(
      steps: ordered,
      easyChecksSatisfied: false,
    );
    expect(gated.join(' ').toLowerCase(), isNot(contains('unplug')));
    expect(gated.join(' ').toLowerCase(), isNot(contains('remove and rinse')));
  });

  test('dishwasher close paths stay beginner-safe', () {
    final filter = closePathForFailureMode(dishwasherCloggedFilterId)!;
    final joined = filter.safeGuidanceSteps.join(' ').toLowerCase();
    expect(joined, contains('unplug'));
    expect(joined, contains('sealed'));
    expect(joined, isNot(contains('multimeter')));
    expect(joined, contains('do not'));
    for (final id in [
      dishwasherCloggedFilterId,
      dishwasherDrainPathId,
      dishwasherDoorNotLatchedId,
      dishwasherCloggedSprayArmsId,
      dishwasherClosedSupplyId,
      dishwasherDoorSealLeakId,
    ]) {
      final path = closePathForFailureMode(id)!;
      final text = path.safeGuidanceSteps.join(' ').toLowerCase();
      expect(text.contains('unplug') || text.contains('do not'), isTrue);
      expect(text, isNot(contains('live voltage')));
      expect(text, isNot(contains('multimeter')));
    }
  });

  test('add dishwasher starts a dishwasher-package session', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 19));
    deps.createHousehold('Dishwasher House');
    final dishwasher = deps.addDishwasher();
    expect(dishwasher.category, 'dishwasher');
    expect(dishwasher.name, 'Kitchen Dishwasher');
    expect(dishwasher.location, 'Kitchen');

    final sessionId = deps.startOrResumeSession(dishwasher);
    final session = deps.repairSessionRepository.getSession(sessionId)!;
    expect(session.packageId, dishwasherPackageId);
    expect(session.packageVersion, dishwasherPackageVersion);

    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the tub filter',
    );
    expect(outcome.closeKind, SessionCloseKind.fixed);
    expect(deps.repairHistoryForAppliance(dishwasher.id), hasLength(1));
  });

  testWidgets('home add dishwasher opens a session without dryer starter', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 19));
    await openDishwasherSession(tester, deps, 'Dishwasher UI House');
    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('What is the dishwasher doing?'), findsOneWidget);
  });

  testWidgets('dishwasher standing-water path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 19, 1));
    await openDishwasherSession(tester, deps, 'Dishwasher Fixed House');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-standing-water')),
    );
    await selectFailureMode(tester, dishwasherCloggedFilterId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Unplug the dishwasher'), findsNothing);
    await walkGuidanceUntilContaining(tester, 'Unplug the dishwasher');
    expect(find.textContaining('Unplug the dishwasher'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsOneWidget);
    await saveSessionOutcome(tester);

    final dishwasher = deps.appliancesForCurrentHousehold().single;
    final history = deps.repairHistoryForAppliance(dishwasher.id);
    expect(history, hasLength(1));
    expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
    expect(history.single.outcome.verified, isTrue);
    expect(history.single.outcome.startSymptom, 'Standing water');
  });

  testWidgets('dishwasher fill path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 10));
    await openDishwasherSession(tester, deps, 'Dishwasher Fill House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-fill')));
    await selectFailureMode(tester, dishwasherClosedSupplyId);
    await advanceClosePathFromConclusionIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final dishwasher = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(dishwasher.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('dishwasher poor-clean path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 10, 1));
    await openDishwasherSession(tester, deps, 'Dishwasher Clean House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-poor-clean')));
    await selectFailureMode(tester, dishwasherCloggedSprayArmsId);
    await advanceClosePathFromConclusionIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final dishwasher = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(dishwasher.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('dishwasher leak path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 10, 2));
    await openDishwasherSession(tester, deps, 'Dishwasher Leak House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-leaks')));
    await selectFailureMode(tester, dishwasherDoorSealLeakId);
    await advanceClosePathFromConclusionIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Look at the door seal'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final dishwasher = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(dishwasher.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('dishwasher door path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 10, 3));
    await openDishwasherSession(tester, deps, 'Dishwasher Door House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-start')));
    await selectFailureMode(tester, dishwasherDoorNotLatchedId);
    await advanceClosePathFromConclusionIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('feel or hear a click'), findsWidgets);
    expect(find.textContaining('Remove and rinse'), findsNothing);
    await completeGuidanceStepsIfPresent(tester);
    await tapConfirmedVerificationIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final dishwasher = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(dishwasher.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('dishwasher hazard yes hard-stops without Fixed', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 19, 2));
    await openDishwasherSession(tester, deps, 'Dishwasher Hazard House');
    await selectObservation(tester, 'hazard-observation');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
    expect(find.textContaining('fire or smoke'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
  });
}
