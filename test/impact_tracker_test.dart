import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/impact_tracker.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

void main() {
  test('Fixed outcomes count repairs, appliances, and estimated savings', () {
    expect(UserFacingCopy.impactEstimatesLabel.toLowerCase(), contains('estimate'));

    final impact = computeHouseholdImpact([
      const ImpactRepairInput(
        applianceId: 'dryer-1',
        closeKind: SessionCloseKind.fixed,
        diyCostUsd: 20,
        rankingLeaderFailureModeId: 'thermal-fuse-open',
      ),
      const ImpactRepairInput(
        applianceId: 'dryer-1',
        closeKind: SessionCloseKind.notFixed,
      ),
      const ImpactRepairInput(
        applianceId: 'washer-1',
        closeKind: SessionCloseKind.fixed,
        rankingLeaderFailureModeId: 'heating-element-failed',
      ),
    ]);

    expect(impact.repairsLogged, 2);
    expect(impact.appliancesKeptInService, 2);
    expect(impact.estimatedSavingsUsd, isNotNull);
    expect(impact.estimatedSavingsUsd! > 0, isTrue);
    expect(formatImpactUsd(impact.estimatedSavingsUsd!), contains(r'$'));
  });

  test('no Fixed outcomes means empty impact and no savings claim', () {
    final impact = computeHouseholdImpact([
      const ImpactRepairInput(
        applianceId: 'dryer-1',
        closeKind: SessionCloseKind.stopped,
      ),
    ]);
    expect(impact.isEmpty, isTrue);
    expect(impact.estimatedSavingsUsd, isNull);
  });

  test('user DIY cost is compared to the package pro stub', () {
    final saved = estimatedSavingsUsdFor(
      const ImpactRepairInput(
        applianceId: 'dryer-1',
        closeKind: SessionCloseKind.fixed,
        diyCostUsd: 25,
        rankingLeaderFailureModeId: 'thermal-fuse-open',
      ),
    );
    expect(saved, 190);
  });

  testWidgets('home card shows after Fixed and labels money as an estimate', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14));
    deps.createHousehold('Impact House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      diyCostUsd: 18,
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-impact-card')), findsOneWidget);
    expect(find.byKey(const Key('home-impact-estimates-label')), findsOneWidget);
    expect(find.text(UserFacingCopy.impactEstimatesLabel), findsOneWidget);
    expect(find.byKey(const Key('home-impact-repairs')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.byKey(const Key('home-impact-appliances')), findsOneWidget);
  });

  testWidgets('home hides impact when nothing is Fixed', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 14));
    deps.createHousehold('Empty Impact House');
    deps.addDryer();

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-impact-card')), findsNothing);
  });
}
