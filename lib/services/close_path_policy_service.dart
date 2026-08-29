import '../helpers/dryer_close_path.dart';
import '../models/evidence.dart';

export '../helpers/dryer_close_path.dart'
    show
        CloseResolveEligibility,
        FailureModeClosePath,
        VerificationOutcome,
        closeVerificationChoices,
        closeVerificationTemplateId;

/// Thin deterministic boundary for Primary close-path / verification policy.
///
/// Wraps dryer close-path helpers. Beginner-safe content only; no LLM.
class ClosePathPolicyService {
  const ClosePathPolicyService();

  FailureModeClosePath? pathForFailureMode(String failureModeId) {
    return closePathForFailureMode(failureModeId);
  }

  Evidence? findVerificationEvidence({
    required List<Evidence> evidence,
    required String failureModeId,
  }) {
    return findCloseVerificationEvidence(
      evidence: evidence,
      failureModeId: failureModeId,
    );
  }

  VerificationOutcome outcomeFromAnswer(String? answer) {
    return verificationOutcomeFromCloseAnswer(answer);
  }

  VerificationOutcome outcomeForPrimary({
    required List<Evidence> evidence,
    required String? primaryFailureModeId,
  }) {
    if (primaryFailureModeId == null) {
      return VerificationOutcome.notApplicable;
    }
    final closeEvidence = findVerificationEvidence(
      evidence: evidence,
      failureModeId: primaryFailureModeId,
    );
    if (closeEvidence == null) {
      return VerificationOutcome.pending;
    }
    return outcomeFromAnswer(closeEvidence.answer);
  }

  CloseResolveEligibility resolveEligibility({
    required bool safetyStopActive,
    required String? primaryFailureModeId,
    required VerificationOutcome verificationOutcome,
    FailureModeClosePath? closePath,
  }) {
    return closeResolveEligibility(
      safetyStopActive: safetyStopActive,
      primaryFailureModeId: primaryFailureModeId,
      verificationOutcome: verificationOutcome,
      closePath: closePath,
    );
  }
}
