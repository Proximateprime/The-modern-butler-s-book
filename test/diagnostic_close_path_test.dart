import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('dryer session reaches close path then resolves', (tester) async {
    final fixedTime = DateTime.utc(2026, 7, 22, 16);
    final dependencies = AppDependencies(clock: () => fixedTime);

    await openDryerSession(tester, dependencies, 'Close Path Household');

    await tapVisible(tester, find.byKey(const Key('package-summary-tile')));
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    expect(find.text('Observation prompts: ${package.evidenceTemplates.length}'), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(
      find.byKey(const Key('observation-prompt-dryer-response')),
      findsOneWidget,
    );

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));
    expect(
      find.byKey(const Key('observation-prompt-cycle-heat-setting')),
      findsWidgets,
    );

    await selectObservation(tester, 'cycle-heat-setting');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-yes-heat-cycle')),
    );
    await selectObservation(tester, 'recent-overheat');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no')));
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'normal');

    await selectFailureMode(tester, 'heating-element-failed');
    await chooseCallAProFromDecision(tester);
    await saveSessionOutcome(
      tester,
      choiceKey: const Key('outcome-needs-professional'),
    );

    expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
    expect(find.text('Needs a professional'), findsWidgets);
    expect(find.byKey(const Key('session-outcome-summary')), findsNothing);
  });
}
