import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('add dryer and washer with model and serial; listed after restore', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = () => DateTime.utc(2026, 8, 22, 12);

    final deps = AppDependencies(clock: clock, store: store);
    deps.createHousehold('House Book');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();
    expect(find.text(UserFacingCopy.addApplianceSerialHint), findsOneWidget);
    expect(find.text(UserFacingCopy.addApplianceLocationHint), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('add-appliance-brand-field')),
      'Whirlpool',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'WED5000DW',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-serial-field')),
      'DRY-SERIAL-1',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-washer-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-appliance-brand-field')),
      'Whirlpool',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'WTW5000DW',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-serial-field')),
      'WASH-SERIAL-1',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Laundry Room Dryer'), findsOneWidget);
    expect(find.text('Laundry Room Washer'), findsOneWidget);
    expect(find.text('Model WED5000DW'), findsOneWidget);
    expect(find.text('Model WTW5000DW'), findsOneWidget);

    await deps.flushPersist();

    final restored = AppDependencies(clock: clock, store: store);
    await restored.restore();
    expect(restored.appliancesForCurrentHousehold(), hasLength(2));
    final names =
        restored.appliancesForCurrentHousehold().map((a) => a.name).toSet();
    expect(names, containsAll(['Laundry Room Dryer', 'Laundry Room Washer']));
    final dryer = restored
        .appliancesForCurrentHousehold()
        .singleWhere((a) => a.category == 'dryer');
    final washer = restored
        .appliancesForCurrentHousehold()
        .singleWhere((a) => a.category == 'washer');
    expect(dryer.modelNumber, 'WED5000DW');
    expect(dryer.serialNumber, 'DRY-SERIAL-1');
    expect(dryer.location, 'Laundry Room');
    expect(washer.modelNumber, 'WTW5000DW');
    expect(washer.serialNumber, 'WASH-SERIAL-1');

    await tester.pumpWidget(MaterialApp(home: HomeScreen(dependencies: restored)));
    await tester.pumpAndSettle();
    expect(find.text('Laundry Room Dryer'), findsOneWidget);
    expect(find.text('Laundry Room Washer'), findsOneWidget);

    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Model: WED5000DW'), findsOneWidget);
    expect(find.text('Serial: DRY-SERIAL-1'), findsOneWidget);
  });
}
