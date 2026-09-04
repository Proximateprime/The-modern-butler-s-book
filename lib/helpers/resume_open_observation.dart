import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'evidence_prompt_match.dart';

/// Continue repair restores the observation that was on screen.
///
/// Ranking’s suggested-next / conclusion chrome must not steal that id while
/// the household still has that question open (unanswered).
String? preferOnScreenOpenObservationId({
  required String? onScreenTemplateId,
  required String? rankingSuggestedNextTemplateId,
  required bool onScreenStillOpen,
}) {
  if (onScreenStillOpen &&
      onScreenTemplateId != null &&
      onScreenTemplateId.isNotEmpty) {
    return onScreenTemplateId;
  }
  return rankingSuggestedNextTemplateId;
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
