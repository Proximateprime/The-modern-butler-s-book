import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('Path 1 — no-heat primary verification Confirmed resolves', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 22, 18),
    );
    await openDryerSession(tester, dependencies, 'No Heat Household');

    await selectObservation(tester, 'drum-turns');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-turns-normally')),
    );

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));

    await selectFailureMode(tester, 'heating-element-failed');
    await reachClosePathVerificationIfPresent(tester);

    expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
    expect(find.byKey(const Key('verification-card')), findsNothing);
    expect(find.text('Hand off to a qualified technician'), findsNothing);

    await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));
    expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    await saveSessionOutcome(
      tester,
      choiceKey: const Key('outcome-needs-professional'),
    );

    expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
    expect(find.text('Needs a professional'), findsWidgets);
  });

  testWidgets('Path 1 — Not confirmed blocks Resolved', (tester) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 22, 18, 5),
    );
    await openDryerSession(tester, dependencies, 'Not Confirmed Household');

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));

    await selectFailureMode(tester, 'heating-element-failed');
    await reachClosePathVerificationIfPresent(tester);

    expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));

    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
    expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    await saveSessionOutcome(
      tester,
      choiceKey: const Key('outcome-needs-professional'),
    );
    expect(find.text('Needs a professional'), findsWidgets);
  });

  testWidgets('Path 2 — vent restriction close path resolves', (tester) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 22, 19),
    );
    await openDryerSession(tester, dependencies, 'Vent Household');

    await selectObservation(tester, 'clothes-remain-damp');
    await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));

    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'weak');

    await selectFailureMode(tester, 'restricted-exhaust-airflow');

    await reachClosePathVerificationIfPresent(tester);
    expect(find.byKey(const Key('verification-ask')), findsOneWidget);
    expect(find.byKey(const Key('close-answer-choice-panel')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));

    expect(find.text('Fixed'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);
    expect(find.text('Fixed'), findsWidgets);
  });

  testWidgets('Path 4 — weak evidence keeps Unresolved available', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 22, 20),
    );
    await openDryerSession(tester, dependencies, 'Weak Evidence Household');

    expect(find.byKey(const Key('verification-card')), findsNothing);
    expect(find.text('Unresolved'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
    expect(find.byKey(const Key('outcome-unresolved')), findsOneWidget);
    await saveSessionOutcome(
      tester,
      choiceKey: const Key('outcome-unresolved'),
    );
    expect(find.text('Not fixed'), findsWidgets);
  });
}
