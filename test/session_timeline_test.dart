import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/session_timeline.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

Evidence _evidence({
  required String id,
  required String observation,
  required String answer,
  required String templateId,
}) {
  return Evidence(
    id: id,
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: observation,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 16, 20),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  test('timeline lists answered observations in order and skips verification', () {
    final items = sessionTimelineObservations([
      _evidence(
        id: 'e0',
        observation: 'starter',
        answer: 'No heat',
        templateId: 'problem-starter-complaint',
      ),
      _evidence(
        id: 'e1',
        observation: 'Were they still damp?',
        answer: 'Still damp',
        templateId: 'clothes-remain-damp',
      ),
      _evidence(
        id: 'e2',
        observation: 'Verify the fuse path',
        answer: 'Confirmed',
        templateId: 'close-verify-thermal-fuse-open',
      ),
      _evidence(
        id: 'e3',
        observation: 'How strong is airflow?',
        answer: 'Weak',
        templateId: 'exterior-airflow',
      ),
    ]);

    expect(items, hasLength(3));
    expect(items[0].prompt, 'What you noticed');
    expect(items[0].answer, 'No heat');
    expect(items[1].answer, 'Still damp');
    expect(items[2].answer, 'Weak');
  });

  test('leader why sentence uses standing data without scores', () {
    expect(
      leaderWhySentence(
        leaderLabel: 'Restricted exhaust airflow',
        leaderStanding: const FailureModeStanding(
          supportCount: 3,
          excludeCount: 0,
        ),
        runnerUpStanding: const FailureModeStanding(
          supportCount: 1,
          excludeCount: 0,
        ),
      ),
      'Restricted exhaust airflow is leading because more of your answers '
      'match it than the other possibilities.',
    );
    expect(
      leaderWhySentence(
        leaderLabel: 'Heating element failed',
        leaderStanding: const FailureModeStanding(
          supportCount: 0,
          excludeCount: 0,
        ),
      ),
      isNull,
    );
  });

  testWidgets('diagnosis How we got here is collapsed until opened', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 20));
    await openDryerSession(tester, deps, 'Timeline Diagnosis');
    await selectObservation(tester, 'clothes-remain-damp');
    await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'weak');
    await selectFailureMode(tester, 'restricted-exhaust-airflow');

    final tile = find.byKey(const Key('how-we-got-here-tile'));
    expect(tile, findsOneWidget);
    expect(
      tester.widget<ExpansionTile>(tile).initiallyExpanded,
      isFalse,
    );

    await tapVisible(tester, tile);
    expect(find.text('Still damp'), findsWidgets);
    expect(find.text('Weak'), findsWidgets);
    expect(find.byKey(const Key('how-we-got-here-leader-why')), findsOneWidget);
    expect(find.textContaining('is leading because'), findsOneWidget);
  });

  testWidgets('Done screen includes collapsed How we got here', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 20));
    await openDryerSession(tester, deps, 'Timeline Done');
    await selectObservation(tester, 'clothes-remain-damp');
    await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'weak');
    await selectFailureMode(tester, 'restricted-exhaust-airflow');
    await completeRepairReadinessIfPresent(tester);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-resolved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('completion-done-screen')), findsOneWidget);
    final tile = find.byKey(const Key('how-we-got-here-tile'));
    expect(tile, findsOneWidget);
    expect(
      tester.widget<ExpansionTile>(tile).initiallyExpanded,
      isFalse,
    );

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Still damp'), findsWidgets);
    expect(find.byKey(const Key('how-we-got-here-leader-why')), findsOneWidget);
  });
}
