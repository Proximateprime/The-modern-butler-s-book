import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  test('dryer-response template defines start-specific answer choices', () {
    final template =
        package.evidenceTemplates.firstWhere((item) => item.id == 'dryer-response');
    final choices = answerChoicesFor(template);
    expect(choices, contains('Nothing happens'));
    expect(choices, contains('Hums but does not start'));
    expect(choices, isNot(contains('Yes')));
  });

  test('heat-observed custom answers still drive ranking', () {
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        Evidence(
          id: 'e1',
          sessionId: 's1',
          applianceId: 'a1',
          type: EvidenceType.structuredAnswer,
          observation: 'Is there any warmth after the dryer has run briefly?',
          answer: 'No warmth',
          templateId: 'heat-observed',
          collectedAt: DateTime.utc(2026, 7, 24),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ],
    );
    expect(standings['heating-element-failed']!.isSupported, isTrue);
  });

  testWidgets('template-specific answers render and only one panel is active', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 8),
    );
    await openDryerSession(tester, dependencies, 'Answer Choices Household');

    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('What happens when you press Start?'), findsOneWidget);
    expect(find.text('Nothing happens'), findsOneWidget);
    expect(find.text('Starts normally'), findsOneWidget);
    expect(find.text('Sometimes'), findsNothing);

    await selectObservation(tester, 'heat-observed');

    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('No warmth'), findsOneWidget);
    expect(find.text('Normal heat'), findsOneWidget);
    expect(find.text('Nothing happens'), findsNothing);

    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));

    await expandEvidenceHistory(tester);
    expect(find.textContaining('Answer: No warmth'), findsOneWidget);
  });
}
