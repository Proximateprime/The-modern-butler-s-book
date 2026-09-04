import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'close_path_phase.dart';
import 'evidence_prompt_match.dart';

/// Continue repair restores the observation that was on screen.
///
/// Ranking’s suggested-next, an earlier interview template (drum-turns),
/// empty-next (“No more questions for now”), a named primary (Most likely /
/// Reviewing the likely cause), and close-path guidance / safe-steps chrome
/// must not steal that id while the household still has that question open
/// (unanswered).
String? preferOnScreenOpenObservationId({
  required String? onScreenTemplateId,
  required String? rankingSuggestedNextTemplateId,
  required bool onScreenStillOpen,
  String? paintedTemplateId,
  bool paintedStillOpen = false,
  String? storedPendingTemplateId,
  bool storedPendingStillOpen = false,
}) {
  if (unansweredOpenObservationShouldStayOnScreen(
    onScreenTemplateId: onScreenTemplateId,
    onScreenStillOpen: onScreenStillOpen,
  )) {
    return onScreenTemplateId;
  }
  if (unansweredOpenObservationShouldStayOnScreen(
    onScreenTemplateId: paintedTemplateId,
    onScreenStillOpen: paintedStillOpen,
  )) {
    return paintedTemplateId;
  }
  if (unansweredOpenObservationShouldStayOnScreen(
    onScreenTemplateId: storedPendingTemplateId,
    onScreenStillOpen: storedPendingStillOpen,
  )) {
    return storedPendingTemplateId;
  }
  return rankingSuggestedNextTemplateId;
}

/// Unanswered on-screen interview wins over ranking next *and* over a null
/// next (conclusion / skip / soft-cap would otherwise paint an empty panel).
///
/// A named primary is not an input: Most likely chrome must
/// not blank the open question. I'll-repair / tools / guidance progress is
/// gated separately via [shouldHoldUnansweredOpenInterviewOnResume].
bool unansweredOpenObservationShouldStayOnScreen({
  required String? onScreenTemplateId,
  required bool onScreenStillOpen,
}) {
  return onScreenStillOpen &&
      onScreenTemplateId != null &&
      onScreenTemplateId.isNotEmpty;
}

/// Restore the unanswered on-screen interview after Continue repair.
///
/// Does **not** require a null primary. Ranking may already have named a
/// cause; that chrome stays allowed, but it cannot steal the open question.
/// Real close-path progress (I'll repair, tools marks, guidance, inspect
/// review, pending close verification) still keeps the household on that path.
bool shouldHoldUnansweredOpenInterviewOnResume({
  required String? onScreenTemplateId,
  required bool onScreenStillOpen,
  required bool hasRealClosePathProgress,
}) {
  return unansweredOpenObservationShouldStayOnScreen(
        onScreenTemplateId: onScreenTemplateId,
        onScreenStillOpen: onScreenStillOpen,
      ) &&
      !hasRealClosePathProgress;
}

/// Naming Most likely / confirming a primary must not drop the unanswered
/// on-screen interview. Chrome may name the cause; it must not blank, skip,
/// or invent a chip for that id.
bool shouldKeepUnansweredOpenInterviewWhenPrimaryNamed({
  required String? onScreenTemplateId,
  required bool onScreenStillOpen,
}) {
  return unansweredOpenObservationShouldStayOnScreen(
    onScreenTemplateId: onScreenTemplateId,
    onScreenStillOpen: onScreenStillOpen,
  );
}

/// Continue repair must not write a suggested, default, or inspect chip for
/// an unanswered open observation (for example lint-filter → “Heavily
/// clogged”) while restore is still settling.
bool shouldBlockResumeInventedObservationWrite({
  required bool resumeNotSettled,
  required bool unansweredOpenInterview,
}) {
  return resumeNotSettled && unansweredOpenInterview;
}

/// Close-path Continue / inspect auto-advance must not skip an unanswered
/// open interview (lint-filter must not jump to outside-vent).
bool shouldBlockResumeAdvancePastUnansweredOpenInterview({
  required bool unansweredOpenInterview,
}) {
  return unansweredOpenInterview;
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

/// I'll repair / tools / guidance already underway — do not steal back to
/// an unanswered interview leftover in the resume row.
bool resumeHasRealClosePathProgress({
  required bool choseRepair,
  required List<String> completedGuidanceStepIds,
  required int guidanceStepIndex,
  required Map<String, bool> readinessHaveByToolId,
  required String? pendingCloseVerificationFailureModeId,
  required bool inspectReviewOnly,
}) {
  final closeId = pendingCloseVerificationFailureModeId;
  return choseRepair ||
      completedGuidanceStepIds.isNotEmpty ||
      guidanceStepIndex > 0 ||
      readinessHaveByToolId.isNotEmpty ||
      (closeId != null && closeId.isNotEmpty) ||
      inspectReviewOnly;
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
    // Missing package row must not drop a held id into ranking next /
    // earlier interview (drum-turns). Unanswered by evidence id still holds.
    return !isTemplateRecordedById(
      templateId: templateId,
      recordedEvidence: recordedEvidence,
    );
  }
  return !isTemplateRecorded(
    template: template,
    recordedEvidence: recordedEvidence,
  );
}
