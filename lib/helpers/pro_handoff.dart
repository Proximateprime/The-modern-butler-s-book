import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import 'dryer_close_path.dart';
import 'dryer_problem_starter.dart';
import 'groq_phrasing.dart';
import 'pro_scope.dart';
import 'session_timeline.dart';

/// Default beginner-safe reminder when a mode has no specific notes.
const String defaultProHandoffSafetyNotes =
    'Unplug first. Do not do live electrical work. Stop for smoke or a '
    'burning smell.';

/// Plain-language technician handoff. Display/share only — not a diagnosis.
String formatProHandoffSummary({
  required String applianceName,
  String? manufacturer,
  String? modelNumber,
  required DateTime? date,
  required String? symptom,
  required List<SessionTimelineObservation> observations,
  required String? leaderHypothesis,
  required List<String> alreadyTried,
  required String? safetyNotes,
  String? householdNote,
  SessionObjective? sessionObjective,
  String? whyStopping,
  List<String>? tellTechnician,
}) {
  final brandModel = _brandModel(manufacturer, modelNumber);
  final noticed = observations
      .map((item) => '• ${item.prompt}: ${item.answer}')
      .toList();
  final tried = alreadyTried
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final safety = (safetyNotes ?? '').trim().isEmpty
      ? defaultProHandoffSafetyNotes
      : safetyNotes!.trim();
  final note = householdNote?.trim();
  final lines = <String>[
    'The Modern Butler’s Book — Technician handoff',
    '',
    'This is a household summary of what was observed and tried. '
        'It is not a diagnosis or a quote.',
    '',
    'Date: ${_formatDate(date)}',
    'Appliance: ${_orDash(applianceName)}',
    'Brand / model: $brandModel',
    'Symptom: ${_orDash(symptom)}',
    if (sessionObjective != null) ...[
      'Session goal: ${sessionObjectiveChipLabel(sessionObjective)}',
    ],
    if (whyStopping != null && whyStopping.trim().isNotEmpty) ...[
      '',
      'Why we’re stopping',
      whyStopping.trim(),
    ],
    if (tellTechnician != null && tellTechnician.isNotEmpty) ...[
      '',
      'What to tell a technician',
      for (final item in tellTechnician) '• ${item.trim()}',
    ],
    '',
    'What we noticed',
    if (noticed.isEmpty) '• None recorded' else ...noticed,
    '',
    'Leader hypothesis',
    _orDash(leaderHypothesis),
    'This is the leading household-guide match, not a confirmed diagnosis.',
    '',
    'What was already tried',
    if (tried.isEmpty) '• None recorded' else
      for (final step in tried) '• $step',
    '',
    'Safety notes',
    safety,
    if (note != null && note.isNotEmpty) ...[
      '',
      'Household note',
      note,
    ],
  ];
  return lines.join('\n');
}

/// One paragraph they can read to a tech. Observed / not done — not a diagnosis.
/// Groq may rephrase; it must not invent a diagnosis.
String formatProHandoffSpokenParagraph({
  required String applianceName,
  String? symptom,
  required List<SessionTimelineObservation> observations,
  required List<String> alreadyTried,
  String? leaderHypothesis,
  String? groqParagraph,
}) {
  final packaged = packagedProHandoffSpokenParagraph(
    applianceName: applianceName,
    symptom: symptom,
    observations: observations,
    alreadyTried: alreadyTried,
    leaderHypothesis: leaderHypothesis,
  );
  final overlay = groqParagraph?.trim() ?? '';
  if (overlay.isEmpty) {
    return packaged;
  }
  final accepted = acceptGroqPhrasing(
    request: GroqPhrasingRequest(
      hook: GroqPhrasingHook.proHandoff,
      family: 'dryer',
      energy: 'unknown',
      state: 'guidance',
      comfort: 'normal',
      evidenceNeeded: 'pro-handoff',
      options: const [],
      lastObs: '',
      whyEngine: packaged,
      safety: 'none',
      packagedTitle: kProHandoffSpokenHeading,
      packagedWhyOneLine: packaged,
    ),
    parsed: GroqPhrasingJson(whyOneLine: overlay),
  );
  return accepted?.whyOneLine ?? packaged;
}

