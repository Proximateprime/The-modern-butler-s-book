import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
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
    expect(find.byKey(const Key('safety-stop-title')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('safety-stop-title'))).data,
      'Needs a professional',
    );
    expect(find.text('Stop — Call a professional'), findsNothing);
    expect(find.textContaining('Possible fire or smoke hazard'), findsWidgets);
    expect(find.textContaining('Unplug if it is safe'), findsOneWidget);
    expect(find.textContaining('ventilate'), findsOneWidget);
    expect(find.textContaining('do not keep running'), findsOneWidget);
    expect(find.byKey(const Key('blocking-reason-line')), findsOneWidget);
    expect(
      find.text('This step is blocked for safety — Needs a professional.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('next-action-cue')), findsNothing);
    expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
    expect(find.byKey(const Key('failure-modes-tile')), findsNothing);
    expect(find.byKey(const Key('other-observations-picker')), findsNothing);

    await expandEvidenceHistory(tester);
    expect(find.textContaining('Answer: Yes'), findsOneWidget);

    expect(find.byKey(const Key('end-session-button')), findsOneWidget);
    final dryer = dependencies.appliancesForCurrentHousehold().single;
    final sessionId = dependencies.startOrResumeSession(dryer);
    expect(
      dependencies.buildDecisionContext(sessionId).safetyLevel,
      'stop',
    );

    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    expect(find.byKey(const Key('outcome-note-field')), findsOneWidget);
    expect(find.byKey(const Key('recent-activity-title')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('outcome-save-button')));
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
    expect(find.byKey(const Key('pro-handoff-preview')), findsOneWidget);
  });

  test('official stop copy is shared', () {
    expect(
      UserFacingCopy.voiceHazardConfirm,
      UserFacingCopy.safetyStopOfficial,
    );
    expect(UserFacingCopy.safetyStopOfficial.toLowerCase(), contains('unplug'));
    expect(
      UserFacingCopy.safetyStopOfficial.toLowerCase(),
      contains('ventilate'),
    );
    expect(
      safetyStopDisplayCopy(
        const SafetyStop(reason: 'Possible fire or smoke hazard'),
      ),
      contains(UserFacingCopy.safetyStopOfficial),
    );
  });
}
