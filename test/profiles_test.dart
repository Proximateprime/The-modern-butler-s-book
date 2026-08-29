import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('second profile hides the first household appliances and memory', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 21));
    final first = deps.createHousehold('Town House');
    final dryer = deps.addDryer(name: 'Town Dryer');
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the lint filter',
    );

    expect(deps.appliancesForCurrentHousehold().single.name, 'Town Dryer');
    expect(deps.recentSessionOutcomes(), hasLength(1));

    final second = deps.createHousehold('Lake House');
    expect(deps.currentHousehold?.id, second.id);
    expect(deps.appliancesForCurrentHousehold(), isEmpty);
    expect(deps.recentSessionOutcomes(), isEmpty);

    deps.addDryer(name: 'Lake Dryer');
    expect(
      deps.appliancesForCurrentHousehold().map((item) => item.name),
      ['Lake Dryer'],
    );

    deps.switchHousehold(first.id);
    expect(deps.currentHousehold?.name, 'Town House');
    expect(
      deps.appliancesForCurrentHousehold().map((item) => item.name),
      ['Town Dryer'],
    );
    expect(deps.recentSessionOutcomes(), hasLength(1));
    expect(
      deps.recentSessionOutcomes().single.outcome.immediateCause,
      'Cleaned the lint filter',
    );
  });

  test('active profile survives local persist without cloud auth', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 21),
      store: store,
    );
    first.createHousehold('Town House');
    first.addDryer(name: 'Town Dryer');
    first.createHousehold('Lake House');
    first.addDryer(name: 'Lake Dryer');
    await first.flushPersist();

    final restored = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 21),
      store: store,
    );
    await restored.restore();
    expect(restored.currentHousehold?.name, 'Lake House');
    expect(
      restored.appliancesForCurrentHousehold().map((item) => item.name),
      ['Lake Dryer'],
    );
    expect(restored.listHouseholds(), hasLength(2));
  });

  testWidgets('home can add a second profile and switch back', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 21));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      'Town House',
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();
    await confirmAddAppliance(tester);

    expect(find.text('Laundry Room Dryer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('profiles-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profiles-sheet-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-profile-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      'Lake House',
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.text('Lake House'), findsOneWidget);
    expect(find.text('Laundry Room Dryer'), findsNothing);
    expect(find.byKey(const Key('recent-activity-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profiles-button')));
    await tester.pumpAndSettle();
    final town = deps.listHouseholds().firstWhere(
      (item) => item.name == 'Town House',
    );
    await tester.tap(find.byKey(Key('profile-choice-${town.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Town House'), findsOneWidget);
    expect(find.text('Laundry Room Dryer'), findsOneWidget);
  });
}
