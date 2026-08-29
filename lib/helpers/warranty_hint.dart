import '../models/appliance.dart';

/// Non-legal display check only. Never infers or asserts warranty coverage.
bool shouldShowWarrantyHint(Appliance appliance) {
  return appliance.modelNumber.trim().isNotEmpty &&
      appliance.installationDate != null;
}
