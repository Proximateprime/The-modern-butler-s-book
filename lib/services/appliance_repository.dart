import '../models/appliance.dart';

/// Minimal in-memory store for immutable appliance records.
class ApplianceRepository {
  ApplianceRepository({void Function()? onChanged}) : _onChanged = onChanged;

  final void Function()? _onChanged;
  final Map<String, Appliance> _appliances = {};

  Appliance create(Appliance appliance) {
    if (_appliances.containsKey(appliance.id)) {
      throw StateError(
        'An appliance with id "${appliance.id}" already exists.',
      );
    }

    _appliances[appliance.id] = appliance;
    _onChanged?.call();
    return appliance;
  }

  Appliance? getById(String id) => _appliances[id];

  /// Active appliances for a household (retired/archived hidden by default).
  List<Appliance> listForHousehold(
    String householdId, {
    bool includeArchived = false,
  }) {
    return List.unmodifiable(
      _appliances.values.where(
        (appliance) =>
            appliance.householdId == householdId &&
            (includeArchived || applianceIsListed(appliance.status)),
      ),
    );
  }

  List<Appliance> listAll() => List.unmodifiable(_appliances.values);

  /// Soft-retire: hides from home. Historical sessions keep their id.
  Appliance archive(String id, {required DateTime updatedAt}) {
    final existing = _appliances[id];
    if (existing == null) {
      throw StateError('Appliance "$id" was not found.');
    }
    if (!applianceIsListed(existing.status)) {
      return existing;
    }

    final retired = existing.copyWith(
      status: ApplianceStatus.retired,
      updatedAt: updatedAt,
    );
    _appliances[id] = retired;
    _onChanged?.call();
    return retired;
  }

  void delete(String id) {
    _appliances.remove(id);
    _onChanged?.call();
  }

  Appliance save(Appliance appliance) {
    _appliances[appliance.id] = appliance;
    _onChanged?.call();
    return appliance;
  }

  void replaceAll(List<Appliance> appliances) {
    _appliances
      ..clear()
      ..addEntries(
        appliances.map((appliance) => MapEntry(appliance.id, appliance)),
      );
  }
}
