/// Lifecycle status for an appliance in the household.
enum ApplianceStatus {
  active,
  retired,
  archived,
}

/// Fuel / energy for a dryer. Other families leave this [unknown].
enum ApplianceEnergySource {
  electric,
  gas,
  unknown,
}

ApplianceEnergySource applianceEnergySourceFromName(String? raw) {
  switch (raw) {
    case 'electric':
      return ApplianceEnergySource.electric;
    case 'gas':
      return ApplianceEnergySource.gas;
    default:
      return ApplianceEnergySource.unknown;
  }
}

/// Parses stored appliance status. Unknown / garbage values never become
/// [ApplianceStatus.active] (must not un-retire a hidden unit).
ApplianceStatus applianceStatusFromName(String? raw) {
  switch (raw) {
    case 'active':
      return ApplianceStatus.active;
    case 'retired':
      return ApplianceStatus.retired;
    case 'archived':
      return ApplianceStatus.archived;
    default:
      return ApplianceStatus.retired;
  }
}

/// True when the unit should appear on household home.
bool applianceIsListed(ApplianceStatus status) {
  return status == ApplianceStatus.active;
}

/// Minimal immutable identity and lifecycle record for one appliance.
class Appliance {
  const Appliance({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.manufacturer,
    required this.modelNumber,
    required this.location,
    required this.status,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.serialNumber,
    this.installationDate,
    this.estimatedAgeYears,
    this.ratingLabelPhotoPath,
    this.energySource = ApplianceEnergySource.unknown,
  });

  final String id;
  final String householdId;
  final String name;
  final String category;
  final String manufacturer;
  final String modelNumber;
  final String? serialNumber;
  final String location;
  final ApplianceStatus status;
  final DateTime? installationDate;
  final int? estimatedAgeYears;
  /// On-device path to an optional rating-plate photo. Never uploaded.
  final String? ratingLabelPhotoPath;
  /// Dryer fuel. Missing JSON and non-dryers are [ApplianceEnergySource.unknown].
  final ApplianceEnergySource energySource;
  final String schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appliance copyWith({
    String? name,
    String? manufacturer,
    String? modelNumber,
    String? serialNumber,
    bool clearSerialNumber = false,
    String? location,
    ApplianceStatus? status,
    DateTime? updatedAt,
    DateTime? installationDate,
    bool clearInstallationDate = false,
    int? estimatedAgeYears,
    bool clearEstimatedAgeYears = false,
    String? ratingLabelPhotoPath,
    bool clearRatingLabelPhotoPath = false,
    ApplianceEnergySource? energySource,
  }) {
    return Appliance(
      id: id,
      householdId: householdId,
      name: name ?? this.name,
      category: category,
      manufacturer: manufacturer ?? this.manufacturer,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber:
          clearSerialNumber ? null : (serialNumber ?? this.serialNumber),
      location: location ?? this.location,
      status: status ?? this.status,
      schemaVersion: schemaVersion,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      installationDate:
          clearInstallationDate
              ? null
              : (installationDate ?? this.installationDate),
      estimatedAgeYears:
          clearEstimatedAgeYears
              ? null
              : (estimatedAgeYears ?? this.estimatedAgeYears),
      ratingLabelPhotoPath:
          clearRatingLabelPhotoPath
              ? null
              : (ratingLabelPhotoPath ?? this.ratingLabelPhotoPath),
      energySource: energySource ?? this.energySource,
    );
  }
}
