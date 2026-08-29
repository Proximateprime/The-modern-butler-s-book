/// Reads a barcode/QR payload from a local photo. Never used for diagnosis.
abstract class ApplianceBarcodeScanner {
  bool get isAvailable;

  Future<String?> decodeFile(String imagePath);
}

/// Web / desktop / tests unless a fake is injected.
class UnavailableApplianceBarcodeScanner implements ApplianceBarcodeScanner {
  const UnavailableApplianceBarcodeScanner();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> decodeFile(String imagePath) async => null;
}
