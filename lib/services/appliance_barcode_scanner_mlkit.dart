import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'appliance_barcode_scanner.dart';

ApplianceBarcodeScanner createApplianceBarcodeScanner() =>
    MlKitApplianceBarcodeScanner();

/// Android/iOS ML Kit barcode/QR. Other platforms report unavailable.
class MlKitApplianceBarcodeScanner implements ApplianceBarcodeScanner {
  MlKitApplianceBarcodeScanner({BarcodeScanner Function()? scannerFactory})
    : _scannerFactory =
          scannerFactory ??
          (() => BarcodeScanner(formats: [BarcodeFormat.all]));

  final BarcodeScanner Function() _scannerFactory;

  @override
  bool get isAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<String?> decodeFile(String imagePath) async {
    if (!isAvailable) {
      return null;
    }
    final path = imagePath.trim();
    if (path.isEmpty) {
      return null;
    }
    final scanner = _scannerFactory();
    try {
      final barcodes = await scanner.processImage(
        InputImage.fromFilePath(path),
      );
      for (final barcode in barcodes) {
        final value = barcode.rawValue?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
        final display = barcode.displayValue?.trim();
        if (display != null && display.isNotEmpty) {
          return display;
        }
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      await scanner.close();
    }
  }
}
