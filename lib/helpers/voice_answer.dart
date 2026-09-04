import 'hazard_language.dart';

/// Maps spoken text onto answer chips. Display only — not a diagnosis engine.
String normalizeVoiceTranscript(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Voice / chip-id match on the original engine id, not a Groq display string.
bool isOtherDescribeChoice(String choice) {
  return normalizeVoiceTranscript(choice).startsWith('other');
}

/// Returns a chip label when [transcript] clearly matches one choice.
///
/// Ambiguous or unmatched speech returns null so the caller can fill
/// Other / describe instead of guessing.
String? matchVoiceToAnswerChoice(String transcript, List<String> choices) {
  final spoken = normalizeVoiceTranscript(transcript);
  if (spoken.isEmpty) {
    return null;
  }

  final matchable =
      choices.where((choice) => !isOtherDescribeChoice(choice)).toList();
  if (matchable.isEmpty) {
    return null;
  }

  final exact =
      matchable
          .where((choice) => normalizeVoiceTranscript(choice) == spoken)
          .toList();
  if (exact.length == 1) {
    return exact.single;
  }
  if (exact.length > 1) {
    return null;
  }

  final tokens = spoken.split(' ');
  final shortHits = <String>[];
  final phraseHits = <String>[];
  for (final choice in matchable) {
    final normalized = normalizeVoiceTranscript(choice);
    if (normalized.isEmpty) {
      continue;
    }
    final words = normalized.split(' ');
    if (words.length == 1 && words.first.length <= 3) {
      if (tokens.length == 1 && tokens.first == words.first) {
        shortHits.add(choice);
      }
      continue;
    }
    if (spoken.contains(normalized) ||
        (spoken.length >= 4 &&
            normalized.contains(spoken) &&
            words.length <= 4)) {
      phraseHits.add(choice);
    }
  }

  if (shortHits.length == 1 && phraseHits.isEmpty) {
    return shortHits.single;
  }
  if (phraseHits.length == 1) {
    return phraseHits.single;
  }
  return null;
}

bool transcriptSuggestsHazard(String transcript) {
  return textSuggestsHazard(transcript);
}

bool isAffirmativeHazardChoice(String choice) {
  final normalized = normalizeVoiceTranscript(choice);
  return normalized == 'yes' || textSuggestsHazard(choice);
}
