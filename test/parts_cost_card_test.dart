import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/parts_cost.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('package stubs exist for the vent leader and not for unknown modes', () {
    final parts = FailureModeAuthoringRegistry.partsEstimatesFor(
      'restricted-exhaust-airflow',
    );
    expect(parts, isNotEmpty);
    expect(parts.first.name, 'Lint filter');
    expect(parts.first.diyEstimate, contains(r'$'));
    expect(
      FailureModeAuthoringRegistry.partsEstimatesFor('not-a-real-mode'),
      isEmpty,
    );
  });

  test('outcome parts hide cleaning/restriction purchase rows', () {
    expect(
      partsEstimatesForSelectedPath(
        parts: FailureModeAuthoringRegistry.partsEstimatesFor(
          'restricted-exhaust-airflow',
        ),
        failureModeId: 'restricted-exhaust-airflow',
      ),
      isEmpty,
    );
    expect(
      partsEstimatesForSelectedPath(
        parts: FailureModeAuthoringRegistry.partsEstimatesFor(
          'clogged-lint-pathway',
        ),
        failureModeId: 'clogged-lint-pathway',
      ),
      isEmpty,
    );
    final fuse = partsEstimatesForSelectedPath(
      parts: FailureModeAuthoringRegistry.partsEstimatesFor('thermal-fuse-open'),
      failureModeId: 'thermal-fuse-open',
    );
    expect(fuse, hasLength(1));
    expect(fuse.single.name, 'Thermal fuse');
    final element = partsEstimatesForSelectedPath(
      parts: FailureModeAuthoringRegistry.partsEstimatesFor(
        'heating-element-failed',
      ),
      failureModeId: 'heating-element-failed',
    );
    expect(element, hasLength(1));
    expect(element.single.name, 'Heating element');
    expect(
      partsEstimatesForSelectedPath(
        parts: [
          ...FailureModeAuthoringRegistry.partsEstimatesFor('thermal-fuse-open'),
          ...FailureModeAuthoringRegistry.partsEstimatesFor(
            'restricted-exhaust-airflow',
          ),
        ],
        failureModeId: 'thermal-fuse-open',
      ).map((part) => part.name),
      ['Thermal fuse'],
    );
  });

  test('dryer fuse/vent ignore washer catalog rows even if mixed in', () {
    final mixed = [
      for (final entry in partsCostCatalog.values) ...entry,
    ];
    final names = mixed.map((part) => part.name).toSet();
    expect(names, contains('Drain filter / pump trap'));
    expect(names, contains('Inlet hose'));

    final fuse = partsEstimatesForSelectedPath(
      parts: mixed,
      failureModeId: 'thermal-fuse-open',
    );
    expect(fuse.map((part) => part.name), ['Thermal fuse']);

    final vent = partsEstimatesForSelectedPath(
      parts: mixed,
      failureModeId: 'restricted-exhaust-airflow',
    );
    expect(vent, isEmpty);
    expect(
      partsEstimatesForSelectedPath(
        parts: mixed,
        failureModeId: 'clogged-lint-pathway',
      ),
      isEmpty,
    );
  });

  testWidgets('diagnosis shows estimates-only parts card for the leader', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 20));
    await openDryerSession(tester, deps, 'Parts Cost House');
    await selectFailureMode(tester, 'restricted-exhaust-airflow');

    expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
    expect(find.byKey(const Key('parts-cost-card')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('close-path-continue')));
    expect(find.text("I'll repair"), findsOneWidget);
    expect(find.text('Call a pro'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));
    expect(find.byKey(const Key('parts-cost-card')), findsNothing);
    expect(find.text('Lint filter'), findsNothing);
    expect(find.text('Flexible vent kit'), findsNothing);
    expect(find.text('Drain filter / pump trap'), findsNothing);
    expect(find.text("I'll repair"), findsNothing);

    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.byKey(const Key('outcome-save-button')), findsNothing);
  });

  testWidgets('fuse path parts card is only the fuse, with estimates disclaimer', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 20, 10));
    await openDryerSession(tester, deps, 'Fuse Parts House');
    await selectFailureMode(tester, 'thermal-fuse-open');
    await tapVisible(tester, find.byKey(const Key('close-path-continue')));
    await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));

    expect(find.byKey(const Key('parts-cost-card')), findsOneWidget);
    expect(find.byKey(const Key('parts-cost-estimates-only')), findsOneWidget);
    expect(find.text('Estimates only. Not a quote.'), findsOneWidget);
    expect(find.text('Thermal fuse'), findsOneWidget);
    expect(find.text('Lint filter'), findsNothing);
    expect(find.text('Flexible vent kit'), findsNothing);
    expect(find.text('Drain filter / pump trap'), findsNothing);
    expect(find.text('Inlet hose'), findsNothing);
  });

  testWidgets('Call a pro opens the existing professional outcome path', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 20, 5));
    await openDryerSession(tester, deps, 'Parts Pro House');
    await selectFailureMode(tester, 'restricted-exhaust-airflow');
    await tapVisible(tester, find.byKey(const Key('close-path-continue')));
    await tapVisible(tester, find.byKey(const Key('close-path-call-pro')));
    expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('completion-save-home')));
    await tester.tap(find.byKey(const Key('completion-save-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
      expect(find.text('Needs a professional'), findsWidgets);
  });
}
