import 'dart:convert';

import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/repair_comfort_profile.dart';
import '../models/session_ui_resume_state.dart';
import 'close_path_phase.dart';
import 'confidence_display.dart';
import 'forbidden_guidance.dart';
import 'session_timeline.dart';
import 'user_facing_error.dart';

/// Testers default ON. Groq changes how we talk, not what we conclude.
const bool kGroqPhrasingEnabledDefault = true;

/// Groq chat model. Communication only — never ranking or eligibility.
const String kGroqPhrasingModel = 'llama-3.1-8b-instant';

const String kGroqChatCompletionsUrl =
    'https://api.groq.com/openai/v1/chat/completions';

/// Banned tokens Groq must not introduce. Validator rejects the whole swap.
const List<String> kGroqPhrasingBanned = [
  'gas_train',
  'live_voltage',
  'sealed',
];

/// Exact Confirm ≠ Fixed packaged line (engine eligibility unchanged).
const String kConfirmNotFixedPackaged =
    'We confirmed the part is open. The dryer still isn’t fixed until '
    'heat returns.';

const String kSpeakHumanHeading = 'Speak Human';
const String kSpeakHumanMostLikelyLabel = 'Most likely';
const String kSpeakHumanWhyLabel = 'Why';
const String kSpeakHumanSawLabel = 'What you saw';
const String kSpeakHumanNextLabel = 'Next step';
const String kResumeKnewLead = 'Last time we knew…';
const String kProHandoffSpokenHeading = 'Read this to a technician';

/// Seven ON hooks. OFF surfaces must not be attached.
enum GroqPhrasingHook {
  questionCard,
  safetyStop,
  proHandoff,
  diagnosisSummary,
  confirmNotFixed,
  resume,
  skillComfort,
}

/// Structured request. Small context — not the knowledge bible.
class GroqPhrasingRequest {
  const GroqPhrasingRequest({
    required this.hook,
    required this.family,
    required this.energy,
    required this.state,
    required this.comfort,
    required this.evidenceNeeded,
    required this.options,
    required this.lastObs,
    required this.whyEngine,
    required this.safety,
    this.banned = kGroqPhrasingBanned,
    required this.packagedTitle,
    required this.packagedWhyOneLine,
    this.packagedOptionLabels = const {},
    this.allowResolvedWhenConfirmed,
    this.offersFixed = false,
    this.safetyCritical = false,
    this.prefetchOnly = false,
  });

  final GroqPhrasingHook hook;

  /// Appliance / complaint family (e.g. dryer, no-heat).
  final String family;

  /// `gas` | `electric` | `unknown`
  final String energy;

  /// `evidence` | `guidance` | `verify` | `stop`
  final String state;

  /// `cautious` | `normal` | `short`
  final String comfort;

  /// Already-chosen template / surface id. Never invented by Groq.
  final String evidenceNeeded;

  /// Existing option / chip ids only.
  final List<String> options;

  final String lastObs;
  final String whyEngine;

  /// `none` | `stop_unplug`
  final String safety;

  final List<String> banned;

  final String packagedTitle;
  final String packagedWhyOneLine;
  final Map<String, String> packagedOptionLabels;

  /// Engine flag. Groq must not flip this or offer Fixed when false.
  final bool? allowResolvedWhenConfirmed;
  final bool offersFixed;

  /// Shorter comfort still keeps unplug / never / do not on these.
  final bool safetyCritical;

  /// Prefetch of the already-chosen next template id only.
  final bool prefetchOnly;

  String get screenKey =>
      '${hook.name}|$evidenceNeeded|$state|$lastObs|$safety|'
      '${allowResolvedWhenConfirmed ?? 'n'}|$prefetchOnly';

  Map<String, dynamic> toModelJson() {
    return {
      'family': family,
      'energy': energy,
      'state': state,
      'comfort': comfort,
      'evidence_needed': evidenceNeeded,
      'options': options,
      'last_obs': lastObs,
      'why_engine': whyEngine,
      'safety': safety,
      'banned': banned,
    };
  }

