import '../models/household.dart';

/// Minimal in-memory store for immutable household records.
class HouseholdRepository {
  HouseholdRepository({void Function()? onChanged}) : _onChanged = onChanged;

  final void Function()? _onChanged;
  final Map<String, Household> _households = {};

  Household create(Household household) {
    if (_households.containsKey(household.id)) {
      throw StateError(
        'A household with id "${household.id}" already exists.',
      );
    }

    _households[household.id] = household;
    _onChanged?.call();
    return household;
  }

  Household? getById(String id) => _households[id];

  List<Household> listAll() => List.unmodifiable(_households.values);

  Household save(Household household) {
    _households[household.id] = household;
    _onChanged?.call();
    return household;
  }

  void delete(String id) {
    _households.remove(id);
    _onChanged?.call();
  }

  void replaceAll(List<Household> households) {
    _households
      ..clear()
      ..addEntries(
        households.map((household) => MapEntry(household.id, household)),
      );
  }
}
