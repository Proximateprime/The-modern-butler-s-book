import '../helpers/safety_stop.dart';
import '../models/decision_context.dart';
import '../models/evidence.dart';

export '../helpers/safety_stop.dart' show SafetyStop;

/// Thin deterministic boundary for the session safety hard-stop gate.
///
/// Wraps [evaluateSafetyStop]. Not a Safety Engine — checklist only.
class SafetyDecisionService {
  const SafetyDecisionService();

  SafetyStop? evaluate({
    required List<Evidence> evidence,
    String? primaryFailureModeId,
  }) {
    return evaluateSafetyStop(
      evidence: evidence,
      primaryFailureModeId: primaryFailureModeId,
    );
  }

  /// Same gate as [evaluate], using one session [DecisionContext].
  SafetyStop? evaluateContext(DecisionContext context) {
    return evaluate(
      evidence: context.evidence,
      primaryFailureModeId: context.primaryFailureModeId,
    );
  }
}
