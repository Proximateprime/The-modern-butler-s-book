import 'dishwasher_easy_checks.dart';
import 'dryer_start_easy_checks.dart';
import 'easy_airflow_checks.dart';
import 'fridge_easy_checks.dart';
import 'washer_easy_checks.dart';

/// Presentation-only: mark an easy check as already done.
///
/// Does not change ranking. Does not auto-skip from maintenance dates.
const String alreadyCheckedEasyCheckAnswer = 'Already checked';

/// Guidance-step label for the same mark.
const String alreadyDidThisEasyCheckLabel = 'I already did this';

/// Dryer airflow, washer door/filter, dishwasher door/filter/hose.
const Set<String> easyCheckObservationTemplateIds = {
  'lint-filter-condition',
  'exterior-airflow',
  'vent-hose-condition',
  ...dryerStartEasyCheckTemplateIds,
  ...washerEasyCheckTemplateIds,
  ...dishwasherEasyCheckTemplateIds,
  ...fridgeEasyCheckTemplateIds,
};

bool isEasyCheckObservationTemplateId(String? templateId) {
  return templateId != null &&
      easyCheckObservationTemplateIds.contains(templateId);
}

bool isEasyCheckGuidanceStep(String step) {
  return isEasyAirflowCheckStep(step) ||
      isDryerStartEasyCheckStep(step) ||
      isWasherEasyCheckStep(step) ||
      isDishwasherEasyCheckStep(step) ||
      isFridgeEasyCheckStep(step);
}

/// Inserts **Already checked** before Not sure / Other, if this is an easy check.
List<String> withAlreadyCheckedEasyCheckChoice({
  required String templateId,
  required List<String> choices,
}) {
  if (!isEasyCheckObservationTemplateId(templateId)) {
    return choices;
  }
  if (choices.contains(alreadyCheckedEasyCheckAnswer)) {
    return choices;
  }
  final next = List<String>.from(choices);
  final notSure = next.indexOf('Not sure');
  if (notSure >= 0) {
    next.insert(notSure, alreadyCheckedEasyCheckAnswer);
    return next;
  }
  final other = next.indexOf('Other / describe');
  if (other >= 0) {
    next.insert(other, alreadyCheckedEasyCheckAnswer);
    return next;
  }
  next.add(alreadyCheckedEasyCheckAnswer);
  return next;
}
