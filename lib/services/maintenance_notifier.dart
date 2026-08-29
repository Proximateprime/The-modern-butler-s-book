import '../models/maintenance_reminder.dart';

/// Local reminder ping. Never a calendar OAuth or cloud push.
abstract class MaintenanceNotifier {
  Future<bool> requestPermission();

  Future<void> schedule(MaintenanceReminder reminder);

  Future<void> cancel(String reminderId);

  /// True after a successful permission grant this session.
  bool get notificationsAllowed;
}

/// Tests and web: store due dates only. Home shows an in-app due banner.
class SilentMaintenanceNotifier implements MaintenanceNotifier {
  SilentMaintenanceNotifier({this.notificationsAllowed = false});

  @override
  bool notificationsAllowed;

  final List<MaintenanceReminder> scheduled = [];
  final List<String> cancelledIds = [];
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return notificationsAllowed;
  }

  @override
  Future<void> schedule(MaintenanceReminder reminder) async {
    scheduled.removeWhere((item) => item.id == reminder.id);
    if (!reminder.done) {
      scheduled.add(reminder);
    }
  }

  @override
  Future<void> cancel(String reminderId) async {
    cancelledIds.add(reminderId);
    scheduled.removeWhere((item) => item.id == reminderId);
  }
}
