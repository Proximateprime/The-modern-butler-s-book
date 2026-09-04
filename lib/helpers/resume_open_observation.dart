import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'close_path_phase.dart';
import 'evidence_prompt_match.dart';

/// Continue repair restores the observation that was on screen.
///
/// Ranking’s suggested-next, empty-next (“No more questions for now”), and
/// close-path guidance / safe-steps chrome must not steal that id while the
/// household still has that question open (unanswered).
String? preferOnScreenOpenObservationId({
  required String? onScreenTemplateId,
  required String? rankingSuggestedNextTemplateId,
  required bool onScreenStillOpen,
}) {
  if (unansweredOpenObservationShouldStayOnScreen(
    onScreenTemplateId: onScreenTemplateId,
    onScreenStillOpen: onScreenStillOpen,
  )) {
    return onScreenTemplateId;
  }
  return rankingSuggestedNextTemplateId;
}

/// Unanswered on-screen interview wins over ranking next *and* over a null
/// next (conclusion / skip / soft-cap would otherwise paint an empty panel).
bool unansweredOpenObservationShouldStayOnScreen({
  required String? onScreenTemplateId,
  required bool onScreenStillOpen,
}) {
  return onScreenStillOpen &&
      onScreenTemplateId != null &&
      onScreenTemplateId.isNotEmpty;
}

/// Mid-guidance resume stays valid only when there is no unanswered open
/// interview. An open observation pins Continue repair on conclusion so
/// restore cannot jump into safe-steps chrome.
ClosePathPhase resumeClosePathPhaseHonoringOpenObservation({
  required ClosePathPhase computed,
  required bool unansweredOpenObservation,
}) {
  if (unansweredOpenObservation) {
    return ClosePathPhase.conclusion;
  }
  return computed;
}

bool interviewTemplateIsStillOpen({
  required String? templateId,
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
}) {
  if (templateId == null || templateId.isEmpty) {
    return false;
  }
  EvidenceTemplate? template;
  for (final item in templates) {
    if (item.id == templateId) {
      template = item;
      break;
    }
  }
  if (template == null) {
    return false;
  }
  return !isTemplateRecorded(
    template: template,
    recordedEvidence: recordedEvidence,
  );
}
