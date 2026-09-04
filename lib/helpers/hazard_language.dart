/// Shared household hazard language. Voice, typed Other, free notes, and
/// hazard-observation Other must use this list — do not fork copies.
///
/// Categories John gates on: smell-gas, gas-leak, propane, bare-burning.

/// Smell-gas phrasing, including “I smell gas” (`smell gas` substring).
const List<String> kSmellGasHazardMarkers = [
  'smell gas',
  'gas smell',
  'smell of gas',
  'smells like gas',
  'gas odor',
  'gas-like',
  'gas like',
];

const List<String> kGasLeakHazardMarkers = [
  'gas leak',
  'gas-leak',
  'leaking gas',
];

const List<String> kPropaneHazardMarkers = [
  'propane',
  'natural gas',
];

/// Bare burning (not only “burning smell”).
const List<String> kBareBurningHazardMarkers = [
  'burning',
  'burn smell',
  'burning smell',
];

const List<String> kFireSmokeSparkHazardMarkers = [
  'smoke',
  'spark',
  'sparks',
  'sparking',
  'on fire',
  'melting',
  'melted',
];

/// One concatenated list. Safety stop, voice, typed Other, and starter
/// hazard-signs keywords must reference this — not a private duplicate.
const List<String> kSharedHazardLanguageMarkers = [
  ...kSmellGasHazardMarkers,
  ...kGasLeakHazardMarkers,
  ...kPropaneHazardMarkers,
  ...kBareBurningHazardMarkers,
  ...kFireSmokeSparkHazardMarkers,
];

enum HazardLanguageKind {
  gas,
  fireSmoke,
}

String normalizeHazardText(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool textContainsHazardMarker(String raw, List<String> markers) {
  final text = normalizeHazardText(raw);
  if (text.isEmpty) {
    return false;
  }
  for (final marker in markers) {
    final needle = normalizeHazardText(marker);
    if (needle.isNotEmpty && text.contains(needle)) {
      return true;
    }
  }
  return false;
}

/// Gas language first, then fire/smoke/spark. Used so hazard-observation
/// Other cannot skip the gas matcher.
HazardLanguageKind? classifyHazardLanguage(String raw) {
  if (textContainsHazardMarker(raw, kSmellGasHazardMarkers) ||
      textContainsHazardMarker(raw, kGasLeakHazardMarkers) ||
      textContainsHazardMarker(raw, kPropaneHazardMarkers)) {
    return HazardLanguageKind.gas;
  }
  if (textContainsHazardMarker(raw, kBareBurningHazardMarkers) ||
      textContainsHazardMarker(raw, kFireSmokeSparkHazardMarkers)) {
    return HazardLanguageKind.fireSmoke;
  }
  return null;
}

bool textSuggestsHazard(String raw) => classifyHazardLanguage(raw) != null;

const String kHazardLanguageGasReason = 'Possible gas hazard';
const String kHazardLanguageFireSmokeReason = 'Possible fire or smoke hazard';

String? hazardLanguageStopReason(String raw) {
  switch (classifyHazardLanguage(raw)) {
    case HazardLanguageKind.gas:
      return kHazardLanguageGasReason;
    case HazardLanguageKind.fireSmoke:
      return kHazardLanguageFireSmokeReason;
    case null:
      return null;
  }
}
