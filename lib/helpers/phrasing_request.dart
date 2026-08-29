import 'dart:convert';

import '../models/appliance.dart';
import '../models/inspect_step.dart';
import '../models/repair_comfort_profile.dart';
import 'user_facing_error.dart';

/// Testers default ON. Groq changes how we talk, not what we conclude.
const bool kGroqPhrasingEnabledDefault = true;

const String kGroqPhrasingModel = 'llama-3.1-8b-instant';

const String kGroqChatCompletionsUrl =
    'https://api.groq.com/openai/v1/chat/completions';

/// Banned tokens Groq must not introduce.
const List<String> kGroqPhrasingBanned = [
  'gas_train',
  'live_voltage',
  'sealed',
];

/// Confirm ≠ Fixed packaged source of truth.
///
/// Not shipped on thermal-fuse today (closest: “Confirming no warmth is not
/// a completed repair.”). Groq may rephrase; must not flip allowResolved
/// or offer Fixed.
const String kConfirmNotFixedPackaged = UserFacingCopy.confirmNotFixedPackaged;

const String kSpeakHumanHeading = 'Speak Human';
const String kSpeakHumanMostLikelyLabel = 'Most likely';
const String kSpeakHumanWhyLabel = 'Why';
const String kSpeakHumanSawLabel = 'What you saw';
const String kSpeakHumanNextLabel = 'Next step';
const String kResumeKnewLead = 'Last time we knew…';
const String kProHandoffSpokenHeading = 'Read this to a technician';

/// Packaged Other / describe type-in. Groq may swap display only.
const String kPackagedDescribeDialogTitle = 'What do you notice?';
const String kPackagedDescribeDialogHint =
    'e.g. no heat, won’t start, loud squeal';
const String kPackagedDescribeDialogLabel = 'Describe what you see or hear';

/// GOLDEN chrome — Groq must not paraphrase these labels or buttons.
const List<String> kGoldenChromeFrozenLabels = [
  "I'll repair",
  'Call a pro',
  'Most likely',
  'Current question',
  'Why ask this?',
  'Continue repair',
  'Start repair',
  inspectMatchesOkChip,
  inspectDoesntMatchChip,
];

/// Seven ON hooks. Inputs are engine ids / packaged strings only.
enum PhrasingSlot {
  questionCard,
  safetyStop,
  proHandoff,
  diagnosisSummary,
  confirmNotFixed,
  resume,
  skillComfort,
}

/// Compatibility name used by session wiring. Same seven slots.
typedef GroqPhrasingHook = PhrasingSlot;

/// Structured request. Small context — not the knowledge bible.
///
/// [evidenceNeeded] and [options] are engine ids only. Groq never invents
/// a fourth option or a new chip id.
class PhrasingRequest {
  const PhrasingRequest({
    required PhrasingSlot hook,
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
    this.packagedDescribeTitle = kPackagedDescribeDialogTitle,
    this.packagedDescribeHint = kPackagedDescribeDialogHint,
    this.allowResolvedWhenConfirmed,
    this.offersFixed = false,
    this.safetyCritical = false,
    this.prefetchOnly = false,
  }) : slot = hook;

  /// Typed slot for one of the seven ON hooks.
  factory PhrasingRequest.questionCard({
    required String family,
    required String energy,
    required String comfort,
    required String evidenceNeeded,
    required List<String> options,
    required String lastObs,
    required String whyEngine,
    required String packagedTitle,
    required String packagedWhyOneLine,
    Map<String, String> packagedOptionLabels = const {},
    bool prefetchOnly = false,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.questionCard,
      family: family,
      energy: energy,
      state: 'evidence',
      comfort: comfort,
      evidenceNeeded: evidenceNeeded,
      options: options,
      lastObs: lastObs,
      whyEngine: whyEngine,
      safety: 'none',
      packagedTitle: packagedTitle,
      packagedWhyOneLine: packagedWhyOneLine,
      packagedOptionLabels: packagedOptionLabels,
      prefetchOnly: prefetchOnly,
    );
  }

