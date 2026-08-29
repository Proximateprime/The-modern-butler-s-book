import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  const ranking = RankingService();
  const reasoning = DiagnosticReasoning();

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-${answer.hashCode}',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: templateId,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 8, 12),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  Evidence starterNoHeat() {
    return Evidence(
      id: 'e-starter',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.textObservation,
      observation: "What's going on with the dryer?",
      answer: 'No heat',
      templateId: problemStarterComplaintTemplateId,
      collectedAt: DateTime.utc(2026, 8, 12),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('golden path ranking and close path', () {
    test('compatible overheat + weak air path ranks fuse at or above element', () {
      final recorded = [
        starterNoHeat(),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(
          templateId: 'recent-overheat',
          answer: recentOverheatYesAnswer,
        ),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
      ];
      final snapshot = ranking.evaluate(package: package, evidence: recorded);
      final fuseIndex = snapshot.orderedFailureModes.indexWhere(
        (mode) => mode.id == 'thermal-fuse-open',
      );
      final elementIndex = snapshot.orderedFailureModes.indexWhere(
        (mode) => mode.id == 'heating-element-failed',
      );
      expect(fuseIndex, lessThan(elementIndex));
      expect(
        snapshot.standings['thermal-fuse-open']!.net,
        greaterThanOrEqualTo(snapshot.standings['heating-element-failed']!.net),
      );
      expect(
        snapshot.clearLeaderFailureModeId ??
            snapshot.orderedFailureModes.first.id,
        'thermal-fuse-open',
      );
    });

    test('Not sure on heat-observed is not the same as No warmth', () {
      final noWarmth = evaluateFailureModeStandings(
        package: package,
        evidence: [evidence(templateId: 'heat-observed', answer: 'No warmth')],
      );
      final notSure = evaluateFailureModeStandings(
        package: package,
        evidence: [evidence(templateId: 'heat-observed', answer: 'Not sure')],
      );
      expect(noWarmth['thermal-fuse-open']!.supportCount, greaterThan(0));
      expect(notSure['thermal-fuse-open']!.supportCount, 0);
      expect(notSure['heating-element-failed']!.supportCount, 0);
    });

    test('fuse leader binds fuse verification and actionable guidance', () {
      clearImportedClosePaths();
      KnowledgePackageRepository().loadById('dryer-core');
      final recorded = [
        starterNoHeat(),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(
          templateId: 'recent-overheat',
          answer: recentOverheatYesAnswer,
        ),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Cold and still damp',
        ),
      ];
      final result = reasoning.evaluate(package: package, evidence: recorded);
      expect(result.closePath?.failureModeId, 'thermal-fuse-open');

      final ask = result.closePath!.verificationAsk.toLowerCase();
      expect(ask, contains('still no warmth'));
      expect(ask, isNot(contains('is warmth restored')));

      final steps = result.closePath!.safeGuidanceSteps.join(' ').toLowerCase();
      expect(steps, anyOf(contains('unplug'), contains('breaker')));
      expect(steps, contains('panel'));
      expect(steps, contains('replace'));
      expect(steps, contains('vent'));
      expect(steps, anyOf(contains('do not measure live'), contains('jumper')));
    });
  });

  testWidgets('session start No heat never opens warmth re-ask', (tester) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 12, 16),
    );
    await openDryerSession(
      tester,
      dependencies,
      "Mark's house",
      skipProblemStarter: false,
    );
    await confirmNoHeatStarter(tester);

    expect(
      find.byKey(const Key('observation-prompt-heat-observed')),
      findsNothing,
    );
    expect(
      find.text('Is there any warmth after the dryer has run briefly?'),
      findsNothing,
    );

    final discriminatorShown = [
      'gas-dryer-type',
      'exterior-airflow',
      'dry-time-change',
      'recent-overheat',
      'cycle-heat-setting',
      'drum-turns',
      'clothes-feel-after-cycle',
      'lint-filter-condition',
    ].any(
      (id) =>
          tester
              .widgetList(find.byKey(Key('observation-prompt-$id')))
              .isNotEmpty,
    );
    expect(discriminatorShown, isTrue);
  });

  testWidgets(
    'no-heat discriminators can lead to thermal fuse close path with back',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 12, 16, 10),
      );
      await openDryerSession(
        tester,
        dependencies,
        'Golden Path Household',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);

      expect(
        find.text('Is there any warmth after the dryer has run briefly?'),
        findsNothing,
      );

      await answerObservation(tester, 'drum-turns', 'turns-normally');
      await answerObservation(tester, 'cycle-heat-setting', 'yes-heat-cycle');

      final back = find.byKey(const Key('answer-choice-back'));
      if (back.evaluate().isNotEmpty) {
        await tapVisible(tester, back);
        expect(find.text('Change this answer'), findsOneWidget);
        await tapVisible(
          tester,
          find.byKey(const Key('answer-choice-yes-heat-cycle')),
        );
      }

      await answerObservation(
        tester,
        'recent-overheat',
        'yes-very-hot-or-shut-off-from-heat',
      );
      await selectObservation(tester, 'exterior-airflow');
      if (find.byKey(const Key('inspect-chip-doesnt-match')).evaluate().isNotEmpty) {
        await tapVisible(
          tester,
          find.byKey(const Key('inspect-chip-doesnt-match')),
        );
      } else {
        await answerObservation(tester, 'exterior-airflow', 'weak');
      }
      await answerObservation(
        tester,
        'clothes-feel-after-cycle',
        'cold-and-still-damp',
      );

      expect(
        find.byKey(const Key('recommended-primary-label-thermal-fuse-open')),
        findsOneWidget,
      );
      await tapVisible(
        tester,
        find.byKey(const Key('accept-recommended-primary-thermal-fuse-open')),
      );

      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      await completeRepairReadinessIfPresent(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('lint filter'), findsWidgets);
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      expect(find.byKey(const Key('guidance-did-this')), findsOneWidget);
      expect(find.textContaining('is warmth restored'), findsNothing);

      await completeGuidanceStepsIfPresent(tester);
      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      expect(find.byKey(const Key('verification-card')), findsNothing);
      expect(find.textContaining('Hand off to a qualified technician'), findsNothing);
    },
  );
}
