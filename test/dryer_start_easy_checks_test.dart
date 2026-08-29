import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_start_easy_checks.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-$answer',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: answer,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 8, 20),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  test('won\'t-start easy checks start at door click, not airflow', () {
    final recorded = [
      evidence(templateId: 'dryer-response', answer: 'Nothing happens'),
    ];
    expect(
      shouldPrioritizeDryerStartEasyChecks(
        recordedEvidence: recorded,
        starterMatchedSymptomIds: {'will-not-start'},
      ),
      isTrue,
    );
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        starterMatchedSymptomIds: {'will-not-start'},
      )?.id,
      'door-closed-firmly',
    );
  });

  test('no-tumble easy check is listen for the motor', () {
    final recorded = [
      evidence(templateId: 'drum-turns', answer: 'Motor runs, drum still'),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        starterMatchedSymptomIds: {'motor-runs-drum-still'},
      )?.id,
      'motor-audible',
    );
  });

  test('start easy-check templates include Already checked', () {
    final choices = withAlreadyCheckedEasyCheckChoice(
      templateId: 'door-closed-firmly',
      choices: const [
        'Clicks shut firmly',
        'Soft close / no click',
        'Not sure',
        'Other / describe',
      ],
    );
    expect(choices, contains(alreadyCheckedEasyCheckAnswer));
    expect(
      choices.indexOf(alreadyCheckedEasyCheckAnswer),
      lessThan(choices.indexOf('Not sure')),
    );
  });

  test('door-click guidance counts as an already-did-this easy check', () {
    expect(
      isDryerStartEasyCheckStep(
        'Close the door firmly until you feel/hear a solid click.',
      ),
      isTrue,
    );
  });
}
