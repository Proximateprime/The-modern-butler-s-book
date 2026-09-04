import 'dart:io';

import '../models/enrichment_note.dart';
import '../models/maintenance_reminder.dart';
import '../models/repair_comfort_profile.dart';
import '../models/session_ui_resume_state.dart';
import '../services/local_domain_store.dart';

/// Empty House Book snapshot. No homes, appliances, sessions, or reminders.
DomainSnapshot emptyHouseBookSnapshot() {
  return DomainSnapshot(
    idCounter: 0,
    lastTimestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    currentHouseholdId: null,
    currentMemberId: null,
    sessionIdByApplianceId: const {},
    packageRefsBySession: const {},
    households: const [],
    appliances: const [],
    sessions: const [],
    evidence: const [],
    evidenceLinks: const [],
    hypotheses: const [],
    hypothesisIdsBySession: const {},
    outcomes: const [],
    sessionUiResumeBySessionId: const <String, SessionUiResumeState>{},
    foregroundSessionId: null,
    maintenanceReminders: const <MaintenanceReminder>[],
    repairComfort: const RepairComfortProfile(),
    expertMode: false,
    householdProEnabled: false,
    dismissedPatternHintKeys: const [],
    enrichmentNotes: const <EnrichmentNote>[],
  );
}

/// Best-effort delete of locally attached household photos. Never a cloud call.
Future<void> deleteLocalHouseholdPhotoFiles(Iterable<String?> paths) async {
  for (final raw in paths) {
    final path = raw?.trim() ?? '';
    if (path.isEmpty) {
      continue;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