  GroqPhrasingRequest copyWith({
    GroqPhrasingHook? hook,
    String? family,
    String? energy,
    String? state,
    String? comfort,
    String? evidenceNeeded,
    List<String>? options,
    String? lastObs,
    String? whyEngine,
    String? safety,
    List<String>? banned,
    String? packagedTitle,
    String? packagedWhyOneLine,
    Map<String, String>? packagedOptionLabels,
    bool? allowResolvedWhenConfirmed,
    bool? offersFixed,
    bool? safetyCritical,
    bool? prefetchOnly,
  }) {
    return GroqPhrasingRequest(
      hook: hook ?? this.hook,
      family: family ?? this.family,
      energy: energy ?? this.energy,
      state: state ?? this.state,
      comfort: comfort ?? this.comfort,
      evidenceNeeded: evidenceNeeded ?? this.evidenceNeeded,
      options: options ?? this.options,
      lastObs: lastObs ?? this.lastObs,
      whyEngine: whyEngine ?? this.whyEngine,
      safety: safety ?? this.safety,
      banned: banned ?? this.banned,
      packagedTitle: packagedTitle ?? this.packagedTitle,
      packagedWhyOneLine: packagedWhyOneLine ?? this.packagedWhyOneLine,
      packagedOptionLabels: packagedOptionLabels ?? this.packagedOptionLabels,
      allowResolvedWhenConfirmed:
          allowResolvedWhenConfirmed ?? this.allowResolvedWhenConfirmed,
      offersFixed: offersFixed ?? this.offersFixed,
      safetyCritical: safetyCritical ?? this.safetyCritical,
      prefetchOnly: prefetchOnly ?? this.prefetchOnly,
    );
  }
}

/// JSON-only Groq payload. Extra keys are ignored; extra option ids reject.
class GroqPhrasingJson {
  const GroqPhrasingJson({
    this.title,
    this.whyOneLine,
    this.optionLabelsOnly = const {},
  });

  final String? title;
  final String? whyOneLine;
  final Map<String, String> optionLabelsOnly;

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (whyOneLine != null) 'why_one_line': whyOneLine,
      if (optionLabelsOnly.isNotEmpty) 'option_labels_only': optionLabelsOnly,
    };
  }
}

/// Accepted display overlay. Always starts as packaged; Groq may swap fields.
class GroqPhrasingAccepted {
  const GroqPhrasingAccepted({
    required this.screenKey,
    required this.title,
    required this.whyOneLine,
    required this.optionLabels,
    required this.fromGroq,
  });

  final String screenKey;
  final String title;
  final String whyOneLine;
  final Map<String, String> optionLabels;
  final bool fromGroq;

  factory GroqPhrasingAccepted.packaged(GroqPhrasingRequest request) {
    return GroqPhrasingAccepted(
      screenKey: request.screenKey,
      title: request.packagedTitle,
      whyOneLine: request.packagedWhyOneLine,
      optionLabels: Map<String, String>.from(request.packagedOptionLabels),
      fromGroq: false,
    );
  }

  String displayLabelFor(String optionId) {
    return optionLabels[optionId] ?? optionId;
  }
}

/// Speak Human diagnosis card. Ranked FMs already exist — display only.
class SpeakHumanDiagnosis {
  const SpeakHumanDiagnosis({
    required this.mostLikely,
    required this.why,
    required this.whatYouSaw,
    required this.nextStep,
    this.confidenceBand,
  });

  final String mostLikely;
  final String why;
  final String whatYouSaw;
  final String nextStep;
  final String? confidenceBand;
}

/// Maps household comfort onto the Groq token. Does not change the profile.
String groqComfortToken(RepairComfortLevel level) {
  return switch (level) {
    RepairComfortLevel.moreDetail => 'cautious',
    RepairComfortLevel.standard => 'normal',
    RepairComfortLevel.shorter => 'short',
  };
}

String groqEnergyToken(ApplianceEnergySource source) {
  return switch (source) {
    ApplianceEnergySource.gas => 'gas',
    ApplianceEnergySource.electric => 'electric',
    ApplianceEnergySource.unknown => 'unknown',
  };
}