  factory PhrasingRequest.safetyStop({
    required String family,
    required String energy,
    required String comfort,
    required String lastObs,
    required String packagedTitle,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.safetyStop,
      family: family,
      energy: energy,
      state: 'stop',
      comfort: comfort,
      evidenceNeeded: 'safety-stop',
      options: const [],
      lastObs: lastObs,
      whyEngine: UserFacingCopy.safetyStopOfficial,
      safety: 'stop_unplug',
      packagedTitle: packagedTitle,
      packagedWhyOneLine: UserFacingCopy.safetyStopOfficial,
      safetyCritical: true,
    );
  }

  factory PhrasingRequest.proHandoff({
    required String family,
    required String energy,
    required String comfort,
    required String packagedParagraph,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.proHandoff,
      family: family,
      energy: energy,
      state: 'guidance',
      comfort: comfort,
      evidenceNeeded: 'pro-handoff',
      options: const [],
      lastObs: '',
      whyEngine: packagedParagraph,
      safety: 'none',
      packagedTitle: kProHandoffSpokenHeading,
      packagedWhyOneLine: packagedParagraph,
    );
  }

  factory PhrasingRequest.diagnosisSummary({
    required String family,
    required String energy,
    required String comfort,
    required String evidenceNeeded,
    required String lastObs,
    required String packagedTitle,
    required String packagedWhyOneLine,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.diagnosisSummary,
      family: family,
      energy: energy,
      state: 'guidance',
      comfort: comfort,
      evidenceNeeded: evidenceNeeded,
      options: const [],
      lastObs: lastObs,
      whyEngine: packagedWhyOneLine,
      safety: 'none',
      packagedTitle: packagedTitle,
      packagedWhyOneLine: packagedWhyOneLine,
    );
  }

  factory PhrasingRequest.confirmNotFixed({
    required String family,
    required String energy,
    required String comfort,
    required String evidenceNeeded,
    required String lastObs,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.confirmNotFixed,
      family: family,
      energy: energy,
      state: 'verify',
      comfort: comfort,
      evidenceNeeded: evidenceNeeded,
      options: const [],
      lastObs: lastObs,
      whyEngine: kConfirmNotFixedPackaged,
      safety: 'none',
      packagedTitle: kConfirmNotFixedPackaged,
      packagedWhyOneLine: kConfirmNotFixedPackaged,
      allowResolvedWhenConfirmed: false,
      offersFixed: false,
    );
  }

  factory PhrasingRequest.resume({
    required String family,
    required String energy,
    required String comfort,
    required String lastObs,
    required String packagedLine,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.resume,
      family: family,
      energy: energy,
      state: 'evidence',
      comfort: comfort,
      evidenceNeeded: 'resume',
      options: const [],
      lastObs: lastObs,
      whyEngine: packagedLine,
      safety: 'none',
      packagedTitle: kResumeKnewLead,
      packagedWhyOneLine: packagedLine,
    );
  }

  factory PhrasingRequest.skillComfort({
    required String family,
    required String energy,
    required String comfort,
    required String lastObs,
    required String packagedWhyOneLine,
    bool safetyCritical = true,
  }) {
    return PhrasingRequest(
      hook: PhrasingSlot.skillComfort,
      family: family,
      energy: energy,
      state: 'guidance',
      comfort: comfort,
      evidenceNeeded: 'skill-comfort',
      options: const [],
      lastObs: lastObs,
      whyEngine: packagedWhyOneLine,
      safety: comfort == 'short' ? 'stop_unplug' : 'none',
      packagedTitle: packagedWhyOneLine,
      packagedWhyOneLine: packagedWhyOneLine,
      safetyCritical: safetyCritical,
    );
  }

  final PhrasingSlot slot;

  /// Same as [slot]. Session wiring still says `hook`.
  PhrasingSlot get hook => slot;

  final String family;
  final String energy;
  final String state;
  final String comfort;
  final String evidenceNeeded;
  final List<String> options;
  final String lastObs;
  final String whyEngine;
  final String safety;
  final List<String> banned;
  final String packagedTitle;
  final String packagedWhyOneLine;
  final Map<String, String> packagedOptionLabels;
  final String packagedDescribeTitle;
  final String packagedDescribeHint;
  final bool? allowResolvedWhenConfirmed;
  final bool offersFixed;
  final bool safetyCritical;
  final bool prefetchOnly;

  String get screenKey =>
      '${slot.name}|$evidenceNeeded|$state|$lastObs|$safety|'
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

