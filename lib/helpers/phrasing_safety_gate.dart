import 'confidence_display.dart';
import 'forbidden_guidance.dart';
import 'package_release_validator.dart';
import 'phrasing_request.dart';
import 'user_facing_error.dart';

/// Attach-map gates confirmed on leftover 8bad47be.
///
/// Every Groq string must pass:
/// - [visibleHouseholdHowTo]
/// - [lineLooksLikeUnsafeInstruction]
/// - official-stop substring (unplug AND ventilate AND don’t keep running)
///   when the slot is a stop shorten
/// - [standingLooksLikePercentage]
GroqPhrasingAccepted? acceptGroqPhrasing({
  required PhrasingRequest request,
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
    for (final entry in labels.entries) {
      if (isGoldenChromeLabel(entry.key) && entry.value != entry.key) {
        return null;
      }
      if (isGoldenChromeLabel(entry.value) && entry.value != entry.key) {
        return null;
      }
    }
  }

  final fields = <String>[
    if (title != null && title.isNotEmpty) title,
    if (why != null && why.isNotEmpty) why,
    ...labels.values,
  ];
  final requireOfficialStop = request.slot == PhrasingSlot.safetyStop ||
      request.safety == 'stop_unplug';
  for (final field in fields) {
    if (!groqStringPassesSafetyGate(
      field,
      requireOfficialStop: false,
      banned: request.banned,
    )) {
      return null;
    }
  }

  if (_violatesGoldenChrome(
        packaged: request.packagedTitle,
        groq: title,
      ) ||
      _violatesGoldenChrome(
        packaged: request.packagedWhyOneLine,
        groq: why,
      )) {
    return null;
  }

  if (request.slot == PhrasingSlot.questionCard) {
    if (title != null && _isQuestionSlotNovel(title)) {
      return null;
    }
  }

  if (requireOfficialStop) {
    final shortened = why ?? title ?? '';
    if (!hasOfficialStopSubstrings(shortened)) {
      return null;
    }
  }

  if (request.slot == PhrasingSlot.confirmNotFixed ||
      request.allowResolvedWhenConfirmed == false ||
      !request.offersFixed) {
    for (final field in fields) {
      if (_offersFixedWhenNotEligible(field, request)) {
        return null;
      }
    }
  }

  if ((request.comfort == 'short' ||
          request.slot == PhrasingSlot.skillComfort) &&
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
    whyOneLine: (why != null && why.isNotEmpty) ? why : packaged.whyOneLine,
    optionLabels: {
      ...packaged.optionLabels,
      ...labels,
    },
    fromGroq: true,
  );
}

/// One Groq string through the attach-map gates.
bool groqStringPassesSafetyGate(
  String text, {
  required bool requireOfficialStop,
  List<String> banned = kGroqPhrasingBanned,
}) {
  if (text.trim().isEmpty) {
    return false;
  }
  if (_containsBanned(text, banned)) {
    return false;
  }
  if (lineLooksLikeUnsafeInstruction(text)) {
    return false;
  }
  if (standingLooksLikePercentage(text) || _containsConfidenceNumber(text)) {
    return false;
  }
  if (_failsHouseholdHowToGate(text)) {
    return false;
  }
  if (requireOfficialStop && !hasOfficialStopSubstrings(text)) {
    return false;
  }
  return true;
}

/// Official stop shorten: unplug AND ventilate AND don’t keep running.
bool hasOfficialStopSubstrings(String text) {
  final lower = text.toLowerCase();
  final unplug = lower.contains('unplug');
  final ventilate = lower.contains('ventilate');
  final dontRun = lower.contains('do not keep running') ||
      lower.contains("don't keep running") ||
      lower.contains('don’t keep running');
  return unplug && ventilate && dontRun;
}

bool safetyStopShortenAcceptable(String candidate) {
  return groqStringPassesSafetyGate(candidate, requireOfficialStop: true);
}

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

bool confirmNotFixedPhrasingFlipsEligibility({
  required bool allowResolvedWhenConfirmed,
  required String phrasing,
}) {
  if (allowResolvedWhenConfirmed) {
    return false;
  }
  return _claimsFixedAvailable(phrasing);
}

bool _violatesGoldenChrome({
  required String packaged,
  required String? groq,
}) {
  if (groq == null || groq.isEmpty) {
    return false;
  }
  if (isGoldenChromeLabel(packaged) && groq != packaged) {
    return true;
  }
  if (isGoldenChromeLabel(groq) && groq != packaged) {
    return true;
  }
  return false;
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
  if (visible.isEmpty &&
      text.trim().isNotEmpty &&
      !isSafetyLimitLanguage(text)) {
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

bool _offersFixedWhenNotEligible(String text, PhrasingRequest request) {
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
