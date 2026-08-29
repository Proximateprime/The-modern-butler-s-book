import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'evidence_prompt_match.dart';
import 'observation_prompt_quality.dart';

/// Package template that records electric vs gas vs not sure.
const String gasDryerTypeTemplateId = 'gas-dryer-type';

/// Household-facing fuel question. Must be asked before heat-component guidance
/// when energy source is unknown.
const String gasDryerTypeHouseholdPrompt = 'Is this dryer gas or electric?';

/// Interview answers authored on [gasDryerTypeTemplateId].
const String gasDryerTypeGasAnswer = 'Yes, gas dryer';
const String gasDryerTypeElectricAnswer = 'Electric dryer';

/// Maps appliance energy onto the package fuel-type answer, or null if unknown.
String? gasDryerTypeAnswerFor(ApplianceEnergySource source) {
  return switch (source) {
    ApplianceEnergySource.electric => gasDryerTypeElectricAnswer,
    ApplianceEnergySource.gas => gasDryerTypeGasAnswer,
    ApplianceEnergySource.unknown => null,
  };
}

/// Inverse of [gasDryerTypeAnswerFor]. Null when the answer is not a firm fuel.
ApplianceEnergySource? energySourceFromGasDryerTypeAnswer(String? answer) {
  final key = normalizeObservationAnswer(answer);
  if (key == gasDryerTypeElectricAnswer) {
    return ApplianceEnergySource.electric;
  }
  if (key == gasDryerTypeGasAnswer) {
    return ApplianceEnergySource.gas;
  }
  return null;
}

/// True when recorded answers show a gas dryer.
bool isGasDryerFromEvidence(List<Evidence> evidence) {
  return normalizeObservationAnswer(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: gasDryerTypeTemplateId,
        ),
      ) ==
      gasDryerTypeGasAnswer;
}

/// No heat, weak heat. Burning smell is a safety stop, not a fuel question.
bool dryerStarterIsHeatRelated(Set<String> starterMatchedSymptomIds) {
  return starterMatchedSymptomIds.contains('no-heat') ||
      starterMatchedSymptomIds.contains('clothes-hot-but-damp');
}

/// Unknown energy + heat complaint: ask fuel before element / fuse-as-element.
bool dryerNeedsFuelQuestionBeforeHeatComponents({
  required ApplianceEnergySource energySource,
  required List<Evidence> recordedEvidence,
  required List<EvidenceTemplate> templates,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  if (energySource != ApplianceEnergySource.unknown) {
    return false;
  }
  var hasTemplate = false;
  for (final template in templates) {
    if (template.id == gasDryerTypeTemplateId) {
      hasTemplate = true;
      break;
    }
  }
  if (!hasTemplate) {
    return false;
  }
  if (isTemplateRecordedId(
    templateId: gasDryerTypeTemplateId,
    recordedEvidence: recordedEvidence,
  )) {
    return false;
  }
  if (dryerStarterIsHeatRelated(starterMatchedSymptomIds)) {
    return true;
  }
  return inferHeatPathPolarity(
        recordedEvidence: recordedEvidence,
        starterMatchedSymptomIds: starterMatchedSymptomIds,
      ) ==
      HeatPathPolarity.noHeat;
}

EvidenceTemplate? gasDryerTypeTemplate(List<EvidenceTemplate> templates) {
  for (final template in templates) {
    if (template.id == gasDryerTypeTemplateId) {
      return template;
    }
  }
  return null;
}

bool isTemplateRecordedId({
  required String templateId,
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId == templateId) {
      return true;
    }
  }
  return false;
}

/// Electric heating-generation modes. Not the primary path on a gas dryer.
const Set<String> electricHeatGenerationModeIds = {
  'heating-element-failed',
  'relay-or-control-no-heat-output',
  'missing-leg-240v-supply',
  'loose-power-cord-connection-electric',
  'thermal-fuse-open',
};

String applianceEnergySourceLabel(ApplianceEnergySource source) {
  return switch (source) {
    ApplianceEnergySource.electric => 'Electric',
    ApplianceEnergySource.gas => 'Gas',
    ApplianceEnergySource.unknown => 'Not sure',
  };
}
