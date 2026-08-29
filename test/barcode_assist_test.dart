import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/appliance_barcode_parse.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/appliance_barcode_scanner.dart';
import 'package:modern_butlers_book/services/evidence_photo_picker.dart';
import 'package:modern_butlers_book/services/rating_plate_ocr.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

class _FakePicker implements EvidencePhotoPicker {
  _FakePicker({this.path = '/tmp/appliance-barcode.jpg'});

  final String path;

  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) async => path;
}

class _FakeScanner implements ApplianceBarcodeScanner {
  _FakeScanner({this.payload, this.available = true});

  final String? payload;
  final bool available;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> decodeFile(String imagePath) async => payload;
}

class _FakeOcr implements RatingPlateOcr {
  _FakeOcr({this.text, this.available = true});

  final String? text;
  final bool available;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> recognizeFile(String imagePath) async => text;
}

void main() {
  test('plain model barcode maps to the model field', () {
    final parsed = parseApplianceBarcodePayload('MED5630HW');
    expect(parsed.modelNumber, 'MED5630HW');
    expect(parsed.manufacturer, isEmpty);
  });

  test('QR JSON and URL query map onto OCR identity fields', () {
    final json = parseApplianceBarcodePayload(
      '{"brand":"LG","model":"WM4000HWA","serial":"LG9988"}',
    );
    expect(json.manufacturer, 'LG');
    expect(json.modelNumber, 'WM4000HWA');
    expect(json.serialNumber, 'LG9988');

    final url = parseApplianceBarcodePayload(
      'https://parts.example.com/item?model=WFW5620HW&brand=Whirlpool',
    );
    expect(url.manufacturer, 'Whirlpool');
    expect(url.modelNumber, 'WFW5620HW');
  });

  test('UPC digits do not invent a model — household types it', () {
    expect(parseApplianceBarcodePayload('012345678905').isEmpty, isTrue);
    expect(parseApplianceBarcodePayload('   ').isEmpty, isTrue);
  });

  testWidgets('barcode scan fills the same model field as OCR', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23, 30),
      photoPicker: _FakePicker(),
      ratingPlateOcr: _FakeOcr(available: false),
      barcodeScanner: _FakeScanner(payload: 'MED5630HW'),
    );
    deps.createHousehold('Barcode House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('add-appliance-model-field')))
          .controller!
          .text,
      'MED5630HW',
    );

    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.text('Model: MED5630HW'), findsOneWidget);
  });

  testWidgets('parsed barcode brand model and serial persist on the appliance', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 16, 40),
      photoPicker: _FakePicker(),
      ratingPlateOcr: _FakeOcr(available: false),
      barcodeScanner: _FakeScanner(
        payload: '{"brand":"Samsung","model":"DVE45T6000W","serial":"S12345"}',
      ),
    );
    deps.createHousehold('Identity Barcode House');

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
      'Samsung',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('add-appliance-model-field')))
          .controller!
          .text,
      'DVE45T6000W',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('add-appliance-serial-field')))
          .controller!
          .text,
      'S12345',
    );

    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Samsung'), findsWidgets);
    expect(find.text('Model: DVE45T6000W'), findsOneWidget);
    expect(find.text('Serial: S12345'), findsOneWidget);
  });

  testWidgets('unmapped barcode leaves fields manual', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23, 31),
      photoPicker: _FakePicker(),
      ratingPlateOcr: _FakeOcr(available: false),
      barcodeScanner: _FakeScanner(payload: '012345678905'),
    );
    deps.createHousehold('Manual Barcode House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-washer-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();
    expect(find.text(UserFacingCopy.barcodeScanEmpty), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('add-appliance-model-field')))
          .controller!
          .text,
      isEmpty,
    );

    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'WM4000HWA',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Washer'));
    await tester.pumpAndSettle();
    expect(find.text('Model: WM4000HWA'), findsOneWidget);
  });

  testWidgets('barcode permission denied keeps manual fields and does not crash', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 16),
      photoPicker: _DenyPicker(),
      barcodeScanner: _FakeScanner(payload: 'MED5630HW'),
    );
    deps.createHousehold('Denied Barcode House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-appliance-scan-rating-plate')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
    expect(find.byKey(const Key('add-appliance-brand-field')), findsOneWidget);
    expect(find.byKey(const Key('add-appliance-model-field')), findsOneWidget);
    expect(find.byKey(const Key('add-appliance-serial-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('add-appliance-model-field')),
      'MED5630HW',
    );
    await tester.tap(find.byKey(const Key('add-appliance-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.text('Model: MED5630HW'), findsOneWidget);
  });
}

class _DenyPicker implements EvidencePhotoPicker {
  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) {
    throw const PhotoPermissionDeniedException();
  }
}
