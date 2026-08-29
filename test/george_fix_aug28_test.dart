import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modern_butlers_book/helpers/dryer_energy_source.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/kg_category_slugs.dart';
import 'package:modern_butlers_book/helpers/kg_family_filter.dart';
import 'package:modern_butlers_book/helpers/kg_relation_rules.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/knowledge_graph.dart';
import 'package:modern_butlers_book/models/knowledge_package_ref.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/seed/kg_mvp_seed_data.dart';
import 'package:modern_butlers_book/seed/knowledge_graph_seeder.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';

import 'support/in_memory_knowledge_graph.dart';
import 'support/session_test_helpers.dart';

void main() {
  test('Dart seeder persists authored applies_to and contains, not force-suggests',
      () async {
    final graph = InMemoryKnowledgeGraph();
    final seeder = KnowledgeGraphSeeder(graph: graph);
    await seeder.seedMvpPhase1();

    expect(
      graph.edges.any((e) => e.relationType == KgRelationType.appliesTo),
      isTrue,
    );
    expect(
      graph.edges.any((e) => e.relationType == KgRelationType.contains),
      isTrue,
    );
    expect(
      graph.edges.any((e) => e.relationType == KgRelationType.affects),
      isTrue,
    );
    expect(
      kgMvpEdges.any((e) => e.relation == 'contains'),
      isTrue,
    );
    expect(
      kgMvpEdges.any((e) => e.relation == 'applies_to'),
      isTrue,
    );

    final standingSuggests = graph.edges.where(
      (e) => e.relationType == KgRelationType.suggests,
    );
    final standingProduces = graph.edges.where(
      (e) => e.relationType == KgRelationType.produces,
    );
    expect(
      standingProduces.length,
      kgMvpEdges.where((e) => e.relation == 'produces').length,
    );
    expect(
      standingSuggests.length,
      kgMvpEdges.where((e) => e.relation == 'suggests').length,
    );
  });

  test('illegal createEdge throws', () async {
    expect(
      () => assertLegalKgRelation(
        sourceType: KgNodeType.symptom,
        relationType: KgRelationType.contains,
        targetType: KgNodeType.subsystem,
      ),
      throwsA(isA<IllegalKgRelationException>()),
    );

    final graph = InMemoryKnowledgeGraph();
    final symptom = await graph.createNode(
      nodeType: KgNodeType.symptom,
      slug: 'wont-start',
      name: 'Will not start',
      graphVersion: kgMvpVersion,
    );
    final subsystem = await graph.createNode(
      nodeType: KgNodeType.subsystem,
      slug: 'dryer-heating',
      name: 'Heating',
      graphVersion: kgMvpVersion,
    );
    expect(
      () => graph.createEdge(
        sourceNodeId: symptom.id,
        targetNodeId: subsystem.id,
        relationType: KgRelationType.contains,
        graphVersion: kgMvpVersion,
      ),
      throwsA(isA<IllegalKgRelationException>()),
    );
  });

  test('washer wont-start does not return dryer belt or lint', () {
    final washer = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'wont-start',
      familySlug: 'washer',
    );
    expect(washer, contains('washer-lid-switch-failure'));
    expect(washer, isNot(contains('dryer-worn-drum-belt')));
    expect(washer, isNot(contains('dryer-lint-buildup')));
    expect(washer, isNot(contains('dryer-door-switch-failure')));

    final dryer = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'wont-start',
      familySlug: 'dryer',
    );
    expect(dryer, contains('dryer-door-switch-failure'));
    expect(dryer, isNot(contains('dryer-worn-drum-belt')));
    expect(dryer, isNot(contains('washer-lid-switch-failure')));

    final grindingDryer = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'grinding-noise',
      familySlug: 'dryer',
    );
    expect(grindingDryer, isEmpty);
    final grindingWasher = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'grinding-noise',
      familySlug: 'washing-machine',
    );
    expect(grindingWasher, contains('washer-drain-pump-failure'));
  });

  test('category picker labels map to graph slugs', () {
    expect(kgGraphCategorySlug('washer'), 'washing-machine');
    expect(kgGraphCategorySlug('Washing Machine'), 'washing-machine');
    expect(kgGraphCategorySlug('fridge'), 'refrigerator-freezer');
    expect(kgGraphCategorySlug('dryer'), 'dryer');
    expect(kgGraphCategorySlug('dishwasher'), 'dishwasher');
  });

  test('thermal-fuse failure mode exists in graph seed', () {
    expect(
      kgMvpNodes.any(
        (n) => n.type == 'failure_mode' && n.slug == 'dryer-thermal-fuse-open',
      ),
      isTrue,
    );
    expect(
      kgMvpEdges.any(
        (e) =>
            e.relation == 'affects' &&
            e.sourceSlug == 'dryer-thermal-fuse-open' &&
            e.targetSlug == 'dryer-thermal-fuse',
      ),
      isTrue,
    );
    expect(
      kgMvpEdges.any(
        (e) =>
            e.relation == 'suggests' &&
            e.sourceSlug == 'wont-start' &&
            e.targetSlug == 'dryer-lint-buildup',
      ),
      isFalse,
    );
    expect(
      kgMvpEdges.any(
        (e) =>
            e.relation == 'suggests' &&
            e.sourceSlug == 'wont-start' &&
            e.targetSlug == 'dryer-worn-drum-belt',
      ),
      isFalse,
    );
  });

  test('compressor hypothesis is gated, not a fridge DIY mode', () {
    final node = kgMvpNodes.firstWhere(
      (n) => n.slug == 'refrigerator-compressor-sealed-fault',
    );
    expect(kgFailureModeMetadataIsProfessionalGate(node.metadata), isTrue);
    final beginner = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'not-cooling',
      familySlug: 'fridge',
    );
    expect(beginner, isNot(contains('refrigerator-compressor-sealed-fault')));
    final withPro = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'not-cooling',
      familySlug: 'fridge',
      includeProfessional: true,
    );
    expect(withPro, contains('refrigerator-compressor-sealed-fault'));

    final fridge = KnowledgePackageRepository().loadByCategory('fridge').single;
    expect(
      fridge.failureModes.any(
        (m) => m.id.toLowerCase().contains('compressor'),
      ),
      isFalse,
    );
  });

  test('evaporator has a cooling contains link', () {
    expect(
      kgMvpEdges.any(
        (e) =>
            e.relation == 'contains' &&
            e.sourceSlug == 'refrigerator-cooling' &&
            e.targetSlug == 'refrigerator-evaporator-coils',
      ),
      isTrue,
    );
  });

  test('unbalanced-load affects washer suspension', () {
    expect(
      kgMvpEdges.any(
        (e) =>
            e.relation == 'affects' &&
            e.sourceSlug == 'washer-unbalanced-load' &&
            e.targetSlug == 'washer-suspension',
      ),
      isTrue,
    );
  });

  test('floor leak suggests more than dishwasher door seal', () {
    final leaks = kgSuggestedFailureModeSlugsForFamily(
      symptomSlug: 'water-leak-on-floor',
      familySlug: 'dishwasher',
    );
    expect(leaks, contains('dishwasher-door-seal-leak'));
    expect(leaks, contains('dishwasher-drain-hose-leak'));
  });

  test('float switch has failure modes from standing-water and wont-fill', () {
    expect(
      kgSuggestedFailureModeSlugsForFamily(
        symptomSlug: 'standing-water',
        familySlug: 'dishwasher',
      ),
      contains('dishwasher-float-switch-stuck'),
    );
    expect(
      kgSuggestedFailureModeSlugsForFamily(
        symptomSlug: 'wont-fill',
        familySlug: 'dishwasher',
      ),
      contains('dishwasher-float-switch-stuck'),
    );
  });

  test('gas dryer + no heat does not open electric-element primary', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    Evidence item({required String templateId, required String answer}) {
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

    final starter = Evidence(
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

    const ranking = RankingService();
    final snapshot = ranking.evaluate(
      package: package,
      energySource: ApplianceEnergySource.gas,
      evidence: [
        starter,
        item(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        item(templateId: 'drum-turns', answer: 'Turns normally'),
      ],
    );
    expect(
      snapshot.recommendPrimaryFailureModeId,
      isNot('heating-element-failed'),
    );
    expect(
      snapshot.orderedFailureModes.first.id,
      isNot('heating-element-failed'),
    );

    final unknownNext = starterInterviewTemplate(
      templates: package.evidenceTemplates,
      recordedEvidence: [starter],
      firstTemplateId: 'cycle-heat-setting',
      starterMatchedSymptomIds: {'no-heat'},
      energySource: ApplianceEnergySource.unknown,
    );
    expect(unknownNext?.id, gasDryerTypeTemplateId);
  });

  test('burning smell evidence is a safety stop', () {
    expect(
      evaluateSafetyStop(
        evidence: [
          Evidence(
            id: 'e-burn',
            sessionId: 's',
            applianceId: 'a',
            type: EvidenceType.textObservation,
            observation: 'Burning smell',
            answer: 'I smell burning',
            collectedAt: DateTime.utc(2026, 8, 28),
            collectedInState: RepairSessionState.evidenceCollection,
            source: EvidenceSource.user,
            schemaVersion: '1.0',
          ),
        ],
        primaryFailureModeId: null,
      ),
      isNotNull,
    );
  });

  test('unknown appliance status does not become active', () {
    expect(applianceStatusFromName('active'), ApplianceStatus.active);
    expect(applianceStatusFromName('retired'), ApplianceStatus.retired);
    expect(applianceStatusFromName('garbage'), ApplianceStatus.retired);
    expect(applianceStatusFromName(null), ApplianceStatus.retired);
    expect(applianceStatusFromName('ACTIVE'), ApplianceStatus.retired);
  });

  test('status garbage survives restore without un-retiring', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 28, 18);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Status House');
    final dryer = first.addDryer();
    await first.flushPersist();

    final raw = prefs.getString('modern_butler_domain_v1')!;
    final corrupted = raw.replaceFirst('"status":"active"', '"status":"wat"');
    await prefs.setString('modern_butler_domain_v1', corrupted);

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    final restored = second.applianceRepository.getById(dryer.id)!;
    expect(restored.status, isNot(ApplianceStatus.active));
    expect(restored.status, ApplianceStatus.retired);
  });

  test('dryer copy uses door, not lid or spin cycle', () {
    final dryer = KnowledgePackageRepository().loadById('dryer-core')!;
    for (final template in dryer.evidenceTemplates) {
      final lower = template.promptText.toLowerCase();
      expect(lower, isNot(contains('spin cycle')));
      if (template.id == 'door-closed-firmly') {
        expect(lower, contains('door'));
        expect(lower, isNot(contains('lid')));
      }
    }
  });

  test('no beginner live-voltage evidence prompts', () {
    final repo = KnowledgePackageRepository();
    for (final package in repo.listAvailable()) {
      for (final template in package.evidenceTemplates) {
        final lower = template.promptText.toLowerCase();
        final prohibited =
            lower.contains('do not') ||
            lower.contains("don't") ||
            lower.contains('never');
        if (prohibited) {
          continue;
        }
        expect(lower, isNot(contains('measure live voltage')));
        expect(lower, isNot(contains('test live voltage')));
        expect(lower, isNot(contains('probe live')));
      }
    }
  });

  testWidgets('missing package resume is not a blank scaffold', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 28, 18, 10),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Missing');
    final dryer = deps.addDryer();
    final household = deps.currentHousehold!;
    final session = deps.repairSessionRepository.createSession(
      id: 'session-missing-guide',
      applianceId: dryer.id,
      householdId: household.id,
      createdByUserId: household.ownerUserId,
      packageId: 'dryer-core',
      packageVersion: '1.4.0',
      schemaVersion: '1.0',
      initialHistoryEntryId: 'hist-missing',
      startedAt: DateTime.utc(2026, 8, 28, 18, 10),
    );
    deps.sessionCoordinator.importPackageRefs({
      session.id: const KnowledgePackageRef(
        id: 'dryer-core',
        applianceCategory: 'dryer',
        version: '1.4.0',
        displayName: 'Dryer Knowledge Package',
      ),
    });

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          dependencies: deps,
          appliance: dryer,
          sessionId: session.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('missing-guide-scaffold')), findsOneWidget);
    expect(find.text('Install guide'), findsOneWidget);
    expect(find.text('Start fresh'), findsOneWidget);
  });
}
