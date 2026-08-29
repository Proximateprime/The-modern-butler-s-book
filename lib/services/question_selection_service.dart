import '../helpers/package_authoring_index.dart';
import '../helpers/suggest_next_observation.dart';
import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';

/// Thin deterministic boundary for next-question selection.
///
/// Wraps [suggestNextObservation]. No ranking mutation, persistence, or LLM.
class QuestionSelectionService {
  const QuestionSelectionService();

  /// Picks one unused template using the existing preference order.
  EvidenceTemplate? suggestNext({
    required List<EvidenceTemplate> templates,
    required List<Evidence> recordedEvidence,
    String? primaryFailureModeId,
    Set<String> evidenceMatchedFailureModeIds = const {},
    List<String> topFailureModeIds = const [],
    PackageAuthoringIndex? authoringIndex,
    Set<String> starterMatchedSymptomIds = const {},
    ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
  }) {
    return suggestNextObservation(
      templates: templates,
      recordedEvidence: recordedEvidence,
      primaryFailureModeId: primaryFailureModeId,
      evidenceMatchedFailureModeIds: evidenceMatchedFailureModeIds,
      topFailureModeIds: topFailureModeIds,
      authoringIndex: authoringIndex,
      starterMatchedSymptomIds: starterMatchedSymptomIds,
      energySource: energySource,
    );
  }
}
