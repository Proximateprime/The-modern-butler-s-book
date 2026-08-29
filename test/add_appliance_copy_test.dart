import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/add_appliance_scan_copy.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('web hint is one line and does not repeat the old scan string', () {
    expect(
      addApplianceShowsScanAction(
        isWeb: true,
        ocrAvailable: true,
        barcodeAvailable: true,
      ),
      isFalse,
    );
    final hint = addApplianceIdentityHint(isWeb: true, scanAvailable: false);
    expect(hint, UserFacingCopy.addApplianceWebHint);
    expect('Type brand and model here.'.allMatches(hint), hasLength(1));
    expect(hint.toLowerCase(), contains('phone-only'));
    expect(hint, isNot(contains('Use phone app to scan')));
    expect(hint.toLowerCase(), isNot(contains('ocr')));
    expect(
      addApplianceIdentityHint(isWeb: true, scanAvailable: true),
      UserFacingCopy.addApplianceScanHint,
    );
    expect(
      addApplianceIdentityHint(isWeb: true, scanAvailable: true).toLowerCase(),
      isNot(contains('phone-only')),
    );
  });

  test('phone shows Scan rating plate only when a scanner exists', () {
    expect(
      addApplianceShowsScanAction(
        isWeb: false,
        ocrAvailable: true,
        barcodeAvailable: false,
      ),
      isTrue,
    );
    expect(
      addApplianceShowsScanAction(
        isWeb: false,
        ocrAvailable: false,
        barcodeAvailable: true,
      ),
      isTrue,
    );
    expect(
      addApplianceShowsScanAction(
        isWeb: false,
        ocrAvailable: false,
        barcodeAvailable: false,
      ),
      isFalse,
    );
    expect(
      addApplianceShowsScanAction(
        isWeb: false,
        ocrAvailable: true,
        barcodeAvailable: true,
        cameraOff: true,
      ),
      isFalse,
    );
    expect(
      addApplianceIdentityHint(isWeb: false, scanAvailable: true),
      UserFacingCopy.addApplianceScanHint,
    );
    expect(
      addApplianceIdentityHint(isWeb: false, scanAvailable: false),
      UserFacingCopy.addApplianceManualHint,
    );
    expect(
      addApplianceIdentityHint(isWeb: false, scanAvailable: false).toLowerCase(),
      isNot(contains('scan')),
    );
  });

  testWidgets('Add dryer without a scanner is manual-only and still saves', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 15));
    deps.createHousehold('Manual Dryer House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-appliance-screen')), findsOneWidget);
    expect(find.text(UserFacingCopy.addApplianceWebHint), findsNothing);
    expect(find.textContaining('Use phone app to scan'), findsNothing);
    expect(find.byKey(const Key('add-appliance-barcode-web-hint')), findsNothing);
    expect(find.byKey(const Key('add-appliance-scan-rating-plate')), findsNothing);
    expect(find.text('Camera'), findsNothing);
    expect(find.text('Photo'), findsNothing);
    expect(find.text('Barcode'), findsNothing);
    expect(find.text(UserFacingCopy.addApplianceManualHint), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('add-appliance-brand-field')),
      'Maytag',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'MED5630HW',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.text('Brand: Maytag'), findsOneWidget);
    expect(find.text('Model: MED5630HW'), findsOneWidget);
  });
}
