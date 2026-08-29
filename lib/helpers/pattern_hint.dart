import '../models/maintenance_reminder.dart';
import '../models/session_outcome.dart';

/// Smallest repeat count that may surface a household-history hint.
const int patternHintMinOccurrences = 2;

const String patternHintFamilyVent = 'vent';
const String patternHintFamilyDrainFilter = 'drain-filter';
const String patternHintFamilyCoils = 'coils';

const String patternHintTitle = 'From your household history';

/// Modes that must not become a DIY pattern hint (pro / not a maintenance loop).
const Set<String> patternHintExcludedModeIds = {
  'thermal-fuse-open',
  'heating-element-failed',
  'electric-supply-connection-fault',
  'motor-failure',
  'electrical-burning-smell-hazard',
};

const Map<String, String> patternHintFamilyByModeId = {
  'restricted-exhaust-airflow': patternHintFamilyVent,
  'clogged-lint-pathway': patternHintFamilyVent,
  'clogged-washer-drain-filter': patternHintFamilyDrainFilter,
  'kinked-or-clogged-washer-drain-hose': patternHintFamilyDrainFilter,
  'clogged-dishwasher-filter': patternHintFamilyDrainFilter,
  'kinked-or-clogged-dishwasher-drain': patternHintFamilyDrainFilter,
  'blocked-fridge-coils-or-airflow': patternHintFamilyCoils,
};

/// Calm, on-device suggestion from repeated verified records. Not ranking.
class PatternHint {
  const PatternHint({
    required this.familyId,
    required this.body,
    required this.occurrenceCount,
  });

  final String familyId;
  final String body;
  final int occurrenceCount;

  String get title => patternHintTitle;
}

/// Classifies one verified Fixed outcome into a maintenance family, or null.
String? patternFamilyIdForOutcome(SessionOutcome outcome) {
  if (!outcome.verified || outcome.closeKind != SessionCloseKind.fixed) {
    return null;
  }
  final mode = outcome.rankingLeaderFailureModeId?.trim() ?? '';
  if (mode.isNotEmpty && patternHintExcludedModeIds.contains(mode)) {
    return null;
  }
  final fromText = patternFamilyIdFromRecord(
    failureModeId: null,
    texts: [outcome.immediateCause, outcome.rootCause],
  );
  if (fromText != null) {
    return fromText;
  }
  if (_hasExplicitUnclassifiedCause(outcome.immediateCause) ||
      _hasExplicitUnclassifiedCause(outcome.rootCause)) {
    return null;
  }
  return patternFamilyIdFromRecord(
    failureModeId: outcome.rankingLeaderFailureModeId,
    texts: const [],
  );
}

/// Classifies a local maintenance reminder note.
String? patternFamilyIdForReminder(MaintenanceReminder reminder) {
  return patternFamilyIdFromRecord(
    failureModeId: null,
    texts: [reminder.note],
  );
}

String? patternFamilyIdFromRecord({
  required String? failureModeId,
  required Iterable<String?> texts,
}) {
  final mode = failureModeId?.trim() ?? '';
  if (mode.isNotEmpty && patternHintExcludedModeIds.contains(mode)) {
    return null;
  }
  if (mode.isNotEmpty && patternHintFamilyByModeId.containsKey(mode)) {
    return patternHintFamilyByModeId[mode];
  }
  final blob = texts
      .map((item) => (item ?? '').toLowerCase())
      .where((item) => item.isNotEmpty)
      .join(' ');
  if (blob.isEmpty) {
    return null;
  }
  if (_looksLikeVent(blob)) {
    return patternHintFamilyVent;
  }
  if (_looksLikeDrainFilter(blob)) {
    return patternHintFamilyDrainFilter;
  }
  if (_looksLikeCoils(blob)) {
    return patternHintFamilyCoils;
  }
  return null;
}

/// Returns a hint only when one authored family appears at least [minOccurrences]
/// times across verified Fixed history and maintenance records. Otherwise null.
PatternHint? patternHintFromHistory({
  required Iterable<SessionOutcome> outcomes,
  required Iterable<MaintenanceReminder> reminders,
  Set<String> dismissedFamilyIds = const {},
  int minOccurrences = patternHintMinOccurrences,
}) {
  final counts = <String, int>{};
  for (final outcome in outcomes) {
    final family = patternFamilyIdForOutcome(outcome);
    if (family == null) {
      continue;
    }
    counts[family] = (counts[family] ?? 0) + 1;
  }
  for (final reminder in reminders) {
    final family = patternFamilyIdForReminder(reminder);
    if (family == null) {
      continue;
    }
    counts[family] = (counts[family] ?? 0) + 1;
  }

  String? bestFamily;
  var bestCount = 0;
  for (final family in [
    patternHintFamilyVent,
    patternHintFamilyDrainFilter,
    patternHintFamilyCoils,
  ]) {
    final count = counts[family] ?? 0;
    if (count > bestCount) {
      bestFamily = family;
      bestCount = count;
    }
  }
  if (bestFamily == null || bestCount < minOccurrences) {
    return null;
  }
  if (dismissedFamilyIds.contains(bestFamily)) {
    return null;
  }
  return PatternHint(
    familyId: bestFamily,
    occurrenceCount: bestCount,
    body: patternHintBody(familyId: bestFamily),
  );
}

String patternHintBody({
  required String familyId,
}) {
  final focus = switch (familyId) {
    patternHintFamilyVent =>
      'vent or lint-path work more than once. Checking the vent path on a '
          'regular schedule may help.',
    patternHintFamilyDrainFilter =>
      'drain-filter or drain-path work more than once. Checking the accessible '
          'filter on a regular schedule may help.',
    patternHintFamilyCoils =>
      'coil or grille cleaning more than once. Dusting accessible coils on a '
          'regular schedule may help.',
    _ =>
      'the same kind of repair more than once. A regular check of that area '
          'may help.',
  };
  return 'Based on your household history — not a guess. '
      'This appliance has had $focus';
}

String patternHintDismissKey(String applianceId, String familyId) {
  return '$applianceId::$familyId';
}

bool _looksLikeVent(String blob) {
  if (blob.contains('every load') && blob.contains('lint filter')) {
    return false;
  }
  return blob.contains('vent') ||
      blob.contains('exhaust') ||
      blob.contains('lint pathway') ||
      blob.contains('lint system') ||
      blob.contains('lint-path');
}

bool _looksLikeDrainFilter(String blob) {
  return blob.contains('drain filter') ||
      blob.contains('coin trap') ||
      blob.contains('tub filter') ||
      blob.contains('pump trap');
}

bool _looksLikeCoils(String blob) {
  return blob.contains('coil') || blob.contains('grille');
}

bool _hasExplicitUnclassifiedCause(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return false;
  }
  return trimmed != 'No primary hypothesis was selected.';
}
