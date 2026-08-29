/// Local-only maintenance reminder. No push or server.
class MaintenanceReminder {
  const MaintenanceReminder({
    required this.id,
    required this.householdId,
    required this.applianceId,
    required this.note,
    required this.remindOn,
    required this.createdAt,
    this.sessionId,
    this.done = false,
    this.lastDoneAt,
    this.intervalDays,
  });

  final String id;
  final String householdId;
  final String applianceId;
  final String note;
  final DateTime remindOn;
  final DateTime createdAt;
  final String? sessionId;
  final bool done;

  /// When the household last marked this done. Null if never completed.
  final DateTime? lastDoneAt;

  /// Repeating gap in days when the source copy has one. Null if unknown.
  final int? intervalDays;

  /// Display title — same as [note].
  String get title => note;

  MaintenanceReminder copyWith({
    String? note,
    DateTime? remindOn,
    bool? done,
    DateTime? lastDoneAt,
    int? intervalDays,
    bool clearLastDone = false,
  }) {
    return MaintenanceReminder(
      id: id,
      householdId: householdId,
      applianceId: applianceId,
      note: note ?? this.note,
      remindOn: remindOn ?? this.remindOn,
      createdAt: createdAt,
      sessionId: sessionId,
      done: done ?? this.done,
      lastDoneAt: clearLastDone ? null : (lastDoneAt ?? this.lastDoneAt),
      intervalDays: intervalDays ?? this.intervalDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'householdId': householdId,
      'applianceId': applianceId,
      'note': note,
      'title': note,
      'remindOn': remindOn.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'done': done,
      if (sessionId != null) 'sessionId': sessionId,
      if (lastDoneAt != null) 'lastDoneAt': lastDoneAt!.toIso8601String(),
      if (intervalDays != null) 'intervalDays': intervalDays,
    };
  }

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) {
    return MaintenanceReminder(
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      applianceId: json['applianceId'] as String,
      note: json['title'] as String? ?? json['note'] as String? ?? '',
      remindOn: DateTime.parse(json['remindOn'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sessionId: json['sessionId'] as String?,
      done: json['done'] as bool? ?? false,
      lastDoneAt:
          json['lastDoneAt'] == null
              ? null
              : DateTime.parse(json['lastDoneAt'] as String),
      intervalDays: json['intervalDays'] as int?,
    );
  }
}
