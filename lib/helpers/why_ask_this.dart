import '../models/inspect_step.dart';
import '../models/knowledge_package.dart';
import 'easy_airflow_checks.dart';

/// Structured reason for showing a diagnostic question. Display only.
///
/// Codes come from package maps and question family — not an LLM and not a
/// ranking change.
enum WhyAskReasonCode {
  easyAirflow,
  heatPolarity,
  cycleSetting,
  splitsMappedAnswers,
  inspectLook,
  relatedModes,
  observeNarrow,
}

/// Short household-facing explanation for the current question.
class WhyAskThisExplanation {
  const WhyAskThisExplanation({
    required this.code,
    required this.body,
  });

  final WhyAskReasonCode code;
  final String body;
}

/// Authored split-sentences for no-heat (and shared airflow) templates.
///
/// Runtime phrasing uses these plus remaining-mode names. Never invented by
/// an LLM.
const Map<String, String> whyAskAuthoredByTemplateId = {
  'cycle-heat-setting':
      'Air-only / fluff can look like a failed heater. This confirms the '
      'dryer is on a heat cycle before we chase parts.',
  'heat-observed':
      'Warmth versus no warmth splits a restricted vent from an open fuse or '
      'heater. It is a look, not a diagnosis.',
  'lint-filter-condition':
      'A packed lint screen and a failed heater can both leave clothes cold. '
      'This look splits those without opening the cabinet.',
  'exterior-airflow':
      'Weak air at the outside vent points to a restricted exhaust. Strong '
      'air with no heat points more toward the heater path.',
  'vent-hose-condition':
      'A crushed or packed hose can block heat from leaving. This look tells '
      'airflow apart from a failed heater or fuse.',
  'drum-turns':
      'If the drum still turns, a belt or motor failure is less likely. That '
      'leaves no-heat causes as the ones this question is separating.',
  'recent-overheat':
      'A recent overheat episode supports a fuse or high-limit trip after '
      'restricted airflow, rather than a heater that never worked.',
  'dry-time-change':
      'Longer dry times with some heat point to airflow. Sudden no heat after '
      'normal times points more toward a heater or fuse.',
  'clothes-feel-after-cycle':
      'Warm-and-damp versus cold-and-damp splits restricted exhaust from no '
      'heat at the element.',
  'clothes-remain-damp':
      'Still-damp clothes after a cycle keeps heat and airflow in play. Fully '
      'dry clothes make a no-heat path less likely.',
  'heat-before-failure':
      'Heat that used to work, then stopped, splits a fuse or element failure '
      'from a setting or first-time install issue.',
};

/// Plain-language “why this question” from package maps and remaining modes.
///
/// Always returns a non-empty body when [template], [inspectStep], or
/// [templateId] is set. Does not rank, diagnose, or call an LLM.
/// Packaged source of truth — Groq may rephrase the displayed line only.
WhyAskThisExplanation whyAskThisQuestion({
  EvidenceTemplate? template,
  InspectStep? inspectStep,
  String? templateId,
  List<FailureMode> remainingModes = const [],
  List<FailureMode> packageModes = const [],
}) {
  final id =
      template?.id ?? inspectStep?.evidenceTemplateId ?? templateId?.trim() ?? '';
  final affected = _affectedModeIds(
    template: template,
    inspectStep: inspectStep,
  );
  final splitNames = _modeLabels(
    preferred: remainingModes,
    fallback: packageModes,
    affectedIds: affected,
  );
  final splitClause = _splitClause(splitNames);

  if (inspectStep != null) {
    final authored = whyAskAuthoredByTemplateId[id];
    if (authored != null) {
      return WhyAskThisExplanation(
        code: WhyAskReasonCode.inspectLook,
        body: _withSplit(authored, splitClause),
      );
    }
    final look = inspectStep.lookFor.trim();
    final body = look.isEmpty
        ? 'What you see here is recorded as an observation that can support '
            'or rule out remaining causes. It is not a diagnosis.$splitClause'
        : 'This look records what you actually see so later causes can be '
            'supported or ruled out. It is not a diagnosis.$splitClause';
    return WhyAskThisExplanation(
      code: WhyAskReasonCode.inspectLook,
      body: body,
    );
  }

  final authored = whyAskAuthoredByTemplateId[id];
  if (authored != null) {
    final code = easyAirflowCheckTemplateIds.contains(id)
        ? WhyAskReasonCode.easyAirflow
        : id == 'heat-observed'
        ? WhyAskReasonCode.heatPolarity
        : id == 'cycle-heat-setting'
        ? WhyAskReasonCode.cycleSetting
        : WhyAskReasonCode.splitsMappedAnswers;
    return WhyAskThisExplanation(
      code: code,
      body: _withSplit(authored, splitClause),
    );
  }

  if (template != null &&
      (template.supportByAnswer.isNotEmpty ||
          template.excludeByAnswer.isNotEmpty)) {
    return WhyAskThisExplanation(
      code: WhyAskReasonCode.splitsMappedAnswers,
      body:
          'Different answers here match different remaining possibilities'
          '${splitNames.isEmpty ? '' : ' — ${_joinLabels(splitNames)}'}'
          '. This is an observation, not a diagnosis.',
    );
  }

  if (affected.isNotEmpty && splitNames.isNotEmpty) {
    return WhyAskThisExplanation(
      code: WhyAskReasonCode.relatedModes,
      body:
          'This check is on the path because it can support or rule out '
          '${_joinLabels(splitNames)} without guessing a part.',
    );
  }

  return const WhyAskThisExplanation(
    code: WhyAskReasonCode.observeNarrow,
    body:
        'This is a beginner-safe look or listen that narrows remaining '
        'causes. It is not a diagnosis.',
  );
}

Set<String> _affectedModeIds({
  EvidenceTemplate? template,
  InspectStep? inspectStep,
}) {
  final ids = <String>{};
  if (template != null) {
    ids.addAll(template.relatedFailureModeIds);
    for (final list in template.supportByAnswer.values) {
      ids.addAll(list);
    }
    for (final list in template.excludeByAnswer.values) {
      ids.addAll(list);
    }
  }
  if (inspectStep != null) {
    ids.addAll(inspectStep.failureModeIds);
  }
  return ids;
}

List<String> _modeLabels({
  required List<FailureMode> preferred,
  required List<FailureMode> fallback,
  required Set<String> affectedIds,
}) {
  final fromPreferred = [
    for (final mode in preferred)
      if (affectedIds.contains(mode.id)) mode.label.trim(),
  ].where((label) => label.isNotEmpty).take(3).toList();
  if (fromPreferred.isNotEmpty) {
    return fromPreferred;
  }
  return [
    for (final mode in fallback)
      if (affectedIds.contains(mode.id)) mode.label.trim(),
  ].where((label) => label.isNotEmpty).take(3).toList();
}

String _joinLabels(List<String> labels) {
  if (labels.isEmpty) {
    return '';
  }
  if (labels.length == 1) {
    return labels.single;
  }
  if (labels.length == 2) {
    return '${labels[0]} and ${labels[1]}';
  }
  return '${labels[0]}, ${labels[1]}, and ${labels[2]}';
}

String _splitClause(List<String> labels) {
  if (labels.isEmpty) {
    return '';
  }
  return ' It currently helps separate ${_joinLabels(labels)}.';
}

String _withSplit(String authored, String splitClause) {
  if (splitClause.isEmpty) {
    return authored;
  }
  if (authored.endsWith('.')) {
    return '$authored$splitClause';
  }
  return '$authored.$splitClause';
}
