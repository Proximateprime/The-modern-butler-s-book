import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/maintenance_reminder_copy.dart';
import 'package:modern_butlers_book/models/maintenance_reminder.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('reminder json keeps title, due date, appliance, and done', () {
    final reminder = MaintenanceReminder(
      id: 'reminder-1',
      householdId: 'household-1',
      applianceId: 'appliance-1',
      note: 'Clean the lint filter',
      remindOn: DateTime.utc(2026, 9, 1),
      createdAt: DateTime.utc(2026, 8, 16),
      done: true,
      lastDoneAt: DateTime.utc(2026, 8, 16),
      intervalDays: 30,
    );
    final restored = MaintenanceReminder.fromJson(reminder.toJson());
    expect(restored.title, 'Clean the lint filter');
    expect(restored.applianceId, 'appliance-1');
    expect(restored.remindOn, DateTime.utc(2026, 9, 1));
    expect(restored.done, isTrue);
    expect(restored.lastDoneAt, DateTime.utc(2026, 8, 16));
    expect(restored.intervalDays, 30);
    expect(
      MaintenanceReminder.fromJson({
        'id': 'reminder-2',
        'householdId': 'h',
        'applianceId': 'a',
        'note': 'Old note only',
        'remindOn': '2026-09-02T00:00:00.000Z',
        'createdAt': '2026-08-16T00:00:00.000Z',
      }).done,
      isFalse,
    );
  });

  test('upcoming returns next 1–3 undone by due date', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 22));
    deps.createHousehold('Upkeep House');
    final dryer = deps.addDryer();

    deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Later',
      remindOn: DateTime.utc(2026, 12, 1),
    );
    final first = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Soon',
      remindOn: DateTime.utc(2026, 9, 1),
    );
    deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Mid',
      remindOn: DateTime.utc(2026, 10, 1),
    );
    final extra = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Also soon',
      remindOn: DateTime.utc(2026, 9, 15),
    );
    deps.setMaintenanceReminderDone(extra.id, done: true);

    final upcoming = deps.upcomingMaintenanceReminders(limit: 3);
    expect(upcoming, hasLength(3));
    expect(upcoming.map((item) => item.title), ['Soon', 'Mid', 'Later']);
    expect(upcoming.every((item) => !item.done), isTrue);

    deps.setMaintenanceReminderDone(first.id, done: true);
    expect(
      deps.upcomingMaintenanceReminders(limit: 3).map((item) => item.title),
      ['Mid', 'Later'],
    );
  });

  test('done flag survives local persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      store: store,
    );
    first.createHousehold('Persist Upkeep');
    final dryer = first.addDryer();
    final reminder = first.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Vacuum the lint path',
      remindOn: DateTime.utc(2026, 9, 1),
    );
    first.setMaintenanceReminderDone(reminder.id, done: true);
    await first.flushPersist();

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      store: store,
    );
    await second.restore();
    final restored = second.maintenanceRemindersForAppliance(dryer.id).single;
    expect(restored.done, isTrue);
    expect(restored.title, 'Vacuum the lint path');
    expect(restored.lastDoneAt, DateTime.utc(2026, 8, 16));
    expect(second.upcomingMaintenanceReminders(), isEmpty);
  });

  testWidgets('home shows next upcoming reminders', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 22));
    deps.createHousehold('Home Upkeep');
    final dryer = deps.addDryer();
    final reminder = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Clean the lint filter',
      remindOn: DateTime.utc(2026, 9, 1),
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('upcoming-maintenance-title')), findsOneWidget);
    expect(find.byKey(Key('upcoming-reminder-${reminder.id}')), findsOneWidget);
    expect(find.text('Clean the lint filter'), findsOneWidget);

    await tester.tap(find.byKey(Key('upcoming-reminder-${reminder.id}')));
    await tester.pumpAndSettle();
    expect(deps.maintenanceRemindersForAppliance(dryer.id).single.done, isTrue);
    expect(find.byKey(const Key('upcoming-maintenance-title')), findsNothing);
  });

  testWidgets('appliance detail adds a reminder to the local list', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 22));
    deps.createHousehold('Detail Upkeep');
    final dryer = deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('appliance-add-reminder')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-reminder-title-field')),
      'Wipe the drum',
    );
    await tester.tap(find.byKey(const Key('add-reminder-save-button')));
    await tester.pumpAndSettle();

    expect(deps.maintenanceRemindersForAppliance(dryer.id), hasLength(1));
    expect(
      deps.maintenanceRemindersForAppliance(dryer.id).single.title,
      'Wipe the drum',
    );
    expect(find.text('Wipe the drum'), findsOneWidget);
    expect(find.byKey(const Key('appliance-maintenance-empty')), findsNothing);

    final reminder = deps.maintenanceRemindersForAppliance(dryer.id).single;
    await tester.tap(find.byKey(Key('maintenance-reminder-${reminder.id}')));
    await tester.pumpAndSettle();
    expect(deps.maintenanceRemindersForAppliance(dryer.id).single.done, isTrue);
    expect(
      find.textContaining('Last done 2026-08-16'),
      findsOneWidget,
    );
    expect(find.textContaining('Done 2026-08-16'), findsOneWidget);
    await tester.tap(find.byKey(Key('maintenance-reminder-${reminder.id}')));
    await tester.pumpAndSettle();
    expect(deps.maintenanceRemindersForAppliance(dryer.id).single.done, isFalse);
    expect(
      deps.maintenanceRemindersForAppliance(dryer.id).single.lastDoneAt,
      isNull,
    );
    expect(find.textContaining('Next due'), findsOneWidget);
  });

  test('checking Done records last done and rolls next due when interval exists',
      () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 12));
    deps.createHousehold('Interval House');
    final dryer = deps.addDryer();
    final withInterval = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Check the exterior vent hood',
      remindOn: DateTime.utc(2026, 8, 1),
      intervalDays: 30,
    );
    final oneShot = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Clean the lint filter every load',
      remindOn: DateTime.utc(2026, 8, 20),
    );

    deps.setMaintenanceReminderDone(withInterval.id, done: true);
    final rolled = deps.maintenanceRemindersForAppliance(dryer.id).firstWhere(
      (item) => item.id == withInterval.id,
    );
    expect(rolled.done, isTrue);
    expect(rolled.lastDoneAt, DateTime.utc(2026, 8, 18));
    expect(rolled.remindOn, DateTime.utc(2026, 9, 17));

    deps.setMaintenanceReminderDone(oneShot.id, done: true);
    final doneOnce = deps.maintenanceRemindersForAppliance(dryer.id).firstWhere(
      (item) => item.id == oneShot.id,
    );
    expect(doneOnce.lastDoneAt, DateTime.utc(2026, 8, 18));
    expect(doneOnce.remindOn, DateTime.utc(2026, 8, 20));
    expect(doneOnce.intervalDays, isNull);

    deps.setMaintenanceReminderDone(withInterval.id, done: false);
    final unchecked = deps.maintenanceRemindersForAppliance(dryer.id).firstWhere(
      (item) => item.id == withInterval.id,
    );
    expect(unchecked.done, isFalse);
    expect(unchecked.lastDoneAt, isNull);
    expect(unchecked.remindOn, DateTime.utc(2026, 9, 17));
  });

  test('overdue copy stays calm and check/uncheck updates lines', () {
    final now = DateTime.utc(2026, 8, 18);
    final overdue = MaintenanceReminder(
      id: 'r1',
      householdId: 'h',
      applianceId: 'a',
      note: 'Clean the lint filter',
      remindOn: DateTime.utc(2026, 8, 1),
      createdAt: DateTime.utc(2026, 7, 1),
      intervalDays: 30,
    );
    final copy = maintenanceReminderCopy(item: overdue, now: now);
    expect(copy.overdue, isTrue);
    expect(copy.subtitle, contains('Next due 2026-08-01 · Overdue'));
    expect(copy.subtitle, contains('About every 30 days'));
    expect(copy.subtitle.toLowerCase(), isNot(contains('due now')));
    expect(copy.subtitle.toLowerCase(), isNot(contains('late')));
    expect(copy.subtitle.contains('OVERDUE'), isFalse);

    final oneShotDone = MaintenanceReminder(
      id: 'r2',
      householdId: 'h',
      applianceId: 'a',
      note: 'Wipe the drum',
      remindOn: DateTime.utc(2026, 8, 20),
      createdAt: now,
      done: true,
      lastDoneAt: now,
    );
    final doneCopy = maintenanceReminderCopy(item: oneShotDone, now: now);
    expect(doneCopy.overdue, isFalse);
    expect(doneCopy.subtitle, contains('Last done 2026-08-18'));
    expect(doneCopy.subtitle, contains('Done 2026-08-18'));
    expect(doneCopy.subtitle, isNot(contains('Next due')));

    final repeating = MaintenanceReminder(
      id: 'r3',
      householdId: 'h',
      applianceId: 'a',
      note: 'Check the exterior vent hood',
      remindOn: DateTime.utc(2026, 8, 18),
      createdAt: DateTime.utc(2026, 7, 19),
      lastDoneAt: DateTime.utc(2026, 7, 19),
      intervalDays: 30,
    );
    final repeatingCopy = maintenanceReminderCopy(item: repeating, now: now);
    expect(repeatingCopy.overdue, isFalse);
    expect(repeatingCopy.subtitle, contains('Last done 2026-07-19'));
    expect(repeatingCopy.subtitle, contains('Next due 2026-08-18'));
    expect(repeatingCopy.subtitle, contains('About every 30 days'));
    expect(repeatingCopy.subtitle, isNot(contains('Overdue')));
  });

  testWidgets('phone-width maintenance row does not overflow', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 12));
    deps.createHousehold('Phone Upkeep');
    final dryer = deps.addDryer();
    deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note:
          'Vacuum accessible lint around the filter slot and check the '
          'crushed vent hose behind the dryer every 30 days',
      remindOn: DateTime.utc(2026, 8, 1),
      intervalDays: 30,
    );

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(Key('appliance-${dryer.id}')));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Overdue'), findsOneWidget);
    expect(find.textContaining('Due now'), findsNothing);

    final reminder = deps.maintenanceRemindersForAppliance(dryer.id).single;
    await tapVisible(
      tester,
      find.byKey(Key('maintenance-reminder-${reminder.id}')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Last done 2026-08-18'), findsOneWidget);
    expect(find.textContaining('Next due 2026-09-17'), findsOneWidget);
    expect(find.textContaining('Overdue'), findsNothing);
    expect(find.textContaining('About every 30 days'), findsOneWidget);
  });

  test('dryer vent/lint and washer filter notes infer a calendar interval', () {
    expect(
      inferMaintenanceIntervalDays(
        'Inspect the visible vent hose periodically for crush and lint',
      ),
      typicalCalendarMaintenanceDays,
    );
    expect(
      inferMaintenanceIntervalDays(
        'Keep the exterior vent hood clear of lint and nests',
      ),
      typicalCalendarMaintenanceDays,
    );
    expect(
      inferMaintenanceIntervalDays(
        'Vacuum accessible lint around the filter slot periodically',
      ),
      typicalCalendarMaintenanceDays,
    );
    expect(
      inferMaintenanceIntervalDays(
        'Clean the accessible drain filter on a regular schedule',
      ),
      typicalCalendarMaintenanceDays,
    );
    expect(inferMaintenanceIntervalDays(cleanLintSystemTitle), typicalCalendarMaintenanceDays);
    expect(
      inferMaintenanceIntervalDays('Clean the lint filter before every load'),
      isNull,
    );
    expect(inferMaintenanceIntervalDays('Wipe the drum'), isNull);
  });

  test('Done on vent/lint uses inferred interval; missing interval stays Done only',
      () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 12));
    deps.createHousehold('Inferred Interval House');
    final dryer = deps.addDryer();
    final washer = deps.addWasher();
    final vent = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Keep the exterior vent hood clear of lint and nests',
      remindOn: DateTime.utc(2026, 8, 1),
    );
    final washerFilter = deps.addMaintenanceReminder(
      applianceId: washer.id,
      note: 'Clean the accessible drain filter on a regular schedule',
      remindOn: DateTime.utc(2026, 8, 5),
    );
    final oneShot = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: 'Wipe the drum',
      remindOn: DateTime.utc(2026, 8, 20),
    );

    expect(vent.intervalDays, typicalCalendarMaintenanceDays);
    expect(washerFilter.intervalDays, typicalCalendarMaintenanceDays);
    expect(oneShot.intervalDays, isNull);

    deps.setMaintenanceReminderDone(vent.id, done: true);
    final rolledVent = deps.maintenanceRemindersForAppliance(dryer.id).firstWhere(
      (item) => item.id == vent.id,
    );
    expect(rolledVent.lastDoneAt, DateTime.utc(2026, 8, 18));
    expect(rolledVent.remindOn, DateTime.utc(2026, 9, 17));
    final ventCopy = maintenanceReminderCopy(item: rolledVent, now: deps.now);
    expect(ventCopy.subtitle, contains('Last done 2026-08-18'));
    expect(ventCopy.subtitle, contains('Next due 2026-09-17'));
    expect(ventCopy.subtitle, contains('About every 30 days'));

    deps.setMaintenanceReminderDone(washerFilter.id, done: true);
    final rolledWasher =
        deps.maintenanceRemindersForAppliance(washer.id).single;
    expect(rolledWasher.remindOn, DateTime.utc(2026, 9, 17));
    expect(
      maintenanceReminderCopy(item: rolledWasher, now: deps.now).subtitle,
      contains('Next due 2026-09-17'),
    );

    deps.setMaintenanceReminderDone(oneShot.id, done: true);
    final doneOnce = deps.maintenanceRemindersForAppliance(dryer.id).firstWhere(
      (item) => item.id == oneShot.id,
    );
    expect(doneOnce.remindOn, DateTime.utc(2026, 8, 20));
    final onceCopy = maintenanceReminderCopy(item: doneOnce, now: deps.now);
    expect(onceCopy.subtitle, contains('Done 2026-08-18'));
    expect(onceCopy.subtitle, isNot(contains('Next due')));
    expect(onceCopy.subtitle, isNot(contains('About every')));
  });

  testWidgets('Clean lint system Done rolls next due and survives restore', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = () => DateTime.utc(2026, 8, 22, 12);
    final deps = AppDependencies(clock: clock, store: store);
    deps.createHousehold('Lint System House');
    final dryer = deps.addDryer();
    final reminder = deps.addMaintenanceReminder(
      applianceId: dryer.id,
      note: cleanLintSystemTitle,
      remindOn: DateTime.utc(2026, 8, 1),
    );
    expect(reminder.intervalDays, typicalCalendarMaintenanceDays);
    expect(reminder.applianceId, dryer.id);

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();
    expect(find.text(cleanLintSystemTitle), findsOneWidget);
    expect(find.textContaining('Next due 2026-08-01 · Overdue'), findsOneWidget);

    await tester.tap(find.byKey(Key('maintenance-reminder-${reminder.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Last done 2026-08-22'), findsOneWidget);
    expect(find.textContaining('Next due 2026-09-21'), findsOneWidget);
    expect(find.textContaining('About every 30 days'), findsOneWidget);
    await deps.flushPersist();

    final restored = AppDependencies(clock: clock, store: store);
    await restored.restore();
    final saved = restored.maintenanceRemindersForAppliance(dryer.id).single;
    expect(saved.note, cleanLintSystemTitle);
    expect(saved.done, isTrue);
    expect(saved.lastDoneAt, DateTime.utc(2026, 8, 22));
    expect(saved.remindOn, DateTime.utc(2026, 9, 21));
    expect(saved.applianceId, dryer.id);
  });
}
