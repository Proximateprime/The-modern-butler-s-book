import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/easier_first.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/package_maintenance_schedule.dart';
import 'package:modern_butlers_book/helpers/parts_cost.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';
import 'package:modern_butlers_book/helpers/repair_stakes.dart';
import 'package:modern_butlers_book/helpers/thermal_reset_scope.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/enrichment_note.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/parts_cost_card.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('resettable thermal path is DIY; fuse swap stays pro-only', () {
    final reset = closePathForFailureMode(accessibleThermalResetModeId)!;
    final motor = closePathForFailureMode(motorOverheatProtectorModeId)!;
    final fuse = closePathForFailureMode('thermal-fuse-open')!;
    expect(closePathDiyCannotComplete(reset), isFalse);
    expect(closePathDiyCannotComplete(motor), isFalse);
    expect(partsCostDiyOutOfScope(accessibleThermalResetModeId), isFalse);
    expect(closePathDiyCannotComplete(fuse), isTrue);
    expect(partsCostDiyOutOfScope('thermal-fuse-open'), isTrue);
    expect(reset.allowResolvedWhenConfirmed, isTrue);
    expect(
      reset.safeGuidanceSteps.join(' ').toLowerCase(),
      contains('reset'),
    );
  });

  test('easier-first prefers resettable cutoff over thermal fuse', () {
    const fuse = FailureMode(
      id: 'thermal-fuse-open',
      label: 'Thermal fuse open',
      description: '',
      commonality: FailureModeCommonality.veryHigh,
      safetyNotes: '',
    );
    const reset = FailureMode(
      id: accessibleThermalResetModeId,
      label: 'Resettable thermal cutoff',
      description: '',
      commonality: FailureModeCommonality.common,
      safetyNotes: '',
    );
    const standings = {
      'thermal-fuse-open': FailureModeStanding(
        supportCount: 3,
        excludeCount: 0,
      ),
      accessibleThermalResetModeId: FailureModeStanding(
        supportCount: 2,
        excludeCount: 0,
      ),
    };
    expect(
      easierFirstPursuitId(
        orderedFailureModes: [fuse, reset],
        standings: standings,
        rankingLeaderId: 'thermal-fuse-open',
      ),
      accessibleThermalResetModeId,
    );
    expect(
      easierFirstDualFaultActive(
        orderedFailureModes: [fuse, reset],
        standings: standings,
      ),
      isTrue,
    );
    expect(
      easierFirstPursuitId(
        orderedFailureModes: [fuse, reset],
        standings: standings,
        rankingLeaderId: 'thermal-fuse-open',
        confirmedPrimaryId: 'thermal-fuse-open',
      ),
      'thermal-fuse-open',
    );
    expect(
      easierFirstPursuitId(
        orderedFailureModes: [fuse, reset],
        standings: standings,
        rankingLeaderId: 'thermal-fuse-open',
        exhaustedModeIds: {accessibleThermalResetModeId},
      ),
      'thermal-fuse-open',
    );
  });

  test('brick-risk warning is for high-stakes DIY, not fuse handoff', () {
    expect(
      shouldShowBrickRiskWarning(closePathForFailureMode('broken-drive-belt')!),
      isTrue,
    );
    expect(
      shouldShowBrickRiskWarning(closePathForFailureMode('thermal-fuse-open')!),
      isFalse,
    );
  });

  test('empty manufacturer / community maintenance omits content', () {
    expect(manufacturerMaintenanceSchedule(null), isEmpty);
    expect(communityMaintenanceNotices(null), isEmpty);
  });

  test('enrichment cache key is stable and store accepts a home note', () {
    final key = enrichmentCacheKey(
      applianceId: 'a1',
      modelNumber: 'WED4815EW',
      symptomText: '  Button on the back  ',
    );
    expect(
      enrichmentCacheKey(
        applianceId: 'a1',
        modelNumber: 'WED4815EW',
        symptomText: 'Button on the back',
      ),
      key,
    );
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 25, 12));
    deps.createHousehold('Enrich Home');
    final dryer = deps.addDryer();
    deps.queueEnrichmentRequest(
      EnrichmentRequest(
        key: key,
        freeText: 'Reset button on the back panel',
        applianceId: dryer.id,
        modelNumber: 'WED4815EW',
      ),
    );
    expect(deps.enrichmentNoteForKey(key), isNotNull);
    expect(deps.enrichmentNoteForKey(key)!.pending, isTrue);
    expect(deps.acceptedEnrichmentNotes(applianceId: dryer.id), isEmpty);
    deps.acceptEnrichmentNote(deps.enrichmentNoteForKey(key)!.id);
    expect(deps.acceptedEnrichmentNotes(applianceId: dryer.id), hasLength(1));
    deps.queueEnrichmentRequest(
      EnrichmentRequest(
        key: key,
        freeText: 'should not duplicate',
        applianceId: dryer.id,
      ),
    );
    expect(
      deps.acceptedEnrichmentNotes(applianceId: dryer.id).single.body,
      'Reset button on the back panel',
    );
  });

  testWidgets('pro-only fuse path still hides DIY repair CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartsCostCard(
            parts: partsCostCatalog['thermal-fuse-open']!,
            diyOutOfScope: partsCostDiyOutOfScope('thermal-fuse-open'),
            onIllRepair: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('parts-cost-ill-repair')), findsNothing);
    expect(find.byKey(const Key('parts-cost-pro-only-note')), findsOneWidget);
  });

  testWidgets('multi-select starter records both symptoms', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 25, 8));
    await openDryerSession(
      tester,
      deps,
      'Multi Select Starter',
      skipProblemStarter: false,
    );
    await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('starter-chip-long-dry-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();
    await answerElectricFuelIfAsked(tester);

    final session = deps.repairSessionRepository.listAllSessions().single;
    final evidence = deps.repairSessionRepository.evidenceForSession(session.id);
    final starter = evidence.firstWhere(
      (item) => item.templateId == problemStarterComplaintTemplateId,
    );
    expect(starter.answer, contains('No heat'));
    expect(starter.answer, contains('Long dry time'));
  });

  testWidgets(
    'review what you checked does not wipe diagnosis after conclusion',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 25, 9));
      await openDryerSession(
        tester,
        deps,
        'Inspect Review No Wipe',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();
      await answerElectricFuelIfAsked(tester);
      await selectFailureMode(tester, 'thermal-fuse-open');

      expect(find.byKey(const Key('close-path-phase-conclusion')), findsOneWidget);
      expect(find.byKey(const Key('close-path-show-inspect')), findsOneWidget);
      expect(
        find.text(UserFacingCopy.inspectShowMeWhatToCheck),
        findsOneWidget,
      );

      final session = deps.repairSessionRepository.listAllSessions().single;
      final before = deps.buildDecisionContext(session.id);
      expect(before.evidence, isNotEmpty);
      expect(before.primaryFailureModeId, 'thermal-fuse-open');
      final evidenceCount = before.evidence.length;
      final hypothesisCount =
          deps.repairSessionRepository.hypothesesForSession(session.id).length;

      await tapVisible(tester, find.byKey(const Key('close-path-show-inspect')));
      expect(find.byKey(const Key('inspect-review-intro')), findsOneWidget);
      expect(find.byKey(const Key('inspect-chip-matches-ok')), findsNothing);

      final after = deps.buildDecisionContext(session.id);
      expect(after.evidence, hasLength(evidenceCount));
      expect(after.primaryFailureModeId, 'thermal-fuse-open');
      expect(
        deps.repairSessionRepository.hypothesesForSession(session.id),
        hasLength(hypothesisCount),
      );

      await tapVisible(tester, find.byKey(const Key('inspect-review-back')));
      expect(find.byKey(const Key('close-path-phase-conclusion')), findsOneWidget);
      expect(find.byKey(const Key('close-path-show-inspect')), findsOneWidget);
    },
  );
}
