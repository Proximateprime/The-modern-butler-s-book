import '../models/evidence.dart';
import '../models/inspect_step.dart';
import 'evidence_prompt_match.dart';
import 'inspect_steps.dart';

/// One already-recorded (or still unanswered) inspect check for review mode.
class InspectReviewRow {
  const InspectReviewRow({
    required this.step,
    this.recordedAnswer,
  });

  final InspectStep step;
  final String? recordedAnswer;

  bool get answered =>
      recordedAnswer != null && recordedAnswer!.trim().isNotEmpty;
}

/// Static checklist of inspect steps already on this path. Does not write
/// evidence. Used after Most likely so "review what you checked" cannot
/// restart the interview.
List<InspectReviewRow> inspectReviewRows({
  required List<InspectStep> steps,
  required List<Evidence> recordedEvidence,
}) {
  return [
    for (final step in steps)
      InspectReviewRow(
        step: step,
        recordedAnswer: answerForTemplate(
          recordedEvidence: recordedEvidence,
          templateId: step.evidenceTemplateId,
        ),
      ),
  ];
}

String inspectReviewAnswerLabel(InspectReviewRow row) {
  if (!row.answered) {
    return 'Not recorded yet — still in Clues if you add it later';
  }
  return row.recordedAnswer!;
}
