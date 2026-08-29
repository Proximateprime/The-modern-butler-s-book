import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/inspect_steps.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

Evidence _washerAnswer({
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
    collectedAt: DateTime.utc(2026, 8, 16, 23),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  test('washer package is a primary-path v0.2 catalog', () {
    final package =
        KnowledgePackageRepository().loadByCategory('washer').single;
    expect(package.id, washerPackageId);
    expect(package.version, '0.2.3');
    expect(package.failureModes, hasLength(9));
    expect(
      package.failureModes.map((mode) => mode.id),
      containsAll([
        washerCloggedDrainFilterId,
        washerDrainHoseId,
        washerClosedTapsId,
        washerCloggedInletScreensId,
        washerUnbalancedLoadId,
        washerLooseInletHoseId,
        washerDrainHoseNotSeatedId,
        washerDoorNotLatchedId,
        washerNoPowerOrLockId,
      ]),
    );
    expect(package.symptoms, hasLength(6));
    expect(
      package.symptoms.map((item) => item.id),
      containsAll([
        'wont-drain',
        'wont-fill',
        'wont-spin',
        'leaks',
        'wont-start',
        'door-wont-close',
      ]),
    );
    for (final mode in package.failureModes) {
      expect(mode.safetyNotes.toLowerCase(), contains('sealed'));
      expect(mode.safetyNotes.toLowerCase(), contains('electrical'));
    }
    var washerSteps = 0;
    for (final mode in package.failureModes) {
      washerSteps +=
          closePathForFailureMode(mode.id)!.safeGuidanceSteps.length;
    }
    expect(washerSteps, 41);
  });

  test('dryer package depth is unchanged', () {
    final dryer = KnowledgePackageRepository().loadById('dryer-core')!;
    expect(dryer.failureModes, hasLength(41));
    expect(dryer.version, '1.4.2');
  });

  test('washer drain answer supports drain-filter, not fill', () {
    final package = buildWasherMvpPackage();
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        _washerAnswer(
          templateId: washerComplaintTemplateId,
          observation: 'What is the washer doing?',
          answer: "Won't drain",
        ),
      ],
    );
    expect(standings[washerCloggedDrainFilterId]!.isSupported, isTrue);
    expect(standings[washerClosedTapsId]!.isSupported, isFalse);
  });

  test('drain-filter packed vs clear splits ranking', () {
    final package = buildWasherMvpPackage();
    final complaint = _washerAnswer(
      templateId: washerComplaintTemplateId,
      observation: 'What is the washer doing?',
      answer: "Won't drain",
    );
    final packed = evaluateFailureModeStandings(
      package: package,
      evidence: [
        complaint,
        _washerAnswer(
          templateId: 'washer-drain-filter-access',
          observation: 'filter',
          answer: 'Yes',
        ),
      ],
    );
    final clear = evaluateFailureModeStandings(
      package: package,
      evidence: [
        complaint,
        _washerAnswer(
          templateId: 'washer-drain-filter-access',
          observation: 'filter',
          answer: 'No',
        ),
      ],
    );
    expect(packed[washerCloggedDrainFilterId]!.net, greaterThan(0));
    expect(clear[washerCloggedDrainFilterId]!.isSupported, isFalse);
    expect(
      packed[washerCloggedDrainFilterId]!.net,
      greaterThan(clear[washerCloggedDrainFilterId]!.net),
    );
  });

  test('washer fill, spin, and leak answers support matching modes', () {
    final package = buildWasherMvpPackage();

    FailureModeStanding standing(String answer, String modeId) {
      return evaluateFailureModeStandings(
        package: package,
        evidence: [
          _washerAnswer(
            templateId: washerComplaintTemplateId,
            observation: 'What is the washer doing?',
            answer: answer,
          ),
        ],
      )[modeId]!;
    }

    expect(standing("Won't fill", washerClosedTapsId).isSupported, isTrue);
    expect(standing("Won't fill", washerCloggedInletScreensId).isSupported, isTrue);
    expect(
      standing("Won't fill", washerCloggedDrainFilterId).isSupported,
      isFalse,
    );
    expect(standing("Won't spin", washerUnbalancedLoadId).isSupported, isTrue);
    expect(standing('Leaks', washerLooseInletHoseId).isSupported, isTrue);
    expect(standing('Leaks', washerDrainHoseNotSeatedId).isSupported, isTrue);
    expect(
      standing("Won't start", washerDoorNotLatchedId).isSupported,
      isTrue,
    );
    expect(
      standing("Door won't close", washerDoorNotLatchedId).isSupported,
      isTrue,
    );
  });

  test('leak plus slipped hose ranks not-seated with a setup inspect chain', () {
    final package = buildWasherMvpPackage();
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        _washerAnswer(
          templateId: washerComplaintTemplateId,
          observation: 'What is the washer doing?',
          answer: 'Leaks',
        ),
        _washerAnswer(
          templateId: 'washer-standpipe-hose',
          observation: 'standpipe',
          answer: 'Yes',
        ),
      ],
    );
    expect(standings[washerDrainHoseNotSeatedId]!.isSupported, isTrue);
    expect(
      standings[washerDrainHoseNotSeatedId]!.net,
      greaterThan(standings[washerLooseInletHoseId]!.net),
    );
    final steps = inspectStepsForFailureMode(
      failureModeId: washerDrainHoseNotSeatedId,
      packageSteps: package.inspectSteps,
    );
    expect(
      steps.map((step) => step.id).toList(),
      [
        'inspect-washer-standpipe',
        'inspect-washer-drain-hose-config',
      ],
    );
    expect(steps.every((step) => step.noLiveElectrical), isTrue);
  });

  test('washer close paths stay beginner-safe', () {
    final drain = closePathForFailureMode(washerCloggedDrainFilterId)!;
    final joined = drain.safeGuidanceSteps.join(' ').toLowerCase();
    expect(joined, contains('unplug'));
    expect(joined, contains('sealed'));
    expect(joined, isNot(contains('multimeter')));
    expect(joined, isNot(contains('live voltage')));
    expect(
      FailureModeAuthoringRegistry.toolsRequiredFor(washerCloggedDrainFilterId)
          .join(' ')
          .toLowerCase(),
      isNot(contains('multimeter')),
    );
    for (final id in [
      washerCloggedDrainFilterId,
      washerDrainHoseId,
      washerClosedTapsId,
      washerCloggedInletScreensId,
      washerUnbalancedLoadId,
      washerLooseInletHoseId,
      washerDrainHoseNotSeatedId,
      washerDoorNotLatchedId,
      washerNoPowerOrLockId,
    ]) {
      final path = closePathForFailureMode(id)!;
      final text = path.safeGuidanceSteps.join(' ').toLowerCase();
      expect(text.contains('unplug') || text.contains('do not'), isTrue);
      expect(text, isNot(contains('live voltage')));
      expect(text, isNot(contains('multimeter')));
      expect(
        text.contains('sealed') ||
            text.contains('do not dismantle') ||
            text.contains('no live electrical'),
        isTrue,
      );
    }
  });

  test('add washer starts a washer-package session that can Fixed to memory', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    deps.createHousehold('Washer House');
    final washer = deps.addWasher();
    expect(washer.category, 'washer');
    expect(washer.name, 'Laundry Room Washer');

    final sessionId = deps.startOrResumeSession(washer);
    final session = deps.repairSessionRepository.getSession(sessionId)!;
    expect(session.packageId, washerPackageId);
    expect(session.packageVersion, washerPackageVersion);

    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the drain filter',
      preventionNote: 'Check pockets before washing',
    );
    expect(outcome.closeKind, SessionCloseKind.fixed);
    expect(outcome.summary, contains('Fixed'));
    expect(deps.repairHistoryForAppliance(washer.id), hasLength(1));
    expect(deps.hasInProgressSession(washer), isFalse);
  });

  test('washer open session survives persist and resume', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      store: store,
    );
    first.createHousehold('Washer Resume');
    final washer = first.addWasher();
    final sessionId = first.startOrResumeSession(washer);
    await first.flushPersist();

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      store: store,
    );
    await second.restore();
    expect(second.hasInProgressSession(washer), isTrue);
    expect(second.startOrResumeSession(washer), sessionId);
  });

  testWidgets('home add washer opens a session without dryer starter', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    await openWasherSession(tester, deps, 'Washer UI House');
    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('What is the washer doing?'), findsOneWidget);
  });

  testWidgets('washer drain path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 1));
    await openWasherSession(tester, deps, 'Washer Fixed House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, washerCloggedDrainFilterId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('feel or hear a click'), findsWidgets);
    expect(find.textContaining('Unplug the washer'), findsNothing);
    await walkGuidanceUntilContaining(tester, 'Unplug the washer');
    expect(find.textContaining('Unplug the washer'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsOneWidget);
    await saveSessionOutcome(tester);

    final washer = deps.appliancesForCurrentHousehold().single;
    final history = deps.repairHistoryForAppliance(washer.id);
    expect(history, hasLength(1));
    expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
  });

  testWidgets('washer fill path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 3));
    await openWasherSession(tester, deps, 'Washer Fill House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-fill')));
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
    await selectFailureMode(tester, washerClosedTapsId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await walkGuidanceUntilContaining(tester, 'Open both hot and cold taps');
    expect(find.textContaining('Open both hot and cold taps'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final washer = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(washer.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('washer spin path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 4));
    await openWasherSession(tester, deps, 'Washer Spin House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-spin')));
    await selectObservation(tester, 'washer-load-bunched');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
    await selectFailureMode(tester, washerUnbalancedLoadId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await walkGuidanceUntilContaining(tester, 'Redistribute clothes');
    expect(find.textContaining('Redistribute clothes'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final washer = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(washer.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('washer leak path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 5));
    await openWasherSession(tester, deps, 'Washer Leak House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-leaks')));
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
    await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
    await selectFailureMode(tester, washerLooseInletHoseId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await walkGuidanceUntilContaining(tester, 'Hand-tighten');
    expect(find.textContaining('Hand-tighten'), findsWidgets);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final washer = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(washer.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('washer door path verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 6));
    await openWasherSession(tester, deps, 'Washer Door House');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-start')));
    await selectFailureMode(tester, washerDoorNotLatchedId);
    await advanceClosePathFromConclusionIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('inspect-chip-doesnt-match')),
    );
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('feel or hear a click'), findsWidgets);
    expect(find.textContaining('Unplug the washer'), findsNothing);
    await completeGuidanceStepsIfPresent(tester);
    await tapConfirmedVerificationIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    final washer = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.repairHistoryForAppliance(washer.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  testWidgets('washer hazard yes hard-stops without Fixed', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 2));
    await openWasherSession(tester, deps, 'Washer Hazard House');
    await selectObservation(tester, 'hazard-observation');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
    expect(find.textContaining('fire or smoke'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
  });
}
