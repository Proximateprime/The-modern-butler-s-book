import '../models/evidence.dart';
import '../models/session_ui_resume_state.dart';
import '../services/groq_phrasing_client.dart';
import 'close_path_phase.dart';
import 'confidence_display.dart';
import 'phrasing_request.dart';
import 'phrasing_safety_gate.dart';
import 'session_timeline.dart';

/// Display strings only. Never ranking, safety decisions, or eligibility.
///
/// Testers default ON with hard gates. One Groq call per screen change —
/// not a call per letter, and not when the Other / describe type-in opens.
/// Prefetch is the already-chosen next template id only.
///
/// The Edge Function is not an escape hatch. Every network JSON still
/// goes through [acceptGroqPhrasing] / [visibleHouseholdHowTo] before paint.
class GroqPhrasingService {
  GroqPhrasingService({
    GroqPhrasingClient? client,
    this.enabled = kGroqPhrasingEnabledDefault,
    bool Function()? isOnline,
  }) : client = client ?? GroqPhrasingRuntimeClient(),
       _isOnline = isOnline ?? (() => true);

  final GroqPhrasingClient client;
  final bool enabled;
  final bool Function() _isOnline;

  final Map<String, GroqPhrasingAccepted> _cache = {};
  String? _lastScreenKey;
  final List<String> _requestedEvidenceIds = [];

  bool get shouldCallNetwork =>
      enabled && client.hasApiKey && _isOnline();

  List<String> get requestedEvidenceIds =>
      List<String>.unmodifiable(_requestedEvidenceIds);

  int get liveNetworkCalls {
    final fake = client;
    if (fake is FakeGroqPhrasingClient) {
      return fake.liveNetworkCalls;
    }
    if (fake is FakePhraseFunctionClient) {
      return fake.liveNetworkCalls;
    }
    return 0;
  }

  void resetForTests() {
    _cache.clear();
    _lastScreenKey = null;
    _requestedEvidenceIds.clear();
  }

  /// Packaged first. Groq swap only when the safety gate accepts.
  Future<GroqPhrasingAccepted> phrase(PhrasingRequest request) async {
    final packaged = GroqPhrasingAccepted.packaged(request);
    if (!shouldCallNetwork) {
      return packaged;
    }
    final cached = _cache[request.screenKey];
    if (cached != null && _lastScreenKey == request.screenKey) {
      return cached;
    }
    if (_lastScreenKey == request.screenKey && cached != null) {
      return cached;
    }

    if (!request.prefetchOnly) {
      _lastScreenKey = request.screenKey;
    }
    _requestedEvidenceIds.add(request.evidenceNeeded);

    GroqPhrasingJson? parsed;
    try {
      parsed = await client.complete(request);
    } catch (_) {
      return packaged;
    }
    // Hard gate: never paint function/Groq JSON without the attach-map
    // safety gate. Missing parse / validator fail → packaged.
    final accepted = acceptGroqPhrasing(request: request, parsed: parsed);
    final result = accepted ?? packaged;
    _cache[request.screenKey] = result;
    return result;
  }

  /// Wording for the already-chosen next template id only.
  Future<GroqPhrasingAccepted> prefetchAlreadyChosenNext(
    PhrasingRequest request,
  ) {
    return phrase(request.copyWith(prefetchOnly: true));
  }
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

/// Household-only “where we left off” — never raw phase names (`tools`,
/// `guidance`, and the rest of [ClosePathPhase]).
String resumeWhereWeLeftOff(SessionUiResumeState state) {
  if (state.pendingObservationTemplateId != null) {
    return 'we were on a question';
  }
  if (state.pendingCloseVerificationFailureModeId != null) {
    return 'we were verifying';
  }
  return switch (state.closePathPhase) {
    ClosePathPhase.conclusion => 'we had a most likely cause',
    ClosePathPhase.decision => 'we were choosing what to do next',
    ClosePathPhase.parts => 'we were looking at parts',
    ClosePathPhase.tools => 'we were checking what you already have',
    ClosePathPhase.inspect => 'we were looking at the easy checks',
    ClosePathPhase.guidance => 'we were on the safe steps',
    ClosePathPhase.verification => 'we were verifying',
    ClosePathPhase.opportunistic => 'we were looking at extra checks',
    ClosePathPhase.done => 'we had finished the steps',
  };
}

bool resumeLineLeaksEngineeringPhase(String text) {
  final lower = text.toLowerCase();
  return RegExp(r'\btools\b').hasMatch(lower) ||
      RegExp(r'\bguidance\b').hasMatch(lower);
}

String packagedResumeKnewLine({
  required SessionUiResumeState state,
  required List<Evidence> evidence,
}) {
  final last = evidence.isEmpty ? null : evidence.last;
  final lastBit = last == null
      ? 'no observations yet'
      : '${last.observation}: ${last.answer ?? 'recorded'}';
  return '$kResumeKnewLead ${resumeWhereWeLeftOff(state)}. $lastBit.';
}

/// Groq may phrase resume chrome; drop overlays that leak engine state names.
String resumeBannerSpokenLine({
  required String packaged,
  GroqPhrasingAccepted? overlay,
}) {
  if (overlay == null || !overlay.screenKey.startsWith('resume|')) {
    return packaged;
  }
  final spoken = overlay.whyOneLine.trim();
  if (spoken.isEmpty || resumeLineLeaksEngineeringPhase(spoken)) {
    return packaged;
  }
  return spoken;
}

String packagedProHandoffSpokenParagraph({
  required String applianceName,
  String? symptom,
  required List<SessionTimelineObservation> observations,
  required List<String> alreadyTried,
  String? leaderHypothesis,
  String? whyStopping,
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
  final why = whyStopping?.trim() ?? '';
  final whyClause = why.isEmpty ? '' : ' Why we stopped: $why.';
  return 'Please look at this ${applianceName.trim()}. Symptom: $what. '
      'Observed: $noticed. Already tried or not done: $tried.'
      '$whyClause '
      'Leading household-guide match: $leader — not a diagnosis.';
}

String? _bandOnly(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  if (standingLooksLikePercentage(trimmed)) {
    return null;
  }
  return trimmed;
}
