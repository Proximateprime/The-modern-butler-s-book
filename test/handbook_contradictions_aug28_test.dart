import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modern_butlers_book/helpers/dryer_energy_source.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: observationPromptTitle(
        package.evidenceTemplates.firstWhere((t) => t.id == templateId),
      ),
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 8, 28),
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
      answer: buildStarterComplaintAnswer(
        resolution: resolveDryerStarter(selectedSymptomIds: {'no-heat'}),
      ),
      templateId: problemStarterComplaintTemplateId,
      collectedAt: DateTime.utc(2026, 8, 28),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  test('unknown energy + no heat asks gas vs electric before element path', () {
    final next = starterInterviewTemplate(
      templates: package.evidenceTemplates,
      recordedEvidence: [starterNoHeat()],
      firstTemplateId: 'cycle-heat-setting',
      starterMatchedSymptomIds: {'no-heat'},
      energySource: ApplianceEnergySource.unknown,
    );
    expect(next?.id, gasDryerTypeTemplateId);
    expect(observationPromptTitle(next!), gasDryerTypeHouseholdPrompt);
  });

  test('gas dryer + no heat does not lead with electric heating element', () {
    const ranking = RankingService();
    final snapshot = ranking.evaluate(
      package: package,
      evidence: [
        starterNoHeat(),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: gasDryerTypeTemplateId, answer: gasDryerTypeGasAnswer),
      ],
    );
    expect(
      snapshot.recommendPrimaryFailureModeId,
      isNot('heating-element-failed'),
    );
    expect(
      snapshot.standings['heating-element-failed']!.excludeCount,
      greaterThan(snapshot.standings['heating-element-failed']!.supportCount),
    );
    expect(
      snapshot.orderedFailureModes.first.id,
      isNot('heating-element-failed'),
    );
  });

  test('dryer door-closed copy says door, not lid', () {
    final door = package.evidenceTemplates.firstWhere(
      (t) => t.id == 'door-closed-firmly',
    );
    expect(door.promptText.toLowerCase(), contains('door'));
    expect(door.promptText.toLowerCase(), isNot(contains('lid')));
  });

  testWidgets(
    'burning smell starter shows safety stop, not ordinary questions',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 28, 16));
      await openDryerSession(
        tester,
        deps,
        'Burning Smell House',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('safety-stop-title'))).data,
        'Needs a professional',
      );
      expect(find.text('Stop — Call a professional'), findsNothing);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(find.byKey(const Key('other-observations-picker')), findsNothing);
      final dryer = deps.appliancesForCurrentHousehold().single;
      final sessionId = deps.startOrResumeSession(dryer);
      expect(
        evaluateSafetyStop(
          evidence: deps.repairSessionRepository.evidenceForSession(sessionId),
          primaryFailureModeId: null,
        ),
        isNotNull,
      );
    },
  );

  testWidgets(
    'add dryer without energy then no-heat asks fuel before element guidance',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 28, 16, 5));
      await openDryerSession(
        tester,
        deps,
        'Unknown Energy House',
        skipProblemStarter: false,
      );
      final dryer = deps.appliancesForCurrentHousehold().single;
      expect(dryer.energySource, ApplianceEnergySource.unknown);

      await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('observation-prompt-gas-dryer-type')),
        findsOneWidget,
      );
      expect(find.text(gasDryerTypeHouseholdPrompt), findsOneWidget);
      expect(
        find.byKey(const Key('observation-prompt-relay-heat-output')),
        findsNothing,
      );
    },
  );

  test('energy source survives persist and restore', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 28, 16, 10);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Energy Persist');
    final dryer = first.addDryer(energySource: ApplianceEnergySource.gas);
    expect(dryer.energySource, ApplianceEnergySource.gas);
    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    final restored = second.applianceRepository.getById(dryer.id)!;
    expect(restored.energySource, ApplianceEnergySource.gas);
  });
}