  PhrasingRequest copyWith({
    PhrasingSlot? hook,
    PhrasingSlot? slot,
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
    String? packagedDescribeTitle,
    String? packagedDescribeHint,
    bool? allowResolvedWhenConfirmed,
    bool? offersFixed,
    bool? safetyCritical,
    bool? prefetchOnly,
  }) {
    return PhrasingRequest(
      hook: hook ?? slot ?? this.slot,
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
      packagedDescribeTitle:
          packagedDescribeTitle ?? this.packagedDescribeTitle,
      packagedDescribeHint: packagedDescribeHint ?? this.packagedDescribeHint,
      allowResolvedWhenConfirmed:
          allowResolvedWhenConfirmed ?? this.allowResolvedWhenConfirmed,
      offersFixed: offersFixed ?? this.offersFixed,
      safetyCritical: safetyCritical ?? this.safetyCritical,
      prefetchOnly: prefetchOnly ?? this.prefetchOnly,
    );
  }
}

/// Session / test name for [PhrasingRequest].
typedef GroqPhrasingRequest = PhrasingRequest;

/// JSON-only Groq payload. Extra keys ignored; extra option ids reject.
///
/// Optional [describeTitle] / [describeHint] may ride the same question-card
/// payload as extra display strings for the Other / describe type-in.
class GroqPhrasingJson {
  const GroqPhrasingJson({
    this.title,
    this.whyOneLine,
    this.optionLabelsOnly = const {},
    this.describeTitle,
    this.describeHint,
  });

  final String? title;
  final String? whyOneLine;
  final Map<String, String> optionLabelsOnly;
  final String? describeTitle;
  final String? describeHint;
}

/// Accepted display overlay. Always starts as packaged.
class GroqPhrasingAccepted {
  const GroqPhrasingAccepted({
    required this.screenKey,
    required this.title,
    required this.whyOneLine,
    required this.optionLabels,
    required this.describeTitle,
    required this.describeHint,
    required this.fromGroq,
  });

  final String screenKey;
  final String title;
  final String whyOneLine;
  final Map<String, String> optionLabels;
  final String describeTitle;
  final String describeHint;
  final bool fromGroq;

  factory GroqPhrasingAccepted.packaged(PhrasingRequest request) {
    return GroqPhrasingAccepted(
      screenKey: request.screenKey,
      title: request.packagedTitle,
      whyOneLine: request.packagedWhyOneLine,
      optionLabels: Map<String, String>.from(request.packagedOptionLabels),
      describeTitle: request.packagedDescribeTitle,
      describeHint: request.packagedDescribeHint,
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

bool groqPhrasingHasApiKey(String? key) {
  return key != null && key.trim().isNotEmpty;
}

bool isGoldenChromeLabel(String text) {
  final trimmed = text.trim();
  for (final label in kGoldenChromeFrozenLabels) {
    if (trimmed == label) {
      return true;
    }
  }
  return false;
}

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
  final describeTitle = decoded['describe_title']?.toString().trim();
  final describeHint = decoded['describe_hint']?.toString().trim();
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
    describeTitle:
        describeTitle == null || describeTitle.isEmpty ? null : describeTitle,
    describeHint:
        describeHint == null || describeHint.isEmpty ? null : describeHint,
  );
}

String groqPhrasingSystemPrompt() {
  return 'You rephrase household repair copy. The engine already decided. '
      'Return JSON only with keys title, why_one_line, option_labels_only. '
      'Optional describe_title and describe_hint may ride that same payload '
      'as extra display strings for the Other / describe type-in. '
      'Use the same option ids — never invent a fourth option or new chip id. '
      'Keep the Other / describe option id. Do not map typed notes onto '
      'another chip. Do not pick the next question. '
      'Do not write how-to. Do not mention gas_train, live_voltage, or sealed. '
      'No confidence numbers. No streaming novels. '
      'Do not paraphrase frozen chrome: I\'ll repair, Call a pro, Most likely, '
      'Current question, Why ask this?, Continue repair, Start repair, '
      'Matches / OK, Doesn\'t match / Not OK. '
      'If safety is stop_unplug, keep unplug, ventilate, and do not keep '
      'running. Confirm is not Fixed unless the engine already allows it.';
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
