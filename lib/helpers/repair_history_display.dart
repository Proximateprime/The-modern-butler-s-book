import '../models/session_outcome.dart';

/// Short labels for known close paths. Speak Human in the list; ids stay as stored.
const Map<String, String> _repairPathLabels = {
  'thermal-fuse-open': 'Thermal fuse path',
  'restricted-exhaust-airflow': 'Vent path',
  'clogged-lint-pathway': 'Lint path',
  'heating-element-failed': 'Heating element path',
  'clogged-washer-drain-filter': 'Drain filter path',
  'closed-taps-or-kinked-inlet': 'Water supply path',
  'unbalanced-washer-load': 'Unbalanced load path',
  'loose-inlet-hose': 'Inlet hose path',
  'washer-door-not-latched': 'Door latch path',
  'kinked-or-clogged-washer-drain-hose': 'Drain hose path',
  'clogged-washer-inlet-screens': 'Inlet screen path',
  'washer-drain-hose-not-seated': 'Standpipe path',
  'washer-no-power-or-control-lock': 'Power or lock path',
  'clogged-dishwasher-filter': 'Tub filter path',
  'kinked-or-clogged-dishwasher-drain': 'Drain hose path',
  'dishwasher-door-not-latched': 'Door latch path',
  'clogged-dishwasher-spray-arms': 'Spray arms path',
  'closed-dishwasher-supply-or-air-gap': 'Supply path',
  'dishwasher-door-seal-or-loose-connection': 'Door seal path',
  'blocked-fridge-coils-or-airflow': 'Coils path',
  'blocked-fridge-internal-vents': 'Internal vents path',
  'fridge-door-gasket-or-ajar': 'Door seal path',
  'fridge-temp-controls-set-wrong': 'Temperature setting path',
  'clogged-fridge-defrost-drain': 'Drain pan path',
  'ice-maker-supply-or-switch': 'Ice maker supply path',
  'fridge-ice-bin-or-dispenser-jam': 'Ice bin path',
  'fridge-unlevel-or-vibration': 'Leveling path',
  'fridge-no-power-or-control': 'Power path',
};

const String _missingPrimaryCause = 'No primary hypothesis was selected.';

/// One-line appliance history title. Not ranking.
String repairHistoryHeadline(SessionOutcome outcome) {
  final symptom = _plainText(outcome.startSymptom);
  final path = _pathLabel(
    failureModeId: outcome.rankingLeaderFailureModeId,
    rankingLeaderLabel: outcome.rankingLeaderLabel,
  );
  final action = _shortAction(outcome);

  if (symptom != null && action != null && !_same(symptom, action)) {
    return '$symptom — $action';
  }
  if (path != null && action != null && !_same(path, action)) {
    return '$path — $action';
  }
  if (action != null) {
    return action;
  }
  if (path != null && outcome.verified) {
    return '$path — verified';
  }
  if (symptom != null && outcome.verified) {
    return '$symptom — verified';
  }
  if (symptom != null && path != null && !_same(symptom, path)) {
    return '$symptom — $path';
  }
  return path ?? symptom ?? sessionCloseKindLabel(outcome.closeKind);
}

/// Optional immediate/root cause under the headline. Hidden when already used.
String? repairHistoryCauseLine(SessionOutcome outcome) {
  final headline = repairHistoryHeadline(outcome);
  final action = _shortAction(outcome);
  final immediate = _plainText(outcome.immediateCause);
  final root = _plainText(outcome.rootCause);
  final parts = <String>[];
  if (immediate != null &&
      immediate != _missingPrimaryCause &&
      immediate != action &&
      !_containedIn(headline, immediate)) {
    parts.add(immediate);
  }
  if (root != null && root != action && !_containedIn(headline, root)) {
    parts.add(root);
  }
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' · ');
}

/// Optional note, contributing, prevention, and DIY spend. Hidden when empty.
List<String> repairHistoryExtraLines(SessionOutcome outcome) {
  final lines = <String>[];
  final note = _plainText(outcome.userNote);
  if (note != null) {
    lines.add(note);
  }
  final contributing = _joinedMemory(
    outcome.contributingFactors,
    prefix: 'Also: ',
  );
  if (contributing != null) {
    lines.add(contributing);
  }
  final prevention = _joinedMemory(
    outcome.preventiveActions,
    prefix: 'Prevent: ',
  );
  if (prevention != null) {
    lines.add(prevention);
  }
  final spent = outcome.diyCostUsd;
  if (spent != null && spent >= 0) {
    final rounded = spent.round();
    final shown =
        (spent - rounded).abs() < 0.005
            ? '\$$rounded'
            : '\$${spent.toStringAsFixed(2)}';
    lines.add('DIY about $shown');
  }
  return List.unmodifiable(lines);
}

/// Who recorded the session. Empty when the name is missing.
String? repairHistoryMemberLine(String? displayName) {
  final name = displayName?.trim();
  if (name == null || name.isEmpty) {
    return null;
  }
  return 'by $name';
}

String? _joinedMemory(List<String> items, {required String prefix}) {
  final kept = [
    for (final item in items)
      if (_plainText(item) != null) _plainText(item)!,
  ].take(2).toList();
  if (kept.isEmpty) {
    return null;
  }
  return '$prefix${kept.join(' · ')}';
}

String? _pathLabel({
  required String? failureModeId,
  required String? rankingLeaderLabel,
}) {
  final mapped = _repairPathLabels[failureModeId];
  if (mapped != null) {
    return mapped;
  }
  return _plainText(rankingLeaderLabel);
}

String? _shortAction(SessionOutcome outcome) {
  final raw = _plainText(outcome.immediateCause);
  if (raw == null || raw == _missingPrimaryCause) {
    return null;
  }
  if (raw.length > 48 || raw.contains('. ')) {
    return null;
  }
  return raw;
}

String? _plainText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();

bool _containedIn(String haystack, String needle) {
  return haystack.toLowerCase().contains(needle.toLowerCase());
}
