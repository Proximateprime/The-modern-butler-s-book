import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/household_entitlement.dart';
import 'package:modern_butlers_book/helpers/inventory_export.dart';
import 'package:modern_butlers_book/helpers/pro_handoff.dart';
import 'package:modern_butlers_book/helpers/repair_log_export.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('Store billing is stubbed', () {
    expect(kStoreBillingWired, isFalse);
    expect(purchaseHouseholdProFromStore, throwsUnsupportedError);
  });

  test('free entitlement never locks repair, House Book, or safety', () {
    const free = HouseholdEntitlement(householdProEnabled: false);
    expect(free.allowsCoreRepair, isTrue);
    expect(free.allowsHouseBookBasics, isTrue);
    expect(free.allowsSafetyGuidance, isTrue);
    expect(free.allowsPremiumExportFormatting, isFalse);
    expect(free.allowsPackageCategory('dryer'), isTrue);
    expect(free.allowsPackageCategory('washer'), isTrue);
    expect(free.allowsPackageCategory('dishwasher'), isTrue);
    expect(free.allowsPackageCategory('fridge'), isTrue);
    expect(free.allowsAnotherHome(existingHomeCount: 0), isTrue);
    expect(free.allowsAnotherHome(existingHomeCount: 1), isTrue);
    expect(free.allowsAnotherPerson(existingMemberCount: 1), isTrue);
  });

  test('after Store wiring, extra homes need Household Pro', () {
    const free = HouseholdEntitlement(
      householdProEnabled: false,
      storeBillingWired: true,
    );
    const pro = HouseholdEntitlement(
      householdProEnabled: true,
      storeBillingWired: true,
    );
    expect(free.allowsAnotherHome(existingHomeCount: 0), isTrue);
    expect(free.allowsAnotherHome(existingHomeCount: 1), isFalse);
    expect(free.allowsAnotherPerson(existingMemberCount: 2), isFalse);
    expect(free.allowsPackageCategory('oven'), isFalse);
    expect(pro.allowsAnotherHome(existingHomeCount: 1), isTrue);
    expect(pro.allowsAnotherPerson(existingMemberCount: 2), isTrue);
    expect(pro.allowsPackageCategory('oven'), isTrue);
    expect(pro.allowsSafetyGuidance, isTrue);
  });

  test('safety stop copy does not take an entitlement', () {
    final stop = evaluateSafetyStop(
      evidence: [
        Evidence(
          id: 'e1',
          sessionId: 's1',
          applianceId: 'a1',
          type: EvidenceType.structuredAnswer,
          observation: 'Any smoke, burning smell, sparking, or melting?',
          answer: 'Yes',
          templateId: 'hazard-observation',
          collectedAt: DateTime.utc(2026, 8, 22, 19),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ],
    );
    expect(stop, isNotNull);
    expect(stop!.reason.toLowerCase(), contains('fire or smoke'));
    expect(
      const HouseholdEntitlement(
        householdProEnabled: false,
      ).allowsSafetyGuidance,
      isTrue,
    );
  });

  test('technician handoff stays available without Household Pro', () {
    final text = formatProHandoffSummary(
      applianceName: 'Dryer',
      date: DateTime.utc(2026, 8, 22),
      symptom: 'No heat',
      observations: const [],
      leaderHypothesis: 'Restricted exhaust',
      alreadyTried: const ['Cleaned the lint screen'],
      safetyNotes: defaultProHandoffSafetyNotes,
    );
    expect(text, contains('Technician handoff'));
    expect(text.toLowerCase(), contains('unplug'));
    expect(
      const HouseholdEntitlement(
        householdProEnabled: false,
      ).allowsSafetyGuidance,
      isTrue,
    );
  });

  test('premium inventory formatting adds people, free share does not', () {
    final dryer = Appliance(
      id: 'dryer-1',
      householdId: 'house-1',
      name: 'Laundry Room Dryer',
      category: 'dryer',
      manufacturer: 'Whirlpool',
      modelNumber: 'WED5000DW',
      serialNumber: 'DRY-SERIAL-1',
      location: 'Laundry Room',
      status: ApplianceStatus.active,
      schemaVersion: '1.0',
      createdAt: DateTime.utc(2026, 8, 22),
      updatedAt: DateTime.utc(2026, 8, 22),
    );
    final rows = [
      InventoryExportRow(
        appliance: dryer,
        lastRepairLine: '2026-08-22 · Lint · Fixed',
        lastRepairRootCause: 'Lint-packed vent',
        lastRepairContributing: const ['Skipped filter cleaning'],
      ),
    ];
    final generatedAt = DateTime.utc(2026, 8, 22, 12);
    final free = formatHouseholdInventoryExport(
      householdName: 'Sample home',
      generatedAt: generatedAt,
      rows: rows,
      memberNames: const ['Alex'],
    );
    final pro = formatHouseholdInventoryExport(
      householdName: 'Sample home',
      generatedAt: generatedAt,
      rows: rows,
      premiumFormatting: true,
      memberNames: const ['Alex'],
    );
    expect(free, contains('Serial: DRY-SERIAL-1'));
    expect(free, isNot(contains('People: Alex')));
    expect(free, isNot(contains('Root cause: Lint-packed vent')));
    expect(pro, contains('People: Alex'));
    expect(pro, contains('Root cause: Lint-packed vent'));
    expect(pro, contains('Also: Skipped filter cleaning'));
  });

  test('premium repair log adds root cause; free log still has prevention', () {
    final outcome = SessionOutcome(
      sessionId: 'session-1',
      resolutionStatus: SessionResolutionStatus.resolved,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Cleared the vent',
      rootCause: 'Lint-packed vent',
      contributingFactors: const ['Skipped filter cleaning'],
      preventiveActions: const ['Clean the lint filter every load'],
      verified: true,
      schemaVersion: '1.0',
      startSymptom: 'No heat',
    );
    final free = formatRepairLogExport(
      applianceName: 'Dryer',
      date: DateTime.utc(2026, 8, 22),
      outcome: outcome,
    );
    final pro = formatRepairLogExport(
      applianceName: 'Dryer',
      date: DateTime.utc(2026, 8, 22),
      outcome: outcome,
      premiumFormatting: true,
    );
    expect(free, contains('Clean the lint filter every load'));
    expect(free, isNot(contains('Root cause:')));
    expect(pro, contains('Root cause: Lint-packed vent'));
    expect(pro, contains('Also: Skipped filter cleaning'));
    expect(pro, contains('Clean the lint filter every load'));
  });

  test('Household Pro copy has no fake urgency', () {
    final blob = [
      UserFacingCopy.householdProTitle,
      UserFacingCopy.householdProSubtitle,
      UserFacingCopy.householdProNeverPaywallSafety,
      UserFacingCopy.householdProExtraHomeBlocked,
      UserFacingCopy.householdProExtraPersonBlocked,
    ].join(' ').toLowerCase();
    for (final phrase in HouseholdEntitlementUrgency.forbiddenPhrases) {
      expect(blob, isNot(contains(phrase)));
    }
  });

  test('Household Pro survives persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 22, 19);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Pro House');
    first.setHouseholdProEnabled(true);
    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    expect(second.householdProEnabled, isTrue);
    expect(second.entitlement.allowsPremiumExportFormatting, isTrue);
  });

  testWidgets('Settings toggle is honest debug copy, not a Store buy', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 19));
    deps.createHousehold('Gate House');
    deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-household-pro'));

    expect(find.text(UserFacingCopy.householdProTitle), findsOneWidget);
    expect(find.text(UserFacingCopy.householdProSubtitle), findsOneWidget);
    expect(
      find.text(UserFacingCopy.householdProNeverPaywallSafety),
      findsOneWidget,
    );
    expect(find.textContaining('Buy'), findsNothing);
    expect(find.textContaining('Subscribe'), findsNothing);

    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-household-pro')),
    );
    expect(toggle.value, isFalse);

    await tapVisible(tester, find.byKey(const Key('settings-household-pro')));
    await tester.pumpAndSettle();
    expect(deps.householdProEnabled, isTrue);
  });
}
