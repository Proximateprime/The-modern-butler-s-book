import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/demo_sample_home.dart';
import 'package:modern_butlers_book/helpers/inventory_export.dart';
import 'package:modern_butlers_book/helpers/repair_log_share.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/appliance.dart';
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

  test('inventory text lists model and serial for two appliances', () {
    final generatedAt = DateTime.utc(2026, 8, 22, 12);
    final dryer = Appliance(
      id: 'dryer-1',
      householdId: 'house-1',
      name: 'Laundry Room Dryer',
      category: 'dryer',
      manufacturer: 'Whirlpool',
      modelNumber: 'WED5000DW',
      serialNumber: 'DRY-SERIAL-1',
      location: 'Laundry Room',
      status: ApplianceStatus.active,
      schemaVersion: '1.0',
      createdAt: generatedAt,
      updatedAt: generatedAt,
    );
    final washer = Appliance(
      id: 'washer-1',
      householdId: 'house-1',
      name: 'Laundry Room Washer',
      category: 'washer',
      manufacturer: 'Whirlpool',
      modelNumber: 'WTW5000DW',
      serialNumber: 'WASH-SERIAL-1',
      location: 'Laundry Room',
      status: ApplianceStatus.active,
      schemaVersion: '1.0',
      createdAt: generatedAt,
      updatedAt: generatedAt,
    );

    final text = formatHouseholdInventoryExport(
      householdName: 'Sample home',
      generatedAt: generatedAt,
      rows: [
        InventoryExportRow(
          appliance: dryer,
          lastRepairLine: inventoryLastRepairLine(
            completedAt: generatedAt,
            outcome: SessionOutcome(
              sessionId: 'session-1',
              resolutionStatus: SessionResolutionStatus.resolved,
              closeKind: SessionCloseKind.fixed,
              immediateCause: 'Lint cleaned thoroughly',
              contributingFactors: const [],
              preventiveActions: const [],
              verified: true,
              schemaVersion: '1.0',
            ),
          ),
        ),
        InventoryExportRow(appliance: washer),
      ],
    );

    expect(text, contains('Household: Sample home'));
    expect(text, contains('On this device. Not uploaded.'));
    expect(text, contains('Laundry Room Dryer'));
    expect(text, contains('Model: WED5000DW'));
    expect(text, contains('Serial: DRY-SERIAL-1'));
    expect(text, contains('Last repair:'));
    expect(text, contains('Lint cleaned thoroughly'));
    expect(text, contains('Laundry Room Washer'));
    expect(text, contains('Model: WTW5000DW'));
    expect(text, contains('Serial: WASH-SERIAL-1'));
    expect(text, contains('Notes: —'));
    expect(text, isNot(contains('http')));
  });

  testWidgets('House Book Export inventory shares two sample appliances', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 12));
    deps.includeSampleOpenSession = false;
    deps.loadSampleHome();

    await prepareTallSurface(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(dependencies: deps)));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.exportInventoryTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-inventory-button')));
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    final text = shared.single;
    expect(text, contains('Household: ${DemoSampleHome.householdName}'));
    expect(text, contains('Model: ${DemoSampleHome.modelNumber}'));
    expect(text, contains('Serial: ${DemoSampleHome.dryerSerial}'));
    expect(text, contains('Model: ${DemoSampleHome.washerModelNumber}'));
    expect(text, contains('Serial: ${DemoSampleHome.washerSerial}'));
    expect(text, contains('Last repair:'));
    expect(text, isNot(contains('http')));
    expect(find.byKey(const Key('export-inventory-snackbar')), findsOneWidget);
  });
}
