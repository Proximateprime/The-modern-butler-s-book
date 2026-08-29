import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/pro_handoff.dart';
import 'package:modern_butlers_book/helpers/repair_log_share.dart';
import 'package:modern_butlers_book/helpers/session_timeline.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  late List<String> shared;
  late List<String> copied;

  setUp(() {
    shared = <String>[];
    copied = <String>[];
    repairLogShareHandler = (text) async {
      shared.add(text);
    };
    repairLogCopyHandler = (text) async {
      copied.add(text);
    };
  });

  tearDown(() {
    repairLogShareHandler = shareRepairLogViaSystem;
    repairLogCopyHandler = copyRepairLogToClipboard;
  });

  test('handoff lists observations, leader, tried steps, and safety notes', () {
    final text = formatProHandoffSummary(
      applianceName: 'Laundry Room Dryer',
      manufacturer: 'Demo Manufacturer',
      modelNumber: 'DRY-100',
      date: DateTime.utc(2026, 8, 16, 18),
      symptom: 'No heat',
      observations: const [
        SessionTimelineObservation(
          prompt: 'Is there any warmth after the dryer has run briefly?',
          answer: 'No warmth',
        ),
      ],
      leaderHypothesis: 'Heating element open or failed',
      alreadyTried: alreadyTriedStepsForLeader('heating-element-failed'),
      safetyNotes: safetyNotesForLeader(
        failureModeId: 'heating-element-failed',
      ),
      householdNote: 'Calling the shop Monday',
    );

    expect(text, contains('Technician handoff'));
    expect(text, contains('not a diagnosis'));
    expect(text, contains('Date: 2026-08-16'));
    expect(text, contains('Appliance: Laundry Room Dryer'));
    expect(text, contains('Demo Manufacturer DRY-100'));
    expect(text, contains('Symptom: No heat'));
    expect(text, contains('What we noticed'));
    expect(
      text,
      contains(
        'Is there any warmth after the dryer has run briefly?: No warmth',
      ),
    );
    expect(text, contains('Leader hypothesis'));
    expect(text, contains('Heating element open or failed'));
    expect(text, contains('What was already tried'));
    expect(text, contains('Do not probe live heater terminals'));
    expect(text, contains('Safety notes'));
    expect(text.toLowerCase(), contains('live electrical'));
    expect(text, contains('Calling the shop Monday'));
    expect(text, isNot(contains('http')));
  });

  test('empty optional sections stay plain language, not a dump', () {
    final text = formatProHandoffSummary(
      applianceName: 'Dryer 2',
      date: null,
      symptom: null,
      observations: const [],
      leaderHypothesis: null,
      alreadyTried: const [],
      safetyNotes: null,
    );

    expect(text, contains('Symptom: —'));
    expect(text, contains('Leader hypothesis'));
    expect(text, contains('• None recorded'));
    expect(text, contains(defaultProHandoffSafetyNotes));
    expect(text, isNot(contains('Household note')));
  });

  testWidgets(
    'calling a professional shows a shareable handoff, then export uses it',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 16, 22),
      );
      await openDryerSession(tester, deps, 'Pro Handoff House');

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectFailureMode(tester, 'heating-element-failed');
      await reachClosePathVerificationIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('outcome-needs-professional')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('outcome-note-field')),
        'Calling Monday',
      );
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
      expect(find.text(UserFacingCopy.proHandoffLead), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Technician handoff'),
        ),
        findsNothing,
      );
      final preview = tester.widget<SelectableText>(
        find.byKey(const Key('pro-handoff-preview')),
      );
      final body = preview.data ?? '';
      expect(body, contains('Technician handoff'));
      expect(body, contains('What we noticed'));
      expect(body, contains('No warmth'));
      expect(body, contains('Leader hypothesis'));
      expect(body, contains('What was already tried'));
      expect(body, contains('Safety notes'));
      expect(body, contains('Calling Monday'));

      await tapVisible(tester, find.byKey(const Key('pro-handoff-share')));
      expect(shared, hasLength(1));
      expect(shared.single, contains('No warmth'));
      expect(shared.single, contains('Safety notes'));

      await tapVisible(tester, find.byKey(const Key('pro-handoff-copy')));
      expect(copied, hasLength(1));
      expect(copied.single, contains('Calling Monday'));

      await tester.ensureVisible(find.byKey(const Key('completion-save-home')));
      await tapVisible(tester, find.byKey(const Key('completion-save-home')));
      await tester.pumpAndSettle();

      expect(find.text('Needs a professional'), findsWidgets);
      final sessionId = deps.recentSessionOutcomes().single.outcome.sessionId;
      await tester.tap(find.byKey(Key('export-repair-$sessionId')));
      await tester.pumpAndSettle();
      expect(shared, hasLength(2));
      expect(shared.last, contains('Technician handoff'));
      expect(shared.last, contains('What we noticed'));
      expect(shared.last, isNot(contains('http')));
    },
  );
}
