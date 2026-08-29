import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/rating_plate_parse.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/evidence_photo_picker.dart';
import 'package:modern_butlers_book/services/rating_plate_ocr.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

class _FakeOcr implements RatingPlateOcr {
  _FakeOcr({this.text, this.available = true});

  final String? text;
  final bool available;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> recognizeFile(String imagePath) async => text;
}

class _FakePicker implements EvidencePhotoPicker {
  _FakePicker({this.path = '/tmp/rating-plate.jpg', this.deny = false});

  final String path;
  final bool deny;

  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) async {
    if (deny) {
      throw const PhotoPermissionDeniedException();
    }
    return path;
  }
}

void main() {
  test('parseRatingPlateText reads labeled brand, model, and serial', () {
    final parsed = parseRatingPlateText(
      'WHIRLPOOL\n'
      'Model No. WFW5620HW\n'
      'Serial: C123456789\n',
    );
    expect(parsed.manufacturer, 'Whirlpool');
    expect(parsed.modelNumber, 'WFW5620HW');
    expect(parsed.serialNumber, 'C123456789');
  });

  test('parseRatingPlateText accepts S/N and Model labels', () {
    final parsed = parseRatingPlateText(
      'Brand: Samsung\nMODEL DVE45R6100W\nS/N 8K3Y12345\n',
    );
    expect(parsed.manufacturer, 'Samsung');
    expect(parsed.modelNumber, 'DVE45R6100W');
    expect(parsed.serialNumber, '8K3Y12345');
  });

  test('empty plate text stays empty so the form can be filled by hand', () {
    expect(parseRatingPlateText('   ').isEmpty, isTrue);
  });

  testWidgets('scan fills fields and save shows identity on detail', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      photoPicker: _FakePicker(),
      ratingPlateOcr: _FakeOcr(
        text:
            'Maytag\nModel MED5630HW\nSerial Number MX998877\n',
      ),
    );
    deps.createHousehold('Plate House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('add-appliance-brand-field')))
          .controller!
          .text,
      'Maytag',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('add-appliance-model-field')))
          .controller!
          .text,
      'MED5630HW',
    );

    await tester.enterText(
      find.byKey(const Key('add-appliance-serial-field')),
      'EDITED-SERIAL',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appliance-detail-brand')), findsOneWidget);
    expect(find.text('Brand: Maytag'), findsOneWidget);
    expect(find.text('Model: MED5630HW'), findsOneWidget);
    expect(find.text('Serial: EDITED-SERIAL'), findsOneWidget);
  });

  testWidgets('empty plate scan keeps the photo and still allows typing', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      photoPicker: _FakePicker(),
      ratingPlateOcr: _FakeOcr(text: '   '),
    );
    deps.createHousehold('Empty Plate House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();
    expect(find.text(UserFacingCopy.ratingPlateOcrEmpty), findsOneWidget);
    expect(find.byKey(const Key('add-appliance-rating-photo')), findsOneWidget);
    expect(find.text(UserFacingCopy.addApplianceRatingPhotoStaysLocal), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('add-appliance-brand-field')),
      'Kenmore',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      '11012345678',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-serial-field')),
      'SN-EMPTY-OCR',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();

    final dryer = deps.appliancesForCurrentHousehold().single;
    expect(dryer.ratingLabelPhotoPath, '/tmp/rating-plate.jpg');
    expect(dryer.modelNumber, '11012345678');
    expect(dryer.serialNumber, 'SN-EMPTY-OCR');
  });

  testWidgets('unavailable OCR falls back to manual entry', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      ratingPlateOcr: _FakeOcr(available: false),
    );
    deps.createHousehold('Manual Plate House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-washer-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(UserFacingCopy.addApplianceManualHint),
      findsOneWidget,
    );
    expect(find.text('Scan rating plate'), findsNothing);
    expect(find.byKey(const Key('add-appliance-scan-rating-plate')), findsNothing);
    expect(find.textContaining('Use phone app to scan'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('add-appliance-brand-field')),
      'LG',
    );
    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'WM4000HWA',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Washer'));
    await tester.pumpAndSettle();
    expect(find.text('Brand: LG'), findsOneWidget);
    expect(find.text('Model: WM4000HWA'), findsOneWidget);
  });

  testWidgets('permission denied shows a human banner and keeps the form', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      photoPicker: _FakePicker(deny: true),
      ratingPlateOcr: _FakeOcr(text: 'should not run'),
    );
    deps.createHousehold('Denied Plate House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-appliance-permissions-help')), findsOneWidget);
    expect(find.text(UserFacingCopy.permissionsCameraMicWhy), findsOneWidget);
    expect(find.text(UserFacingCopy.permissionsDeniedManual), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
    expect(find.text(UserFacingCopy.photoPermissionDenied), findsOneWidget);
    expect(find.byKey(const Key('add-appliance-brand-field')), findsOneWidget);
    expect(find.byKey(const Key('add-appliance-save-button')), findsOneWidget);
  });

  testWidgets('edit appliance can rescan and save identity on detail', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23),
      photoPicker: _FakePicker(),
      ratingPlateOcr: _FakeOcr(
        text: 'GE\nModel GTD45EASJWS\nSerial GE112233\n',
      ),
    );
    deps.createHousehold('Edit Plate House');
    deps.addDryer(
      name: 'Laundry Room Dryer',
      manufacturer: 'Old Brand',
      modelNumber: 'OLD-MODEL',
      serialNumber: 'OLD-SERIAL',
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.text('Brand: Old Brand'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appliance-edit-identity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-appliance-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'EDITED-MODEL',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Brand: GE'), findsOneWidget);
    expect(find.text('Model: EDITED-MODEL'), findsOneWidget);
    expect(find.text('Serial: GE112233'), findsOneWidget);
  });
}
