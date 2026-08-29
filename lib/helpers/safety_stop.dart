import '../models/evidence.dart';
import 'dryer_close_path.dart';
import 'user_facing_error.dart';

/// Deterministic hard-stop result for the Session screen safety gate.
///
/// This is not a Safety Engine or Reasoning Engine. It only applies an
/// explicit, documented checklist of substring and failure-mode matches.
class SafetyStop {
  const SafetyStop({required this.reason});

  /// Short explainable reason shown to the user.
  final String reason;
}

/// Dryer MVP hard-stop checklist (documented in-code until package flags exist).
///
/// Evidence observation substrings (case-insensitive):
/// - Gas: `gas smell`, `smell of gas`, `natural gas`, `propane`
/// - Live electrical language: `live voltage`, `live electrical`,
///   `live testing`, `test while live`, `energized`
/// - Immediate hazard: `burning smell`, `smoke`, `melting`, `melted`,
///   `on fire`, `sparking`, `sparks`
///
/// Primary hypothesis failure mode ids that still hard-stop:
/// - `electrical-burning-smell-hazard` → fire/smoke hazard path
///
/// Gated / needs-professional Primary ids are **not** hard-stopped (they emit
/// `professional` from [sessionSafetyLevelFor] so the lamp is Check carefully):
/// - `electric-supply-connection-fault`, `motor-failure`, `start-switch-failure`
/// - `start-capacitor-or-start-assist-weak`,
///   `gas-dryer-no-ignition-professional-only`
/// - `internal-duct-lint-collapse`, `blower-wheel-obstruction`
/// - any close path with `allowResolvedWhenConfirmed: false` (e.g. thermal fuse)
/// - heater-circuit DIY-cannot-complete leaders (heating-element, high-limit,
///   cycling thermostat, relay/control, thermistor, timer heat segment)
/// Start-switch is not door-switch: Confirmed does not unlock Fixed.
/// Start-capacitor is not door-switch and not motor-overheat-protector-open.
///
/// Not hard-stopped by Primary alone (soft close path available):
/// - `heating-element-failed` — identify mode; lamp professional; Confirmed
///   does not unlock Fixed; no live testing guidance
/// - `thermal-fuse-open` — beginner-safe lint/vent checks first; never bypass
/// - `dusty-lint-smell` — non-hazard odor; still escalate if smell type changes
/// Door-switch Fixed when a firm click starts the machine is unchanged.
/// Safety Invariants win over symptom seeding and the interview: if this
/// function returns a stop, the Session screen must not continue ordinary
/// questions (including starter chips treated as normal evidence).
/// Household-facing actions shown on every hard-stop path (chip, type, voice).
String safetyStopOfficialCopy() => UserFacingCopy.safetyStopOfficial;

/// Banner / cue body: why we stopped, then the official actions.
String safetyStopDisplayCopy(SafetyStop stop) {
  final why = stop.reason.trim();
  final official = UserFacingCopy.safetyStopOfficial;
  if (why.isEmpty || official.contains(why) || why == official) {
    return official;
  }
  return '$why\n\n$official';
}

/// Stored session details level. Never the placeholder "not evaluated".
///
/// `stop` — hard safety stop (evidence hazard or fire/smoke FM).
/// `professional` — gated / needs-professional FM that is not a hard stop.
/// `clear` — no hard stop and not a gated professional path.
String sessionSafetyLevelFor({
  required List<Evidence> evidence,
  String? primaryFailureModeId,
}) {
  if (evaluateSafetyStop(
        evidence: evidence,
        primaryFailureModeId: primaryFailureModeId,
      ) !=
      null) {
    return 'stop';
  }
  if (isGatedProfessionalFailureMode(primaryFailureModeId)) {
    return 'professional';
  }
  return 'clear';
}

/// Gated professional Primary — lamp Check carefully, not a hard stop.
bool isGatedProfessionalFailureMode(String? failureModeId) {
  if (failureModeId == null || failureModeId.isEmpty) {
    return false;
  }
  if (_hardStopFailureModeReasons.containsKey(failureModeId)) {
    return false;
  }
  if (_gatedProfessionalFailureModeIds.contains(failureModeId)) {
    return true;
  }
  if (isHeaterCircuitDiyCannotCompleteLeader(failureModeId)) {
    return true;
  }
  final path = closePathForFailureMode(failureModeId);
  return path != null && !path.allowResolvedWhenConfirmed;
}

SafetyStop? evaluateSafetyStop({
  required List<Evidence> evidence,
  String? primaryFailureModeId,
}) {
  for (final item in evidence) {
    // Structured hazard prompt: only affirmative / hazard-word answers stop.
    // A clear "No" must not hard-stop just because the prompt text mentions
    // burning/smoke (needed to separate non-hazard dusty-lint smell).
    if (item.templateId == 'hazard-observation') {
      final answer = (item.answer ?? '').trim().toLowerCase();
      if (answer == 'yes' ||
          answer.contains('burning') ||
          answer.contains('smoke') ||
          answer.contains('spark')) {
        return const SafetyStop(reason: 'Possible fire or smoke hazard');
      }
      continue;
    }

    final fromObservation = _matchEvidenceObservation(item.observation);
    if (fromObservation != null) {
      return fromObservation;
    }
    final answer = item.answer;
    if (answer != null && answer.isNotEmpty) {
      final fromAnswer = _matchEvidenceObservation(answer);
      if (fromAnswer != null) {
        return fromAnswer;
      }
    }
  }

  if (primaryFailureModeId != null) {
    final reason = _hardStopFailureModeReasons[primaryFailureModeId];
    if (reason != null) {
      return SafetyStop(reason: reason);
    }
  }

  return null;
}

const Map<String, String> _hardStopFailureModeReasons = {
  'electrical-burning-smell-hazard': 'Possible fire or smoke hazard',
};

const Set<String> _gatedProfessionalFailureModeIds = {
  'electric-supply-connection-fault',
  'motor-failure',
  'start-switch-failure',
  'start-capacitor-or-start-assist-weak',
  'gas-dryer-no-ignition-professional-only',
  'internal-duct-lint-collapse',
  'blower-wheel-obstruction',
};
const List<_EvidenceSafetyRule> _evidenceRules = [
  _EvidenceSafetyRule(
    reason: 'Possible gas hazard',
    patterns: [
      'gas smell',
      'smell of gas',
      'gas-like',
      'gas odor',
      'natural gas',
      'propane',
    ],
  ),
  _EvidenceSafetyRule(
    reason: 'Requires professional electrical work',
    patterns: [
      'live voltage',
      'live electrical',
      'live testing',
      'test while live',
      'energized',
    ],
  ),
  _EvidenceSafetyRule(
    reason: 'Possible fire or smoke hazard',
    patterns: [
      'burning smell',
      'smoke',
      'melting',
      'melted',
      'on fire',
      'sparking',
      'sparks',
    ],
  ),
];

SafetyStop? _matchEvidenceObservation(String observation) {
  final lowered = observation.toLowerCase();
  for (final rule in _evidenceRules) {
    for (final pattern in rule.patterns) {
      if (lowered.contains(pattern)) {
        return SafetyStop(reason: rule.reason);
      }
    }
  }
  return null;
}

class _EvidenceSafetyRule {
  const _EvidenceSafetyRule({
    required this.reason,
    required this.patterns,
  });

  final String reason;
  final List<String> patterns;
}
