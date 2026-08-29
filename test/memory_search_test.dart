import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/repair_history_search.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('filterRepairHistory matches appliance, outcome, and text', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 12));
    deps.createHousehold('Search House');
    final dryer = deps.addDryer(name: 'Laundry Room Dryer');
    final washer = deps.addWasher(name: 'Laundry Room Washer');
    final dryerSession = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: dryerSession,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleared the vent',
      userNote: 'Took ten minutes',
    );
    final washerSession = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: washerSession,
      closeKind: SessionCloseKind.stopped,
      whatFixedIt: 'Stopped to call a neighbor',
    );
    final items = deps.recentSessionOutcomes(limit: 20);

    expect(
      filterRepairHistory(items: items, query: 'dryer').map((item) => item.session.id),
      [dryerSession],
    );
    expect(
      filterRepairHistory(
        items: items,
        closeKind: SessionCloseKind.stopped,
      ).map((item) => item.session.id),
      [washerSession],
    );
    expect(
      filterRepairHistory(items: items, query: 'ten minutes').single.session.id,
      dryerSession,
    );
    expect(
      filterRepairHistory(items: items, applianceId: washer.id),
      hasLength(1),
    );
    expect(filterRepairHistory(items: items, query: 'no such repair'), isEmpty);
  });

  testWidgets('home search filters history and shows empty matches', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 12));
    deps.createHousehold('Memory Search');
    final dryer = deps.addDryer(name: 'Laundry Room Dryer');
    final washer = deps.addWasher(name: 'Laundry Room Washer');
    final dryerSession = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: dryerSession,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleared the vent',
    );
    final washerSession = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: washerSession,
      closeKind: SessionCloseKind.notFixed,
      whatFixedIt: 'Still leaking',
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    expect(find.byKey(Key('recent-outcome-$dryerSession')), findsOneWidget);
    expect(find.byKey(Key('recent-outcome-$washerSession')), findsOneWidget);

    await tester.tap(find.byKey(const Key('memory-search-tile')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('memory-search-field')), 'leaking');
    await tester.pump();
    expect(find.byKey(Key('recent-outcome-$dryerSession')), findsNothing);
    expect(find.byKey(Key('recent-outcome-$washerSession')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('memory-search-field')), '');
    await tester.pump();
    await tester.tap(find.byKey(const Key('memory-filter-outcome-fixed')));
    await tester.pump();
    expect(find.byKey(Key('recent-outcome-$dryerSession')), findsOneWidget);
    expect(find.byKey(Key('recent-outcome-$washerSession')), findsNothing);

    await tester.tap(find.byKey(const Key('memory-filter-outcome-all')));
    await tester.pump();
    await tester.tap(find.byKey(Key('memory-filter-appliance-${washer.id}')));
    await tester.pump();
    expect(find.byKey(Key('recent-outcome-$washerSession')), findsOneWidget);
    expect(find.byKey(Key('recent-outcome-$dryerSession')), findsNothing);

    await tester.enterText(find.byKey(const Key('memory-search-field')), 'xyz-no-match');
    await tester.pump();
    expect(find.byKey(const Key('recent-activity-no-matches')), findsOneWidget);
    expect(find.text(UserFacingCopy.noMatchingRepairs), findsOneWidget);
    expect(find.byKey(const Key('recent-activity-list')), findsNothing);
  });
}
