import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/maintenance_reminder.dart';
import 'maintenance_notifier.dart';

/// Local OS ping when a reminder is already due. Future dues wait for next
/// app open (then [schedule] is called again). No calendar OAuth.
class PluginMaintenanceNotifier implements MaintenanceNotifier {
  PluginMaintenanceNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  bool notificationsAllowed = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _ensureInitialized();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      notificationsAllowed = granted ?? false;
      return notificationsAllowed;
    } catch (_) {
      notificationsAllowed = false;
      return false;
    }
  }

  @override
  Future<void> schedule(MaintenanceReminder reminder) async {
    try {
      await _ensureInitialized();
      if (reminder.done) {
        await cancel(reminder.id);
        return;
      }
      if (!notificationsAllowed) {
        final allowed = await requestPermission();
        if (!allowed) {
          return;
        }
      }
      final due = reminder.remindOn.toUtc();
      if (due.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 1)))) {
        return;
      }
      await _plugin.show(
        reminder.id.hashCode & 0x7fffffff,
        'Maintenance is due',
        reminder.note,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'maintenance_due',
            'Maintenance reminders',
            channelDescription: 'Local due reminders for household upkeep',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Future<void> cancel(String reminderId) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(reminderId.hashCode & 0x7fffffff);
    } catch (_) {}
  }
}
