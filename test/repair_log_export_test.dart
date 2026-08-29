import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/repair_log_export.dart';
import 'package:modern_butlers_book/helpers/repair_log_share.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

import 'support/session_test_helpers.dart';

void main() {
  late List<String> shared;

  setUp(() {
    shared = <String>[];
    repairLogShareHandler = (text) async {
      shared.add(text);
    };
  });

  tearDown(() {
    repairLogShareHandler = shareRepairLogViaSystem;
  });

  test('export text includes date, appliance, symptom, outcome, leader, prevention, note', () {
    final outcome = SessionOutcome(
      sessionId: 'session-1',
      resolutionStatus: SessionResolutionStatus.resolved,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Cleared the vent',
      contributingFactors: const [],
      preventiveActions: const ['Clean the lint filter every load'],
      verified: true,
      schemaVersion: '1.0',
      userNote: 'Took ten minutes',
      rankingLeaderLabel: 'Restricted exhaust airflow',
      startSymptom: 'No heat',
      recordedAt: DateTime.utc(2026, 8, 16, 16),
    );

    final text = formatRepairLogExport(
      applianceName: 'Laundry Room Dryer',
      date: outcome.recordedAt,
      outcome: outcome,
    );

    expect(text, contains('Date: 2026-08-16'));
    expect(text, contains('Appliance: Laundry Room Dryer'));
    expect(text, contains('Symptom: No heat'));
    expect(text, contains('Outcome: Fixed'));
    expect(text, contains('Leader: Restricted exhaust airflow'));
    expect(text, contains('Clean the lint filter every load'));
    expect(text, contains('Note: Took ten minutes'));
    expect(text, isNot(contains('http')));
  });

  test('empty optional fields use a dash, not a dump', () {
    final outcome = SessionOutcome(
      sessionId: 'session-2',
      resolutionStatus: SessionResolutionStatus.unresolved,
      closeKind: SessionCloseKind.stopped,
      immediateCause: 'Stopped',
      contributingFactors: const [],
      preventiveActions: const [],
      verified: false,
      schemaVersion: '1.0',
    );

    final text = formatRepairLogExport(
      applianceName: 'Dryer 2',
      date: null,
      outcome: outcome,
    );

    expect(text, contains('Symptom: —'));
    expect(text, contains('Leader: —'));
    expect(text, contains('Prevention: —'));
    expect(text, contains('Note: —'));
    expect(text, contains('Outcome: Stopped'));
  });

  testWidgets('closed memory row shares the repair log locally', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 21));
    deps.createHousehold('Export House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Replaced the lint filter',
      preventionNote: 'Clean the filter every load',
      userNote: 'Quiet after that',
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('export-repair-$sessionId')), findsOneWidget);
    await tapVisible(tester, find.byKey(Key('export-repair-$sessionId')));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    expect(shared.single, contains('Appliance: ${dryer.name}'));
    expect(shared.single, contains('Outcome: Fixed'));
    expect(shared.single, contains('Clean the filter every load'));
    expect(shared.single, contains('Note: Quiet after that'));
  });

  testWidgets('appliance history row shares the same local repair log', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 21, 5));
    deps.createHousehold('History Export House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleared the vent',
      preventionNote: 'Keep the vent path clear',
      userNote: 'From the history row',
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('repair-history-$sessionId')), findsOneWidget);
    await tester.tap(find.byKey(Key('export-repair-$sessionId')));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    expect(shared.single, contains('Date: 2026-08-16'));
    expect(shared.single, contains('Appliance: ${dryer.name}'));
    expect(shared.single, contains('Outcome: Fixed'));
    expect(shared.single, contains('Keep the vent path clear'));
    expect(shared.single, contains('Note: From the history row'));
    expect(shared.single, isNot(contains('http')));
  });
}
