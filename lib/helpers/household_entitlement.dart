import 'package:flutter/foundation.dart';

/// Honest Household Pro placeholder. Store billing is not wired.
///
/// Never lock core repair, House Book basics, safety guidance, or emergency
/// stop copy. No fake urgency or scarcity.
const bool kStoreBillingWired = false;

/// Debug-only until there is something real to sell.
///
/// External testers on a release build must not see a toggle labelled
/// "(debug)". Everything it affects is optional export formatting, so hiding
/// it costs a tester nothing.
final bool householdProToggleVisible = kDebugMode;

/// Bundled families that ship as core repair. Extra families would be Pro
/// after Store wiring — none of the current four are extra.
const Set<String> kCoreRepairPackageCategories = {
  'dryer',
  'washer',
  'dishwasher',
  'fridge',
};

/// Copy in this feature must never use scarcity or countdown language.
abstract final class HouseholdEntitlementUrgency {
  static const forbiddenPhrases = [
    'limited time',
    'act now',
    'only today',
    'expires',
    'last chance',
    'hurry',
    'spots left',
  ];
}

class HouseholdEntitlement {
  const HouseholdEntitlement({
    required this.householdProEnabled,
    this.storeBillingWired = kStoreBillingWired,
  });

  final bool householdProEnabled;
  final bool storeBillingWired;

  /// Core repair on supported appliances. Always included.
  bool get allowsCoreRepair => true;

  /// Local House Book, history, tools, reminders, JSON backup, plain inventory.
  bool get allowsHouseBookBasics => true;

  /// Safety stops, disclaimer, and beginner-safe guidance. Never paywalled.
  bool get allowsSafetyGuidance => true;

  /// Extra lines on already-local exports (people, root cause). Not a lock on
  /// the basic share.
  bool get allowsPremiumExportFormatting => householdProEnabled;

  /// Extra homes / extra people. Unlocked until Store billing exists.
  bool get allowsMultiProfileExtras =>
      householdProEnabled || !storeBillingWired;

  /// Packages beyond [kCoreRepairPackageCategories]. Unlocked until Store.
  bool get allowsExtraPackages => householdProEnabled || !storeBillingWired;

  bool allowsPackageCategory(String category) {
    if (kCoreRepairPackageCategories.contains(category)) {
      return allowsCoreRepair;
    }
    return allowsExtraPackages;
  }

  bool allowsAnotherHome({required int existingHomeCount}) {
    if (existingHomeCount <= 0) {
      return true;
    }
    return allowsMultiProfileExtras;
  }

  bool allowsAnotherPerson({required int existingMemberCount}) {
    if (existingMemberCount <= 1) {
      return true;
    }
    return allowsMultiProfileExtras;
  }
}

/// Store IAP is not connected. Do not show a fake Buy button.
Never purchaseHouseholdProFromStore() {
  throw UnsupportedError(
    'Store billing is not wired. Use the Household Pro debug toggle.',
  );
}
