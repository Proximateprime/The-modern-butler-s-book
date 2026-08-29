import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/household_member_label.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('two people share appliances and history stays attributed', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 18));
    deps.createHousehold('Town House');
    final dryer = deps.addDryer(name: 'Town Dryer');
    final you = deps.currentMember!;
    expect(you.displayName, defaultHouseholdMemberDisplayName);

    final alex = deps.addHouseholdMember('Alex');
    expect(deps.currentMember?.id, alex.id);
    expect(
      deps.appliancesForCurrentHousehold().map((item) => item.name),
      ['Town Dryer'],
    );

    final sessionId = deps.startOrResumeSession(dryer);
    final session = deps.repairSessionRepository.getSession(sessionId)!;
    expect(session.createdByUserId, alex.id);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the lint filter',
    );

    deps.switchMember(you.id);
    expect(deps.currentMember?.displayName, defaultHouseholdMemberDisplayName);
    expect(
      deps.appliancesForCurrentHousehold().map((item) => item.name),
      ['Town Dryer'],
    );
    expect(deps.recentSessionOutcomes(), hasLength(1));
    expect(
      deps.displayNameForUserId(
        deps.recentSessionOutcomes().single.session.createdByUserId,
      ),
      'Alex',
    );
  });

  test('active person survives local persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 18),
      store: store,
    );
    first.createHousehold('Town House');
    first.addDryer(name: 'Town Dryer');
    first.addHouseholdMember('Alex');
    await first.flushPersist();

    final restored = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 18),
      store: store,
    );
    await restored.restore();
    expect(restored.currentMember?.displayName, 'Alex');
    expect(
      restored.appliancesForCurrentHousehold().map((item) => item.name),
      ['Town Dryer'],
    );
    expect(restored.listHouseholdMembers(), hasLength(2));
  });

  testWidgets('home can add a person and still see the same dryer', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 18));
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
    expect(find.byKey(const Key('current-member-label')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profiles-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-member-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('member-name-field')), 'Alex');
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.text('Using as Alex'), findsWidgets);
    expect(find.text('Laundry Room Dryer'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profiles-button')));
    await tester.pumpAndSettle();
    final you = deps.listHouseholdMembers().firstWhere(
      (item) => item.displayName == defaultHouseholdMemberDisplayName,
    );
    await tester.tap(find.byKey(Key('member-choice-${you.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Using as You'), findsWidgets);
    expect(find.text('Laundry Room Dryer'), findsOneWidget);
  });
}
