import '../models/maintenance_reminder.dart';

/// Calendar day in UTC so due/overdue copy does not shift with local offset.
DateTime maintenanceDateOnly(DateTime time) {
  final utc = time.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

String formatMaintenanceDate(DateTime time) {
  final day = maintenanceDateOnly(time);
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Typical calendar gap for dryer vent/lint and washer filter items.
const int typicalCalendarMaintenanceDays = 30;

/// Calendar reminder copy from confirmed prevention — not a dryer default.
String preferredCalendarMaintenanceNote(List<String> actions) {
  String? washerOrTubFilter;
  String? calendarItem;
  for (final raw in actions) {
    final action = raw.trim();
    if (action.isEmpty) {
      continue;
    }
    if (inferMaintenanceIntervalDays(action) == null) {
      continue;
    }
    final lower = action.toLowerCase();
    if (lower.contains('drain filter') ||
        lower.contains('pump trap') ||
        lower.contains('tub filter')) {
      washerOrTubFilter ??= action;
      continue;
    }
    calendarItem ??= action;
  }
  if (calendarItem != null) {
    return calendarItem;
  }
  if (washerOrTubFilter != null) {
    return washerOrTubFilter;
  }
  for (final raw in actions) {
    final action = raw.trim();
    if (action.isNotEmpty) {
      return action;
    }
  }
  return '';
}

/// Dryer lint-housing / vent-path upkeep (not the every-load filter screen).
const String cleanLintSystemTitle = 'Clean lint system';

/// Repeating calendar days from authored copy. Null for “every load” and unknown.
///
/// Does not invent a next-due for titles with no interval metadata.
int? inferMaintenanceIntervalDays(String note) {
  final lower = note.toLowerCase();
  if (lower.contains('every load')) {
    return null;
  }
  final match = RegExp(r'every (\d+) days').firstMatch(lower);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  if (_isDryerVentOrLintCalendarItem(lower) ||
      _isWasherFilterCalendarItem(lower)) {
    return typicalCalendarMaintenanceDays;
  }
  return null;
}

bool _isDryerVentOrLintCalendarItem(String lower) {
  if (lower.contains('lint system') ||
      lower.contains('lint pathway') ||
      lower.contains('lint-pathway')) {
    return true;
  }
  if (lower.contains('vent hood') ||
      lower.contains('vent hose') ||
      lower.contains('exterior vent') ||
      lower.contains('vent path')) {
    return true;
  }
  if (lower.contains('filter slot') ||
      lower.contains('lint housing') ||
      (lower.contains('lint') && lower.contains('vacuum'))) {
    return true;
  }
  return false;
}

bool _isWasherFilterCalendarItem(String lower) {
  return lower.contains('drain filter') ||
      lower.contains('pump trap') ||
      lower.contains('tub filter');
}

/// Next calendar due after Done. Null when there is no interval to apply.
DateTime? nextDueAfterDone({
  required DateTime lastDoneOn,
  required int? intervalDays,
}) {
  if (intervalDays == null || intervalDays <= 0) {
    return null;
  }
  return maintenanceDateOnly(lastDoneOn).add(Duration(days: intervalDays));
}

String? maintenanceIntervalLabel(MaintenanceReminder item) {
  if (item.note.toLowerCase().contains('every load')) {
    return 'Every load';
  }
  final days = item.intervalDays;
  if (days == null || days <= 0) {
    return null;
  }
  return 'About every $days days';
}

/// Speak-Human lines under a reminder title. No push or ranking.
class MaintenanceReminderCopy {
  const MaintenanceReminderCopy({
    required this.title,
    required this.lines,
    required this.overdue,
  });

  final String title;
  final List<String> lines;
  final bool overdue;

  String get subtitle => lines.join('\n');
}

MaintenanceReminderCopy maintenanceReminderCopy({
  required MaintenanceReminder item,
  required DateTime now,
  String? applianceName,
}) {
  final lines = <String>[];
  final lastDone = item.lastDoneAt;
  if (lastDone != null) {
    lines.add('Last done ${formatMaintenanceDate(lastDone)}');
  }

  final interval = maintenanceIntervalLabel(item);
  final hasCalendarRepeat = item.intervalDays != null && item.intervalDays! > 0;
  final today = maintenanceDateOnly(now);
  final dueDay = maintenanceDateOnly(item.remindOn);
  final overdue = !item.done && dueDay.isBefore(today);

  if (item.done && !hasCalendarRepeat) {
    final doneOn = lastDone ?? item.remindOn;
    lines.add('Done ${formatMaintenanceDate(doneOn)}');
  } else {
    if (overdue) {
      lines.add('Next due ${formatMaintenanceDate(item.remindOn)} · Overdue');
    } else {
      lines.add('Next due ${formatMaintenanceDate(item.remindOn)}');
    }
  }

  if (interval != null) {
    lines.add(interval);
  }

  final appliance = applianceName?.trim();
  if (appliance != null && appliance.isNotEmpty) {
    lines.add(appliance);
  }

  return MaintenanceReminderCopy(
    title: item.title,
    lines: lines,
    overdue: overdue,
  );
}