String groqEnergyTokenFromAppliance(Appliance appliance) {
  return groqEnergyToken(appliance.energySource);
}

/// Parse Groq message content. Missing / invalid JSON → null (packaged).
GroqPhrasingJson? parseGroqPhrasingJson(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final decoded = _decodeJsonObject(trimmed);
  if (decoded == null) {
    return null;
  }
  final title = decoded['title']?.toString().trim();
  final why = decoded['why_one_line']?.toString().trim();
  final rawOptions = decoded['option_labels_only'];
  final options = <String, String>{};
  if (rawOptions is Map) {
    for (final entry in rawOptions.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value?.toString().trim() ?? '';
      if (key.isNotEmpty && value.isNotEmpty) {
        options[key] = value;
      }
    }
  }
  if ((title == null || title.isEmpty) &&
      (why == null || why.isEmpty) &&
      options.isEmpty) {
    return null;
  }
  return GroqPhrasingJson(
    title: title == null || title.isEmpty ? null : title,
    whyOneLine: why == null || why.isEmpty ? null : why,
    optionLabelsOnly: options,
  );
}

/// Hard gates. Any failure → caller keeps packaged. Never invents a 4th option.
GroqPhrasingAccepted? acceptGroqPhrasing({
  required GroqPhrasingRequest request,
  required GroqPhrasingJson? parsed,
}) {
  if (parsed == null) {
    return null;
  }
  final title = parsed.title?.trim();
  final why = parsed.whyOneLine?.trim();
  final labels = parsed.optionLabelsOnly;

  if (labels.isNotEmpty) {
    final allowed = request.options.toSet();
    for (final id in labels.keys) {
      if (!allowed.contains(id)) {
        return null;
      }
    }
  }

  final fields = <String>[
    if (title != null && title.isNotEmpty) title,
    if (why != null && why.isNotEmpty) why,
    ...labels.values,
  ];
  for (final field in fields) {
    if (_containsBanned(field, request.banned)) {
      return null;
    }
    if (_failsHouseholdHowToGate(field)) {
      return null;
    }
    if (standingLooksLikePercentage(field) || _containsConfidenceNumber(field)) {
      return null;
    }
  }

  if (request.hook == GroqPhrasingHook.questionCard) {
    if (title != null && _isQuestionSlotNovel(title)) {
      return null;
    }
  }

  if (request.hook == GroqPhrasingHook.safetyStop ||
      request.safety == 'stop_unplug') {
    final shortened = why ?? title ?? '';
    if (!_hasUnplugVentilateDontKeepRunning(shortened)) {
      return null;
    }
  }

  if (request.hook == GroqPhrasingHook.confirmNotFixed ||
      request.allowResolvedWhenConfirmed == false ||
      !request.offersFixed) {
    for (final field in fields) {
      if (_offersFixedWhenNotEligible(field, request)) {
        return null;
      }
    }
  }

  if ((request.comfort == 'short' ||
          request.hook == GroqPhrasingHook.skillComfort) &&
      request.safetyCritical) {
    for (final field in fields) {
      if (!_keepsShorterSafetyWords(field)) {
        return null;
      }
    }
    if (fields.isEmpty) {
      return null;
    }
  }

  final packaged = GroqPhrasingAccepted.packaged(request);
  return GroqPhrasingAccepted(
    screenKey: request.screenKey,
    title: (title != null && title.isNotEmpty) ? title : packaged.title,
    whyOneLine:
        (why != null && why.isNotEmpty) ? why : packaged.whyOneLine,
    optionLabels: {
      ...packaged.optionLabels,
      ...labels,
    },
    fromGroq: true,
  );
}

bool groqPhrasingHasApiKey(String? key) {
  return key != null && key.trim().isNotEmpty;
}

/// Safety-stop shorten gate: unplug, ventilate, and don’t keep running.
bool safetyStopShortenAcceptable(String candidate) {
  if (!_hasUnplugVentilateDontKeepRunning(candidate)) {
    return false;
  }
  if (_failsHouseholdHowToGate(candidate)) {
    return false;
  }
  if (_containsBanned(candidate, kGroqPhrasingBanned)) {
    return false;
  }
  return true;
}

