import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/rating_plate_parse.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/warranty_hint.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('hint needs model and install/purchase date — never warranty as fact', () {
    const copy = UserFacingCopy.warrantyHint;
    expect(copy.toLowerCase(), contains('may still'));
    expect(copy.toLowerCase(), isNot(contains('is under warranty')));
    expect(copy.toLowerCase(), isNot(contains('covered')));

    final withBoth = Appliance(
      id: 'a1',
      householdId: 'h1',
      name: 'Dryer',
      category: 'dryer',
      manufacturer: 'Whirlpool',
      modelNumber: 'WED5000DW',
      location: 'Laundry',
      status: ApplianceStatus.active,
      schemaVersion: '1.0',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      installationDate: DateTime.utc(2025, 3, 1),
    );
    expect(shouldShowWarrantyHint(withBoth), isTrue);

    expect(
      shouldShowWarrantyHint(
        withBoth.copyWith(modelNumber: '  ', clearInstallationDate: false),
      ),
      isFalse,
    );
    expect(
      shouldShowWarrantyHint(withBoth.copyWith(clearInstallationDate: true)),
      isFalse,
    );
  });

  test('OCR reads labeled install/purchase dates and ignores manufacture dates', () {
    final purchased = parseRatingPlateText(
      'Whirlpool\nModel WED5000DW\nPurchase date: 2025-03-01\n',
    );
    expect(purchased.modelNumber, 'WED5000DW');
    expect(purchased.installationDate, DateTime.utc(2025, 3, 1));

    final installed = parseRatingPlateText(
      'Model ABC1234X\nInstalled 03/15/2024\n',
    );
    expect(installed.installationDate, DateTime.utc(2024, 3, 15));

    final mfgOnly = parseRatingPlateText(
      'Model ABC1234X\nMFG DATE 2020-01-01\n',
    );
    expect(mfgOnly.installationDate, isNull);
  });

  testWidgets('detail and diagnosis show the hint only when model and date exist', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 12));
    deps.createHousehold('Warranty House');
    final withoutDate = deps.addDryer(name: 'No Date Dryer');
    final withDate = deps.addDryer(
      name: 'Dated Dryer',
      modelNumber: 'WED5000DW',
      installationDate: DateTime.utc(2025, 6, 1),
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('appliance-${withoutDate.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hint')), findsNothing);
    expect(find.text(UserFacingCopy.warrantyHint), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${withDate.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warranty-hint')), findsOneWidget);
    expect(find.text(UserFacingCopy.warrantyHint), findsOneWidget);

    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);
    expect(find.byKey(const Key('warranty-hint')), findsOneWidget);
    expect(find.text(UserFacingCopy.warrantyHint), findsOneWidget);
    expect(find.text('Now: Answering questions'), findsOneWidget);
  });
}