/// Builds a handoff from a closed session's evidence and outcome.
String formatProHandoffForSession({
  required List<Evidence> evidence,
  KnowledgePackage? package,
  required String applianceName,
  Appliance? appliance,
  required SessionOutcome outcome,
  DateTime? date,
}) {
  final leaderId = outcome.rankingLeaderFailureModeId;
  final path =
      leaderId == null ? null : closePathForFailureMode(leaderId);
  return formatProHandoffSummary(
    applianceName: applianceName,
    manufacturer: appliance?.manufacturer,
    modelNumber: appliance?.modelNumber,
    date: date ?? outcome.recordedAt,
    symptom: outcome.startSymptom ?? _symptomFromEvidence(evidence),
    observations: sessionTimelineObservations(evidence),
    leaderHypothesis: outcome.rankingLeaderLabel,
    alreadyTried: alreadyTriedStepsForLeader(leaderId),
    safetyNotes: safetyNotesForLeader(
      package: package,
      failureModeId: leaderId,
    ),
    householdNote: outcome.userNote,
    sessionObjective: outcome.sessionObjective,
    whyStopping: path == null ? null : proHandoffWhy(path),
    tellTechnician: path == null ? null : proHandoffTellTechnician(path),
  );
}

/// Spoken paragraph from a closed session. Display only.
String formatProHandoffSpokenForSession({
  required List<Evidence> evidence,
  required String applianceName,
  required SessionOutcome outcome,
  String? groqParagraph,
}) {
  final leaderId = outcome.rankingLeaderFailureModeId;
  return formatProHandoffSpokenParagraph(
    applianceName: applianceName,
    symptom: outcome.startSymptom ?? _symptomFromEvidence(evidence),
    observations: sessionTimelineObservations(evidence),
    alreadyTried: alreadyTriedStepsForLeader(leaderId),
    leaderHypothesis: outcome.rankingLeaderLabel,
    groqParagraph: groqParagraph,
  );
}

List<String> alreadyTriedStepsForLeader(String? failureModeId) {
  if (failureModeId == null || failureModeId.trim().isEmpty) {
    return const [];
  }
  final steps = closePathForFailureMode(failureModeId)?.safeGuidanceSteps;
  if (steps == null) {
    return const [];
  }
  return safeCheckGuidanceSteps(steps);
}

String? safetyNotesForLeader({
  KnowledgePackage? package,
  String? failureModeId,
}) {
  final fromAuthoring = FailureModeAuthoringRegistry.safetyNotesFor(
    failureModeId,
  );
  if (fromAuthoring != null) {
    return fromAuthoring;
  }
  if (package == null || failureModeId == null) {
    return null;
  }
  for (final mode in package.failureModes) {
    if (mode.id == failureModeId) {
      final notes = mode.safetyNotes.trim();
      return notes.isEmpty ? null : notes;
    }
  }
  return null;
}

String? _symptomFromEvidence(List<Evidence> evidence) {
  for (final item in evidence) {
    if (item.templateId != problemStarterComplaintTemplateId) {
      continue;
    }
    final answer = item.answer?.trim();
    if (answer != null && answer.isNotEmpty) {
      return answer;
    }
  }
  return null;
}

String _brandModel(String? manufacturer, String? modelNumber) {
  final brand = manufacturer?.trim() ?? '';
  final model = modelNumber?.trim() ?? '';
  if (brand.isEmpty && model.isEmpty) {
    return '—';
  }
  if (brand.isEmpty) {
    return model;
  }
  if (model.isEmpty) {
    return brand;
  }
  return '$brand $model';
}

String _orDash(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '—';
  }
  return trimmed;
}

String _formatDate(DateTime? time) {
  if (time == null) {
    return '—';
  }
  final local = time.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