/// Official body, optionally Groq-shortened when gates pass.
String phrasedSafetyStopOfficial({String? groqShortened}) {
  final candidate = groqShortened?.trim() ?? '';
  if (candidate.isNotEmpty && safetyStopShortenAcceptable(candidate)) {
    return candidate;
  }
  return UserFacingCopy.safetyStopOfficial;
}

String packagedConfirmNotFixedLine({
  required bool allowResolvedWhenConfirmed,
  required bool verificationSupported,
}) {
  if (verificationSupported && !allowResolvedWhenConfirmed) {
    return kConfirmNotFixedPackaged;
  }
  return '';
}

/// Confirm ≠ Fixed phrasing cannot flip eligibility.
bool confirmNotFixedPhrasingFlipsEligibility({
  required bool allowResolvedWhenConfirmed,
  required String phrasing,
}) {
  if (allowResolvedWhenConfirmed) {
    return false;
  }
  return _claimsFixedAvailable(phrasing);
}

SpeakHumanDiagnosis packagedSpeakHuman({
  required String? primaryLabel,
  required String? why,
  required List<SessionTimelineObservation> observations,
  required String nextStep,
  String? confidenceBand,
}) {
  final saw = observations.isEmpty
      ? 'No observations recorded yet.'
      : observations
          .map((item) => '${item.prompt}: ${item.answer}')
          .join('; ');
  return SpeakHumanDiagnosis(
    mostLikely: (primaryLabel ?? '').trim().isEmpty
        ? 'Not enough yet for a most likely cause'
        : primaryLabel!.trim(),
    why: (why ?? '').trim().isEmpty
        ? 'Based on your answers — not a certainty or a percentage.'
        : why!.trim(),
    whatYouSaw: saw,
    nextStep: nextStep.trim().isEmpty
        ? 'Continue the path the engine already chose.'
        : nextStep.trim(),
    confidenceBand: _bandOnly(confidenceBand),
  );
}

SpeakHumanDiagnosis applySpeakHumanOverlay({
  required SpeakHumanDiagnosis packaged,
  GroqPhrasingAccepted? overlay,
}) {
  if (overlay == null || !overlay.fromGroq) {
    return packaged;
  }
  final title = overlay.title.trim();
  final why = overlay.whyOneLine.trim();
  return SpeakHumanDiagnosis(
    mostLikely: title.isEmpty ? packaged.mostLikely : title,
    why: why.isEmpty ? packaged.why : why,
    whatYouSaw: packaged.whatYouSaw,
    nextStep: packaged.nextStep,
    confidenceBand: packaged.confidenceBand,
  );
}

String packagedResumeKnewLine({
  required SessionUiResumeState state,
  required List<Evidence> evidence,
}) {
  final last = evidence.isEmpty ? null : evidence.last;
  final lastBit = last == null
      ? 'no observations yet'
      : '${last.observation}: ${last.answer ?? 'recorded'}';
  final where = state.pendingObservationTemplateId != null
      ? 'we were on a question'
      : state.pendingCloseVerificationFailureModeId != null
          ? 'we were verifying'
          : state.closePathPhase != ClosePathPhase.conclusion
              ? 'we were in ${state.closePathPhase.name}'
              : 'we had a most likely cause';
  return '$kResumeKnewLead $where. $lastBit.';
}

/// One paragraph a household can read to a tech. Not a diagnosis.
String packagedProHandoffSpokenParagraph({
  required String applianceName,
  String? symptom,
  required List<SessionTimelineObservation> observations,
  required List<String> alreadyTried,
  String? leaderHypothesis,
}) {
  final noticed = observations.isEmpty
      ? 'nothing recorded yet'
      : observations
          .map((item) => '${item.prompt}: ${item.answer}')
          .join('; ');
  final tried = alreadyTried.isEmpty
      ? 'none recorded'
      : alreadyTried.join('; ');
  final leader = (leaderHypothesis ?? '').trim().isEmpty
      ? 'none'
      : leaderHypothesis!.trim();
  final what = (symptom ?? '').trim().isEmpty ? 'not recorded' : symptom!.trim();
  return 'Please look at this ${applianceName.trim()}. Symptom: $what. '
      'Observed: $noticed. Already tried or not done: $tried. '
      'Leading household-guide match: $leader — not a diagnosis.';
}

