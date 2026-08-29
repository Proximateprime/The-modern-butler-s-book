import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('hazard observation forces professional hard stop', (
    tester,
  ) async {
    final fixedTime = DateTime.utc(2026, 7, 22, 15);
    final dependencies = AppDependencies(clock: () => fixedTime);

    await openDryerSession(tester, dependencies, 'Safety Household');

    await selectObservation(tester, 'hazard-observation');
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));

    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(find.text('Stop — Call a professional'), findsOneWidget);
    expect(find.text('Possible fire or smoke hazard'), findsOneWidget);
    expect(find.byKey(const Key('blocking-reason-line')), findsOneWidget);
    expect(
      find.text('This step is blocked for safety—call a pro.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('next-action-cue')), findsNothing);
    expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
    expect(find.byKey(const Key('failure-modes-tile')), findsNothing);
    expect(find.byKey(const Key('other-observations-picker')), findsNothing);

    await expandEvidenceHistory(tester);
    expect(find.textContaining('Answer: Yes'), findsOneWidget);

    expect(find.text('End Session — Needs professional'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
    expect(find.text('Calling a professional'), findsWidgets);
    expect(find.byKey(const Key('session-outcome-summary')), findsNothing);
  });
}
