import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/root_cause_memory.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/ui/session_outcome_screen.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('confirmed root cause is user text, seed, or omitted — never guessed', () {
    expect(
      confirmedRootCause(
        notSure: true,
        suggested: 'Packed lint',
        custom: 'Packed lint',
      ),
      isNull,
    );
    expect(
      confirmedRootCause(
        notSure: false,
        suggested: 'Packed lint',
        custom: 'Skipped cleaning',
      ),
      'Skipped cleaning',
    );
    expect(
      confirmedRootCause(
        notSure: false,
        suggested: 'Packed lint',
        custom: '  ',
      ),
      'Packed lint',
    );
  });

  test('confirmed memory items keep selected chips plus extra lines', () {
    expect(
      confirmedMemoryItems(
        selected: const ['Skipped filter cleaning'],
        extraLines: 'Tissues in pockets\nSkipped filter cleaning',
      ),
      ['Skipped filter cleaning', 'Tissues in pockets'],
    );
  });

  test('Fixed outcome stores user root-cause fields on the memory row', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14));
    deps.createHousehold('Root Cause House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);

    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Heating element open',
      rootCause: 'Age after a restricted vent overheat',
      contributingFactors: const ['Weak exterior airflow', 'Lint overdue'],
      preventiveActions: const ['Clean the lint filter every load'],
    );

    expect(outcome.immediateCause, 'Heating element open');
    expect(outcome.rootCause, 'Age after a restricted vent overheat');
    expect(outcome.contributingFactors, [
      'Weak exterior airflow',
      'Lint overdue',
    ]);
    expect(outcome.preventiveActions, ['Clean the lint filter every load']);

    final stored = deps.repairHistoryForAppliance(dryer.id).single.outcome;
    expect(stored.immediateCause, outcome.immediateCause);
    expect(stored.rootCause, outcome.rootCause);
    expect(stored.contributingFactors, outcome.contributingFactors);
    expect(stored.preventiveActions, outcome.preventiveActions);
  });

  test('package prevention seeds when the user leaves actions blank', () {
    final seed = rootCauseMemorySeed(
      failureModeId: 'clogged-washer-drain-filter',
    );
    expect(seed.preventiveActions, isNotEmpty);

    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14, 5));
    deps.createHousehold('Seed House');
    final washer = deps.addWasher();
    final sessionId = deps.startOrResumeSession(washer);
    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Debris in the drain filter',
    );
    expect(outcome.preventiveActions, isNotEmpty);
  });

  test('explicit empty prevention is not filled from the package', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 17));
    deps.createHousehold('Empty Prevention House');
    final washer = deps.addWasher();
    final sessionId = deps.startOrResumeSession(washer);
    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Debris in the drain filter',
      rootCause: '',
      contributingFactors: const [],
      preventiveActions: const [],
    );
    expect(outcome.rootCause, isNull);
    expect(outcome.contributingFactors, isEmpty);
    expect(outcome.preventiveActions, isEmpty);
  });

  test('root-cause memory survives persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 17, 14, 10);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Persist Root');
    final dryer = first.addDryer();
    final sessionId = first.startOrResumeSession(dryer);
    first.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Open heating element',
      rootCause: 'Overheat from a crushed vent',
      contributingFactors: const ['Exterior hood blocked'],
      preventiveActions: const ['Keep the vent path clear'],
    );
    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    final stored = second.repairHistoryForAppliance(dryer.id).single.outcome;
    expect(stored.immediateCause, 'Open heating element');
    expect(stored.rootCause, 'Overheat from a crushed vent');
    expect(stored.contributingFactors, ['Exterior hood blocked']);
    expect(stored.preventiveActions, ['Keep the vent path clear']);
  });

  test('prior hint uses latest Fixed cause and ignores the open session', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14, 15));
    deps.createHousehold('Hint House');
    final dryer = deps.addDryer();
    final first = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: first,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Lint screen packed',
      rootCause: 'Skipped cleaning',
    );
    final open = deps.startOrResumeSession(dryer);
    final hint = priorRootCauseHint(
      history: deps.repairHistoryForAppliance(dryer.id),
      excludeSessionId: open,
    );
    expect(hint?.immediateCause, 'Lint screen packed');
    expect(hint?.rootCause, 'Skipped cleaning');
  });

  testWidgets('Fixed form captures structured root-cause fields', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14, 20));
    deps.createHousehold('Form House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SessionOutcomeScreen(
          dependencies: deps,
          appliance: dryer,
          sessionId: sessionId,
          eligibility: CloseResolveEligibility.allowResolved,
          rankingLeaderLabel: 'Heating element failed',
          rankingLeaderFailureModeId: 'heating-element-failed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('outcome-resolved')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-root-cause-field')), findsOneWidget);
    expect(find.byKey(const Key('outcome-root-unknown')), findsOneWidget);
    expect(find.byKey(const Key('outcome-factor-chip-0')), findsOneWidget);
    expect(find.byKey(const Key('outcome-prevention-chip-0')), findsOneWidget);
    expect(find.byKey(const Key('outcome-update-maintenance')), findsOneWidget);
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('outcome-prevention-chip-0')))
          .selected,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const Key('outcome-what-fixed-field')),
      'Heating element open',
    );
    await tester.enterText(
      find.byKey(const Key('outcome-root-cause-field')),
      'Age after overheating',
    );
    await tester.enterText(
      find.byKey(const Key('outcome-contributing-field')),
      'Weak vent\nSkipped lint cleaning',
    );
    await tester.enterText(
      find.byKey(const Key('outcome-prevention-field')),
      'Clean the lint filter every load',
    );
    await tester.ensureVisible(find.byKey(const Key('outcome-update-maintenance')));
    await tester.tap(find.byKey(const Key('outcome-update-maintenance')));
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('outcome-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final outcome = deps.outcomeForSession(sessionId)!;
    expect(outcome.immediateCause, 'Heating element open');
    expect(outcome.rootCause, 'Age after overheating');
    expect(
      outcome.contributingFactors,
      containsAll([
        'Age and thermal cycling of the element',
        'Weak vent',
        'Skipped lint cleaning',
      ]),
    );
    expect(
      outcome.preventiveActions,
      containsAll([
        'Keep the vent and lint path clear to reduce heater stress',
        'Clean the lint filter every load',
      ]),
    );
    expect(
      deps.maintenanceRemindersForAppliance(dryer.id).any(
        (item) => item.sessionId == sessionId,
      ),
      isTrue,
    );
  });

  testWidgets('history detail shows stored root-cause memory', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14, 25));
    deps.createHousehold('History Detail House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Heating element open',
      rootCause: 'Age after overheating',
      contributingFactors: const ['Weak vent', 'Skipped lint cleaning'],
      preventiveActions: const ['Clean the lint filter every load'],
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          dependencies: deps,
          appliance: dryer,
          sessionId: sessionId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-outcome-summary')), findsOneWidget);
    expect(find.textContaining('What failed: Heating element open'), findsOneWidget);
    expect(find.byKey(const Key('outcome-root-cause')), findsOneWidget);
    expect(find.text('Age after overheating'), findsOneWidget);
    expect(find.text('• Weak vent'), findsOneWidget);
    expect(find.text('• Clean the lint filter every load'), findsOneWidget);
  });

  testWidgets(
    'next session shows prior root cause as a hint and still asks for evidence',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14, 30));
      deps.createHousehold('Hint UI House');
      final dryer = deps.addDryer();
      final first = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: first,
        closeKind: SessionCloseKind.fixed,
        immediateCause: 'Packed lint screen',
        rootCause: 'Filter not cleaned',
      );

      await prepareTallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appliance-detail-start-repair')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('prior-root-cause-hint')), findsOneWidget);
      expect(find.text(UserFacingCopy.priorRootCauseHintBody), findsOneWidget);
      expect(find.text('Packed lint screen'), findsOneWidget);
      expect(
        find.text('Filter not cleaned'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('problem-starter-panel')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(
        deps.repairSessionRepository
            .getSession(deps.startOrResumeSession(dryer))!
            .currentState
            .name,
        'evidenceCollection',
      );
    },
  );

  testWidgets(
    'verified Fixed root and prevention show on appliance history after restore',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = () => DateTime.utc(2026, 8, 22, 18);
      final deps = AppDependencies(clock: clock, store: store);
      await openDryerSession(tester, deps, 'History Memory House');
      await selectFailureMode(tester, 'clogged-lint-pathway');
      await reachClosePathVerificationIfPresent(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-confirmed')),
      );
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('outcome-resolved')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('outcome-root-cause-field')),
        'Skipped cleaning packed the filter slot',
      );
      await tester.enterText(
        find.byKey(const Key('outcome-prevention-field')),
        'Clean the lint screen every load',
      );
      final save = find.byKey(const Key('outcome-save-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final goHome = find.byKey(const Key('completion-save-home'));
      if (goHome.evaluate().isNotEmpty) {
        await tapVisible(tester, goHome);
      }
      await deps.flushPersist();

      final first = deps.repairHistoryForAppliance(
        deps.appliancesForCurrentHousehold().single.id,
      ).single.outcome;
      expect(first.rootCause, 'Skipped cleaning packed the filter slot');
      expect(
        first.preventiveActions,
        contains('Clean the lint screen every load'),
      );

      final restored = AppDependencies(clock: clock, store: store);
      await restored.restore();
      final dryer = restored.appliancesForCurrentHousehold().single;
      final stored =
          restored.repairHistoryForAppliance(dryer.id).single.outcome;
      expect(stored.rootCause, 'Skipped cleaning packed the filter slot');
      expect(
        stored.preventiveActions,
        contains('Clean the lint screen every load'),
      );

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: restored)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Skipped cleaning packed the filter slot'),
        findsOneWidget,
      );
      expect(find.textContaining('Prevent:'), findsOneWidget);
      expect(
        find.textContaining('Clean the lint filter before every load'),
        findsOneWidget,
      );
    },
  );
}