String groqPhrasingSystemPrompt() {
  return 'You rephrase household repair copy. The engine already decided. '
      'Return JSON only with keys title, why_one_line, option_labels_only. '
      'Use the same option ids — never invent a fourth option or new chip id. '
      'Do not write how-to. Do not mention gas_train, live_voltage, or sealed. '
      'No confidence numbers. No streaming novels. '
      'If safety is stop_unplug, keep unplug, ventilate, and do not keep '
      'running. Confirm is not Fixed unless the engine already allows it.';
}

bool _hasUnplugVentilateDontKeepRunning(String text) {
  final lower = text.toLowerCase();
  final unplug = lower.contains('unplug');
  final ventilate = lower.contains('ventilate');
  final dontRun = lower.contains('do not keep running') ||
      lower.contains("don't keep running") ||
      lower.contains('don’t keep running');
  return unplug && ventilate && dontRun;
}

bool _keepsShorterSafetyWords(String text) {
  final lower = text.toLowerCase();
  return lower.contains('unplug') &&
      (lower.contains('never') ||
          lower.contains('do not') ||
          lower.contains("don't") ||
          lower.contains('don’t'));
}

bool _containsBanned(String text, List<String> banned) {
  final lower = text.toLowerCase();
  for (final token in banned) {
    final needle = token.toLowerCase();
    if (lower.contains(needle)) {
      return true;
    }
    final spaced = needle.replaceAll('_', ' ');
    if (spaced != needle && lower.contains(spaced)) {
      return true;
    }
  }
  return false;
}

bool _failsHouseholdHowToGate(String text) {
  if (isAlwaysForbiddenInstruction(text)) {
    return true;
  }
  final visible = visibleHouseholdHowTo(text, expertMode: false);
  if (visible.isEmpty && text.trim().isNotEmpty && !isSafetyLimitLanguage(text)) {
    return true;
  }
  return false;
}

bool _isQuestionSlotNovel(String title) {
  if (title.length > 180) {
    return true;
  }
  final sentences = title
      .split(RegExp(r'[.!?]+'))
      .where((part) => part.trim().isNotEmpty)
      .length;
  return sentences > 2;
}

bool _containsConfidenceNumber(String text) {
  return RegExp(r'\b\d{1,3}\s*%').hasMatch(text) ||
      RegExp(r'\b\d{2,3}\s*(confidence|percent|likely)\b', caseSensitive: false)
          .hasMatch(text);
}

bool _offersFixedWhenNotEligible(String text, GroqPhrasingRequest request) {
  if (request.allowResolvedWhenConfirmed == true && request.offersFixed) {
    return false;
  }
  if (request.allowResolvedWhenConfirmed == true) {
    return false;
  }
  return _claimsFixedAvailable(text);
}

bool _claimsFixedAvailable(String text) {
  final lower = text.toLowerCase();
  if (lower.contains("isn't fixed") ||
      lower.contains('isn’t fixed') ||
      lower.contains('not fixed') ||
      lower.contains('still isn’t fixed') ||
      lower.contains("still isn't fixed")) {
    return false;
  }
  return lower.contains('mark this fixed') ||
      lower.contains('record fixed') ||
      lower.contains('you can mark fixed') ||
      lower.contains('offer fixed') ||
      lower.contains('ready to resolve') ||
      RegExp(r'\byou can record fixed\b').hasMatch(lower) ||
      (lower.contains('fixed') &&
          (lower.contains('you can') ||
              lower.contains('now mark') ||
              lower.contains('tap fixed')));
}

String? _bandOnly(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  if (standingLooksLikePercentage(trimmed) ||
      _containsConfidenceNumber(trimmed)) {
    return null;
  }
  return trimmed;
}

Map<String, dynamic>? _decodeJsonObject(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text.replaceFirst(RegExp(r'^```(?:json)?'), '').trim();
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3).trim();
    }
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    return null;
  }
  return null;
}
