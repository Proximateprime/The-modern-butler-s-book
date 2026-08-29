import '../models/evidence.dart';

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
/// Primary hypothesis failure mode ids that always require a professional:
/// - `electric-supply-connection-fault` → high-voltage supply work
/// - `motor-failure` → package directs escalation over DIY electrical work
/// - `electrical-burning-smell-hazard` → fire/smoke hazard path
///
/// Not hard-stopped by Primary alone (soft close path available):
/// - `heating-element-failed` — identify mode; no live testing guidance
/// - `thermal-fuse-open` — beginner-safe lint/vent checks first; never bypass
/// - `dusty-lint-smell` — non-hazard odor; still escalate if smell type changes
/// Safety Invariants win over symptom seeding and the interview: if this
/// function returns a stop, the Session screen must not continue ordinary
/// questions (including starter chips treated as normal evidence).
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
    final reason = _professionalFailureModeReasons[primaryFailureModeId];
    if (reason != null) {
      return SafetyStop(reason: reason);
    }
  }

  return null;
}

const Map<String, String> _professionalFailureModeReasons = {
  'electric-supply-connection-fault':
      'Requires professional electrical work',
  'motor-failure': 'Requires professional service',
  'electrical-burning-smell-hazard': 'Possible fire or smoke hazard',
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
