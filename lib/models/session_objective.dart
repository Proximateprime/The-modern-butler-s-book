/// Optional household goal for one repair session.
///
/// Display and handoff timing only. Never used in ranking.
enum SessionObjective {
  fixIt,
  figureOutWhatsWrong,
  decideRepairVsReplace,
  prepareToCallAPro,
}

SessionObjective? sessionObjectiveFromName(String? raw) {
  final name = raw?.trim();
  if (name == null || name.isEmpty) {
    return null;
  }
  for (final value in SessionObjective.values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}

String sessionObjectiveChipLabel(SessionObjective objective) {
  return switch (objective) {
    SessionObjective.fixIt => 'Fix it',
    SessionObjective.figureOutWhatsWrong => "Figure out what's wrong",
    SessionObjective.decideRepairVsReplace => 'Decide repair vs replace',
    SessionObjective.prepareToCallAPro => 'Prepare to call a pro',
  };
}

/// Parts/cost on the close path after a Primary is set.
bool showPartsCostOnClosePath(SessionObjective? objective) {
  return objective != SessionObjective.figureOutWhatsWrong;
}

/// Parts/cost as soon as a recommended match is on screen (before Primary).
bool showPartsCostOnRecommendedPrimary(SessionObjective? objective) {
  return objective == SessionObjective.decideRepairVsReplace;
}

bool showIllRepairOnPartsCard(SessionObjective? objective) {
  return objective != SessionObjective.prepareToCallAPro;
}

bool showCallProOnPartsCard(SessionObjective? objective) {
  return objective != SessionObjective.figureOutWhatsWrong;
}

/// Call-a-pro CTA on the recommended match, before close path.
bool showEarlyProHandoffOnRecommended(SessionObjective? objective) {
  return objective == SessionObjective.prepareToCallAPro;
}

String sessionObjectiveInterviewCueTitle({
  required SessionObjective? objective,
  required bool hasRecommendedPrimary,
}) {
  if (!hasRecommendedPrimary) {
    return 'Next: answer the current question';
  }
  return switch (objective) {
    SessionObjective.decideRepairVsReplace =>
      'Next: compare repair vs replace',
    SessionObjective.prepareToCallAPro =>
      'Next: review notes for a technician',
    SessionObjective.fixIt => 'Next: review the most likely match',
    SessionObjective.figureOutWhatsWrong =>
      'Next: review the most likely match',
    null => 'Next: review the most likely match',
  };
}

String sessionObjectiveInterviewCueDetail({
  required SessionObjective? objective,
  required bool hasRecommendedPrimary,
  required bool hideNextQuestion,
}) {
  return switch (objective) {
    SessionObjective.fixIt =>
      hasRecommendedPrimary
          ? (hideNextQuestion
              ? 'This is the current best guess. Accept it when you are ready to try a fix.'
              : 'Accept only if it fits, then we will walk a beginner-safe fix.')
          : 'Answer what you notice so we can aim at a fix.',
    SessionObjective.figureOutWhatsWrong =>
      'Focus on what you notice. Parts and calling a pro wait until you have a match.',
    SessionObjective.decideRepairVsReplace =>
      hasRecommendedPrimary
          ? 'Compare DIY vs professional estimates for this likely match.'
          : 'We will show parts and pro estimates when a likely match is ready.',
    SessionObjective.prepareToCallAPro =>
      hasRecommendedPrimary
          ? 'Use Call a pro when you have enough to share with a technician.'
          : 'Answer enough to describe the problem to a technician.',
    null =>
      hasRecommendedPrimary
          ? (hideNextQuestion
              ? 'This is the current best guess from your answers.'
              : 'Accept only if it fits, or keep answering questions below.')
          : 'The app will pick the following question from your answers.',
  };
}

const String _bestMatchHumble =
    'This is the best match from your answers so far — not a certainty, '
    'and not a percentage.';

String sessionObjectiveRecommendedHint(SessionObjective? objective) {
  return switch (objective) {
    SessionObjective.fixIt =>
      '$_bestMatchHumble '
          'Accept to set Primary and open a beginner-safe fix — or keep answering.',
    SessionObjective.figureOutWhatsWrong =>
      '$_bestMatchHumble '
          'Accept when you want to verify this match.',
    SessionObjective.decideRepairVsReplace =>
      'Use the estimates to compare a DIY repair with calling a pro. '
          'Accept as Primary only if you want to verify this match. '
          'This is not a percentage score.',
    SessionObjective.prepareToCallAPro =>
      'This is enough to brief a technician. You can call a pro now, '
          'or accept as Primary to verify first. This is not a percentage score.',
    null =>
      '$_bestMatchHumble '
          'Accept to set Primary and open verification — or keep answering '
          'questions first.',
  };
}
