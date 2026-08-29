import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../models/session_outcome.dart';
import '../ui/app_dependencies.dart';

/// Seeded copy for the Fixed outcome form. Empty strings mean nothing to seed.
class RootCauseMemorySeed {
  const RootCauseMemorySeed({
    required this.immediateCause,
    required this.rootCause,
    required this.contributingFactors,
    required this.preventiveActions,
  });

  final String immediateCause;
  final String rootCause;
  final List<String> contributingFactors;
  final List<String> preventiveActions;
}

RootCauseMemorySeed rootCauseMemorySeed({
  String? failureModeId,
  String? rankingLeaderLabel,
}) {
  final authoring = FailureModeAuthoringRegistry.lookup(failureModeId);
  return RootCauseMemorySeed(
    immediateCause: _firstNonEmpty([
          authoring?.immediateCause,
          rankingLeaderLabel,
        ]) ??
        '',
    rootCause: authoring?.rootCause.trim() ?? '',
    contributingFactors: [
      for (final factor in authoring?.contributingFactors ?? const <String>[])
        if (factor.trim().isNotEmpty) factor.trim(),
    ],
    preventiveActions: [
      for (final action in authoring?.preventionActions ?? const <String>[])
        if (action.trim().isNotEmpty) action.trim(),
    ],
  );
}

List<String> splitMemoryLines(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  return [
    for (final line in raw.split(RegExp(r'[\n;]+')))
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

String joinMemoryLines(List<String> items) {
  return [
    for (final item in items)
      if (item.trim().isNotEmpty) item.trim(),
  ].join('\n');
}

/// Package seed the household confirmed, or their own words. Never an LLM guess.
String? confirmedRootCause({
  required bool notSure,
  required String suggested,
  required String custom,
}) {
  if (notSure) {
    return null;
  }
  final typed = custom.trim();
  if (typed.isNotEmpty) {
    return typed;
  }
  final seed = suggested.trim();
  if (seed.isNotEmpty) {
    return seed;
  }
  return null;
}

List<String> confirmedMemoryItems({
  required List<String> selected,
  String? extraLines,
}) {
  final seen = <String>{};
  final items = <String>[];
  for (final raw in [...selected, ...splitMemoryLines(extraLines)]) {
    final item = raw.trim();
    if (item.isEmpty || !seen.add(item.toLowerCase())) {
      continue;
    }
    items.add(item);
  }
  return List.unmodifiable(items);
}

/// Latest Fixed memory with a cause. Hint only — never ranking input.
class PriorRootCauseHint {
  const PriorRootCauseHint({
    required this.immediateCause,
    this.rootCause,
  });

  final String immediateCause;
  final String? rootCause;
}

PriorRootCauseHint? priorRootCauseHint({
  required List<RecentSessionOutcome> history,
  String? excludeSessionId,
}) {
  for (final item in history) {
    if (item.outcome.sessionId == excludeSessionId) {
      continue;
    }
    if (item.outcome.closeKind != SessionCloseKind.fixed) {
      continue;
    }
    final immediate = item.outcome.immediateCause.trim();
    final root = item.outcome.rootCause?.trim();
    if (immediate.isEmpty && (root == null || root.isEmpty)) {
      continue;
    }
    return PriorRootCauseHint(
      immediateCause: immediate,
      rootCause: (root == null || root.isEmpty) ? null : root,
    );
  }
  return null;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}
