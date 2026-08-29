import 'user_facing_error.dart';

/// Add-appliance scan copy and whether to show the action. Presentation only.
bool addApplianceShowsScanAction({
  required bool isWeb,
  required bool ocrAvailable,
  required bool barcodeAvailable,
  bool cameraOff = false,
}) {
  return !isWeb && !cameraOff && (ocrAvailable || barcodeAvailable);
}

String addApplianceIdentityHint({
  required bool isWeb,
  required bool scanAvailable,
}) {
  if (scanAvailable) {
    return UserFacingCopy.addApplianceScanHint;
  }
  if (isWeb) {
    return UserFacingCopy.addApplianceWebHint;
  }
  return UserFacingCopy.addApplianceManualHint;
}
