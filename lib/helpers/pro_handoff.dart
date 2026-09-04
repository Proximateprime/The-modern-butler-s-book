import '../knowledge_factory/dishwasher_mvp_v01.dart';
import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../knowledge_factory/fridge_mvp_v01.dart';
import '../knowledge_factory/washer_mvp_v01.dart';
import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import 'close_path_phase.dart';
import 'dryer_close_path.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';
import 'groq_phrasing.dart';
import 'guidance_display.dart';
import 'hazard_language.dart';
import 'inspect_steps.dart';
import 'pro_scope.dart';
import 'safety_stop.dart';
import 'session_timeline.dart';

/// Prefix when a hard stop still has a leftover ranking leader.
const String leftoverLeaderPrefix = 'Leftover (not why we stopped):';

/// Household-facing symptom for a fire / smoke hazard Yes.
const String hazardSymptomLabel = 'Burning smell / smoke';

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
  bool leftoverLeader = false,
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
    leftoverLeader
        ? _leftoverLeaderLine(leaderHypothesis)
        : _orDash(leaderHypothesis),
    leftoverLeader
        ? 'This leftover guide match is not why we stopped.'
        : 'This is the leading household-guide match, not a confirmed diagnosis.',
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
  String? whyStopping,
  String? groqParagraph,
}) {
  final packaged = packagedProHandoffSpokenParagraph(
    applianceName: applianceName,
    symptom: symptom,
    observations: observations,
    alreadyTried: alreadyTried,
    leaderHypothesis: leaderHypothesis,
    whyStopping: whyStopping,
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
///
/// [alreadyTried] is what this session recorded — never the unused close-path
/// checklist for the ranking leader. On a safety stop, [whyStopping] is the
/// hazard / Needs a professional reason, not the leader path's verification
/// why. Symptom is the mid-session fire/smoke observation when that is why
/// we stopped. A leftover ranking leader is labeled leftover, not headlined.
String formatProHandoffForSession({
  required List<Evidence> evidence,
  KnowledgePackage? package,
  required String applianceName,
  Appliance? appliance,
  required SessionOutcome outcome,
  DateTime? date,
  List<String> completedGuidanceStepIds = const [],
}) {
  final leaderId = outcome.rankingLeaderFailureModeId;
  final stop = evaluateSafetyStop(
    evidence: evidence,
    primaryFailureModeId: leaderId,
  );
  final path = leaderId == null ? null : closePathForFailureMode(leaderId);
  return formatProHandoffSummary(
    applianceName: applianceName,
    manufacturer: appliance?.manufacturer,
    modelNumber: appliance?.modelNumber,
    date: date ?? outcome.recordedAt,
    symptom: symptomForSession(
      evidence: evidence,
      startSymptom: outcome.startSymptom,
    ),
    observations: sessionTimelineObservations(evidence),
    leaderHypothesis: outcome.rankingLeaderLabel,
    leftoverLeader: stop != null,
    alreadyTried: alreadyTriedFromSession(
      evidence: evidence,
      completedGuidanceStepIds: completedGuidanceStepIds,
      leaderFailureModeId: leaderId,
    ),
    safetyNotes: safetyNotesForLeader(
      package: package,
      failureModeId: leaderId,
    ),
    householdNote: outcome.userNote,
    sessionObjective: outcome.sessionObjective,
    whyStopping: whyStoppingForSession(
      safetyStop: stop,
      path: path,
    ),
    tellTechnician: tellTechnicianForSession(
      safetyStop: stop,
      path: path,
    ),
  );
}

/// Spoken paragraph from a closed session. Display only.
/// Uses the same already-tried list and [whyStopping] as the written handoff.
String formatProHandoffSpokenForSession({
  required List<Evidence> evidence,
  required String applianceName,
  required SessionOutcome outcome,
  String? groqParagraph,
  List<String> completedGuidanceStepIds = const [],
}) {
  final leaderId = outcome.rankingLeaderFailureModeId;
  final stop = evaluateSafetyStop(
    evidence: evidence,
    primaryFailureModeId: leaderId,
  );
  final path = leaderId == null ? null : closePathForFailureMode(leaderId);
  return formatProHandoffSpokenParagraph(
    applianceName: applianceName,
    symptom: symptomForSession(
      evidence: evidence,
      startSymptom: outcome.startSymptom,
    ),
    observations: sessionTimelineObservations(evidence),
    alreadyTried: alreadyTriedFromSession(
      evidence: evidence,
      completedGuidanceStepIds: completedGuidanceStepIds,
      leaderFailureModeId: leaderId,
    ),
    leaderHypothesis: leaderHypothesisForHandoff(
      safetyStop: stop,
      rankingLeaderLabel: outcome.rankingLeaderLabel,
    ),
    whyStopping: whyStoppingForSession(
      safetyStop: stop,
      path: path,
    ),
    groqParagraph: groqParagraph,
  );
}

/// Canned close-path checklist for a failure mode. Display/tests only —
/// never use this as a live session's "already tried" list.
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

/// What this session actually recorded: completed inspect / verification
/// evidence plus Safe Guidance steps the household marked done.
/// Empty when nothing was recorded — the formatter prints "None recorded."
List<String> alreadyTriedFromSession({
  required List<Evidence> evidence,
  List<String> completedGuidanceStepIds = const [],
  String? leaderFailureModeId,
}) {
  return [
    ..._triedInspectAndVerification(evidence),
    ..._triedCompletedGuidance(
      completedGuidanceStepIds: completedGuidanceStepIds,
      leaderFailureModeId: leaderFailureModeId,
    ),
  ];
}

/// Safety-stop reason when the session hard-stopped; otherwise the path why.
String? whyStoppingForSession({
  SafetyStop? safetyStop,
  FailureModeClosePath? path,
}) {
  if (safetyStop != null) {
    return proHandoffWhySafetyStop(safetyStop);
  }
  if (path == null) {
    return null;
  }
  return proHandoffWhy(path);
}

/// Safety-stop bullets do not claim unused DIY checks were done.
List<String>? tellTechnicianForSession({
  SafetyStop? safetyStop,
  FailureModeClosePath? path,
}) {
  if (safetyStop != null) {
    return proHandoffTellTechnicianSafetyStop(safetyStop);
  }
  if (path == null) {
    return null;
  }
  return proHandoffTellTechnician(path);
}

/// Why we stopped on a fire / smoke / professional safety gate.
String proHandoffWhySafetyStop(SafetyStop stop) {
  final reason = stop.reason.trim();
  if (reason.isEmpty) {
    return 'Needs a professional.';
  }
  if (reason.toLowerCase().contains('needs a professional')) {
    return reason;
  }
  return 'Needs a professional. $reason.';
}

List<String> proHandoffTellTechnicianSafetyStop(SafetyStop stop) {
  final reason = stop.reason.trim();
  return [
    if (reason.isEmpty)
      'Stopped for a safety hazard before DIY checks.'
    else
      'Stopped for a safety hazard: $reason.',
    'Share the observations listed above.',
  ];
}

List<String> _triedInspectAndVerification(List<Evidence> evidence) {
  final tried = <String>[];
  final seenTemplates = <String>{};
  for (final item in evidence) {
    final templateId = item.templateId;
    final answer = item.answer?.trim();
    if (answer == null || answer.isEmpty) {
      continue;
    }
    if (isCloseVerificationTemplateId(templateId)) {
      final prompt = item.observation.trim();
      tried.add(
        prompt.isEmpty ? answer : '$prompt: $answer',
      );
      continue;
    }
    if (templateId == null || templateId.isEmpty) {
      continue;
    }
    if (templateId == problemStarterComplaintTemplateId) {
      continue;
    }
    final step = inspectStepForEvidenceTemplate(templateId: templateId);
    if (step == null) {
      continue;
    }
    if (!seenTemplates.add(templateId)) {
      continue;
    }
    tried.add('${step.title}: $answer');
  }
  return tried;
}

List<String> _triedCompletedGuidance({
  required List<String> completedGuidanceStepIds,
  String? leaderFailureModeId,
}) {
  if (completedGuidanceStepIds.isEmpty) {
    return const [];
  }
  if (leaderFailureModeId == null || leaderFailureModeId.trim().isEmpty) {
    return const [];
  }
  final path = closePathForFailureMode(leaderFailureModeId);
  if (path == null) {
    return const [];
  }
  final steps = safeCheckGuidanceSteps(path.safeGuidanceSteps);
  final done = completedGuidanceStepIds.toSet();
  return [
    for (var i = 0; i < steps.length; i++)
      if (done.contains(guidanceStepId(i, steps[i])))
        guidanceForSafeStep(steps[i]).what,
  ];
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

/// Symptom for handoff / memory. On a safety stop, the mid-session fire/smoke
/// observation wins over an empty starter complaint and over a leftover
/// starter chip that is not why we stopped.
String? symptomForSession({
  required List<Evidence> evidence,
  String? startSymptom,
}) {
  final hazard = hazardSymptomFromEvidence(evidence);
  if (hazard != null &&
      evaluateSafetyStop(evidence: evidence) != null) {
    return hazard;
  }
  final stored = startSymptom?.trim();
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }
  return symptomFromEvidence(evidence);
}

/// Leftover ranking leader on a hard stop, or the live leader otherwise.
String? leaderHypothesisForHandoff({
  required SafetyStop? safetyStop,
  String? rankingLeaderLabel,
}) {
  final label = rankingLeaderLabel?.trim();
  if (label == null || label.isEmpty) {
    return null;
  }
  if (safetyStop != null) {
    return '$leftoverLeaderPrefix $label';
  }
  return label;
}

/// Starter complaint, then a fire/smoke hazard Yes, then heat-observed.
String? symptomFromEvidence(List<Evidence> evidence) {
  for (final item in evidence) {
    if (item.templateId != problemStarterComplaintTemplateId &&
        item.templateId != washerComplaintTemplateId &&
        item.templateId != dishwasherComplaintTemplateId &&
        item.templateId != fridgeComplaintTemplateId) {
      continue;
    }
    final answer = item.answer?.trim();
    if (answer != null && answer.isNotEmpty) {
      return answer;
    }
  }
  final hazard = hazardSymptomFromEvidence(evidence);
  if (hazard != null) {
    return hazard;
  }
  for (final item in evidence) {
    if (item.templateId != 'heat-observed') {
      continue;
    }
    final answer = item.answer?.trim().toLowerCase();
    if (answer == 'no warmth') {
      return 'No heat';
    }
    if (answer == 'very hot') {
      return 'Too hot';
    }
  }
  return null;
}

/// Mid-session (or starter-mapped) fire/smoke hazard observation.
String? hazardSymptomFromEvidence(List<Evidence> evidence) {
  for (final item in evidence) {
    if (item.templateId != 'hazard-observation') {
      continue;
    }
    final answer = (item.answer ?? '').trim().toLowerCase();
    if (answer == 'yes' || textSuggestsHazard(item.answer ?? '')) {
      return hazardSymptomLabel;
    }
  }
  return null;
}

String _leftoverLeaderLine(String? leaderHypothesis) {
  final label = leaderHypothesis?.trim();
  if (label == null || label.isEmpty) {
    return '—';
  }
  if (label.toLowerCase().startsWith(leftoverLeaderPrefix.toLowerCase())) {
    return label;
  }
  return '$leftoverLeaderPrefix $label';
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
