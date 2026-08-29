import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/local_backup.dart';
import 'package:modern_butlers_book/helpers/local_backup_io.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  late List<String> exported;
  String? picked;

  setUp(() {
    exported = <String>[];
    picked = null;
    householdBackupExportHandler = (json) async {
      exported.add(json);
    };
    householdBackupPickHandler = () async => picked;
  });

  tearDown(() {
    householdBackupExportHandler = exportHouseholdBackupViaSystem;
    householdBackupPickHandler = pickHouseholdBackupViaSystem;
  });

  test('backup round-trips appliances, memory, tools, and reminders', () {
    final source = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 9));
    source.createHousehold('Backup House');
    final dryer = source.addDryer(name: 'Laundry Room Dryer');
    source.rememberOwnedTool('screwdriver');
    source.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Clean the lint filter',
      remindOn: DateTime.utc(2026, 9, 1),
    );
    final sessionId = source.startOrResumeSession(dryer);
    source.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleared the vent',
    );

    final json = source.exportHouseholdBackupJson();
    expect(json, contains(householdBackupKind));
    expect(json, isNot(contains('http://')));

    final dest = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 10));
    dest.createHousehold('Other House');
    dest.addDryer(name: 'Should Be Replaced');
    dest.restoreHouseholdBackupFromJson(json);

    expect(dest.currentHousehold?.name, 'Backup House');
    expect(dest.appliancesForCurrentHousehold().single.name, 'Laundry Room Dryer');
    expect(dest.currentHousehold!.ownedToolIds, contains('screwdriver'));
    expect(
      dest.maintenanceRemindersForAppliance(dryer.id).single.title,
      'Clean the lint filter',
    );
    expect(dest.repairHistoryForAppliance(dryer.id), hasLength(1));
    expect(
      dest.repairHistoryForAppliance(dryer.id).single.outcome.closeKind,
      SessionCloseKind.fixed,
    );
  });

  test('restore after a visible change brings back the exported state', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 15));
    deps.createHousehold('Smoke House');
    var dryer = deps.addDryer(name: 'Laundry Room Dryer');
    deps.rememberOwnedTool('screwdriver');
    final reminder = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Clean the lint filter',
      remindOn: DateTime.utc(2026, 9, 1),
    );
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleared the vent',
    );

    final json = deps.exportHouseholdBackupJson();

    dryer = deps.updateAppliance(
      appliance: dryer,
      name: 'Renamed Dryer',
      manufacturer: dryer.manufacturer,
      modelNumber: dryer.modelNumber,
      location: dryer.location,
    );
    deps.forgetOwnedTool('screwdriver');
    deps.setMaintenanceReminderDone(reminder.id, done: true);
    expect(deps.appliancesForCurrentHousehold().single.name, 'Renamed Dryer');
    expect(deps.currentHousehold!.ownedToolIds, isNot(contains('screwdriver')));
    expect(deps.maintenanceRemindersForAppliance(dryer.id).single.done, isTrue);

    deps.restoreHouseholdBackupFromJson(json);

    expect(deps.appliancesForCurrentHousehold().single.name, 'Laundry Room Dryer');
    expect(deps.currentHousehold!.ownedToolIds, contains('screwdriver'));
    expect(deps.maintenanceRemindersForAppliance(dryer.id).single.done, isFalse);
    expect(deps.repairHistoryForAppliance(dryer.id), hasLength(1));
  });

  test('invalid restore JSON does not wipe the current household', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 15, 10));
    deps.createHousehold('Keep House');
    deps.addDryer(name: 'Keep Dryer');
    deps.rememberOwnedTool('flashlight');

    expect(
      () => deps.restoreHouseholdBackupFromJson('not a backup'),
      throwsA(isA<BackupFileInvalidException>()),
    );
    expect(
      () => deps.restoreHouseholdBackupFromJson(
        '{"kind":"$householdBackupKind","snapshot":{}}',
      ),
      throwsA(isA<BackupFileInvalidException>()),
    );

    expect(deps.currentHousehold?.name, 'Keep House');
    expect(deps.appliancesForCurrentHousehold().single.name, 'Keep Dryer');
    expect(deps.currentHousehold!.ownedToolIds, contains('flashlight'));
  });

  test('bad backup file throws a human-facing error', () {
    expect(
      () => decodeHouseholdBackup('{not json'),
      throwsA(isA<BackupFileInvalidException>()),
    );
    expect(
      () => decodeHouseholdBackup('{"kind":"other","snapshot":{}}'),
      throwsA(isA<BackupFileInvalidException>()),
    );
    expect(
      userFacingErrorMessage(const BackupFileInvalidException()),
      UserFacingCopy.backupFileInvalid,
    );
  });

  testWidgets('settings export shares a local backup file', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 9));
    deps.createHousehold('Export House');
    deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-backup-export'));
    await tester.tap(find.byKey(const Key('settings-backup-export')));
    await tester.pumpAndSettle();

    expect(exported, hasLength(1));
    expect(exported.single, contains('Export House'));
    expect(find.text(UserFacingCopy.backupExported), findsOneWidget);
  });

  testWidgets('settings restore confirms then replaces household data', (
    tester,
  ) async {
    final source = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 9));
    source.createHousehold('From Backup');
    source.addDryer(name: 'Backup Dryer');
    picked = source.exportHouseholdBackupJson();

    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 11));
    deps.createHousehold('Will Replace');
    deps.addDryer(name: 'Old Dryer');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-backup-import'));
    await tester.tap(find.byKey(const Key('settings-backup-import')));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.backupImportConfirm), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-backup-import-cancel')));
    await tester.pumpAndSettle();
    expect(deps.currentHousehold?.name, 'Will Replace');

    await tester.tap(find.byKey(const Key('settings-backup-import')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-backup-import-confirm')));
    await tester.pumpAndSettle();

    expect(deps.currentHousehold?.name, 'From Backup');
    expect(
      deps.appliancesForCurrentHousehold().single.name,
      'Backup Dryer',
    );
    expect(find.text(UserFacingCopy.backupImported), findsOneWidget);
  });

  testWidgets('bad restore file shows a human message and keeps data', (
    tester,
  ) async {
    picked = 'not a backup';
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 9));
    deps.createHousehold('Keep House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-backup-import'));
    await tester.tap(find.byKey(const Key('settings-backup-import')));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.backupFileInvalid), findsOneWidget);
    expect(find.text(UserFacingCopy.backupImportConfirm), findsNothing);
    expect(deps.currentHousehold?.name, 'Keep House');
  });
}
