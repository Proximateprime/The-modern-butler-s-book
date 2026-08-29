import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'evidence_prompt_match.dart';
import 'failure_mode_standing.dart';
import 'safety_stop.dart';

/// Soft cap on meaningful interview answers before we stop prompting
/// the next question and show the current best guess. Not a score.
const int maxInterviewQuestionsSoftCap = 8;

/// Result of the single ask-vs-diagnose policy.
class StoppingRuleDecision {
  const StoppingRuleDecision({
    required this.askAnotherQuestion,
    required this.showDiagnosis,
    required this.safetyHardStop,
  });

  /// Present the next observation as the main action.
  final bool askAnotherQuestion;

  /// Show ranking/diagnosis (recommended primary, best guess, or close path).
  final bool showDiagnosis;

  final bool safetyHardStop;
}

/// One policy used before asking another question vs showing diagnosis.
///
/// Does not compute new scores. Uses the safety checklist, existing
/// [shouldStopInvestigation], [recommendPrimaryFailureModeId] as the
/// confidence threshold, a count cap, and an explicit skip flag.
StoppingRuleDecision stoppingRule({
  SafetyStop? safetyStop,
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  String? primaryFailureModeId,
  String? recommendPrimaryFailureModeId,
  bool skipToBestGuess = false,
  int maxQuestionsSoftCap = maxInterviewQuestionsSoftCap,
}) {
  if (safetyStop != null) {
    return const StoppingRuleDecision(
      askAnotherQuestion: false,
      showDiagnosis: true,
      safetyHardStop: true,
    );
  }

  final investigationDone = shouldStopInvestigation(
    templates: templates,
    recordedEvidence: recordedEvidence,
    primaryFailureModeId: primaryFailureModeId,
  );
  final atSoftCap =
      countMeaningfulInterviewAnswers(
        evidence: recordedEvidence,
        templates: templates,
      ) >=
      maxQuestionsSoftCap;
  final stopAsking = investigationDone || skipToBestGuess || atSoftCap;
  final confidenceThresholdMet = recommendPrimaryFailureModeId != null;

  return StoppingRuleDecision(
    askAnotherQuestion: !stopAsking,
    showDiagnosis: stopAsking || confidenceThresholdMet,
    safetyHardStop: false,
  );
}

/// Decides when open-ended observation suggestions should stop.
///
/// Once a Primary is selected, investigation yields to the verification close
/// path. Safety hard-stops are handled separately.
bool shouldStopInvestigation({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  String? primaryFailureModeId,
}) {
  if (primaryFailureModeId != null) {
    return true;
  }

  return unusedTemplates(
    templates: templates,
    recordedEvidence: recordedEvidence,
  ).isEmpty;
}

/// Counts recorded evidence whose matching package template relates to
/// [failureModeId]. Matching prefers template id, else prompt text.
int countRelatedEvidence({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  required String failureModeId,
}) {
  var count = 0;
  for (final item in recordedEvidence) {
    for (final template in templates) {
      if (!evidenceMatchesTemplate(item, template)) {
        continue;
      }
      if (template.relatedFailureModeIds.contains(failureModeId)) {
        count += 1;
        break;
      }
    }
  }
  return count;
}

/// First unused template related to the primary failure mode, for verification.
EvidenceTemplate? suggestVerificationObservation({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  required String primaryFailureModeId,
}) {
  for (final template in unusedTemplates(
    templates: templates,
    recordedEvidence: recordedEvidence,
  )) {
    if (template.id == 'hazard-observation') {
      continue;
    }
    if (template.relatedFailureModeIds.contains(primaryFailureModeId)) {
      return template;
    }
  }
  return null;
}
