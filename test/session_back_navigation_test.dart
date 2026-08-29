import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('Back returns to previous question and changing answer clears downstream evidence', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 26, 18),
    );
    await openDryerSession(tester, dependencies, 'Back Nav Household');

    await selectObservation(tester, 'drum-turns');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-turns-normally')),
    );

    await selectObservation(tester, 'heat-observed');
    expect(
      find.descendant(
        of: find.byKey(const Key('answer-choice-panel')),
        matching: find.byKey(const Key('observation-prompt-heat-observed')),
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.byKey(const Key('answer-choice-back')));
    expect(
      find.descendant(
        of: find.byKey(const Key('answer-choice-panel')),
        matching: find.byKey(const Key('observation-prompt-drum-turns')),
      ),
      findsOneWidget,
    );
    expect(find.text('Change this answer'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-does-not-turn')),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('answer-choice-panel')),
        matching: find.byKey(const Key('observation-prompt-heat-observed')),
      ),
      findsNothing,
    );

    await tapVisible(tester, find.byKey(const Key('evidence-history-tile')));
    expect(find.text('Answer: Does not turn'), findsOneWidget);
    expect(find.text('Answer: No warmth'), findsNothing);
  });

  testWidgets('Re-selecting the same answer while revising keeps downstream evidence', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 26, 18, 30),
    );
    await openDryerSession(tester, dependencies, 'Same Answer Household');

    await selectObservation(tester, 'drum-turns');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-turns-normally')),
    );

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));

    await expandEvidenceHistory(tester);
    await tapVisible(tester, find.text('Answer: Turns normally'));

    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-turns-normally')),
    );

    await expandEvidenceHistory(tester);
    expect(find.text('Answer: Turns normally'), findsOneWidget);
    expect(find.text('Answer: No warmth'), findsOneWidget);
  });

  testWidgets('Revising a prior answer recomputes ranking recommendations', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 5, 10),
    );
    await openDryerSession(tester, dependencies, 'Standing Revise Household');

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));
    await selectObservation(tester, 'cycle-heat-setting');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-yes-heat-cycle')),
    );
    await selectObservation(tester, 'recent-overheat');
    await tapVisible(
      tester,
      find.byKey(
        const Key('answer-choice-yes-very-hot-or-shut-off-from-heat'),
      ),
    );
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'weak');
    await selectObservation(tester, 'clothes-feel-after-cycle');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-cold-and-still-damp')),
    );

    expect(
      find.byKey(const Key('recommended-primary-label-thermal-fuse-open')),
      findsOneWidget,
    );

    await expandEvidenceHistory(tester);
    await tapVisible(
      tester,
      find.textContaining('Yes, very hot or shut off from heat'),
    );
    await tapVisible(tester, find.byKey(const Key('answer-choice-no')));

    expect(
      find.byKey(const Key('recommended-primary-label-thermal-fuse-open')),
      findsNothing,
    );

    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final sessionId =
        dependencies.repairSessionRepository.listAllSessions().single.id;
    final evidence =
        dependencies.buildDecisionContext(sessionId).evidence;
    final recommend = recommendPrimaryFailureModeId(
      standings: evaluateFailureModeStandings(
        package: package,
        evidence: evidence,
      ),
      evidence: evidence,
      templates: package.evidenceTemplates,
    );
    expect(recommend, isNot('thermal-fuse-open'));
  });
}
