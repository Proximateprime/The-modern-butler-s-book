import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/observation_prompt_quality.dart';
import 'package:modern_butlers_book/helpers/power_steering.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

Evidence _evidence({
  required String templateId,
  required String answer,
}) {
  return Evidence(
    id: 'evidence-$templateId',
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: templateId,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 7, 26),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  test('power fine + machine runs de-emphasizes dead-supply modes', () {
    final evidence = [
      _evidence(templateId: 'panel-lights', answer: 'Yes, panel responds'),
      _evidence(templateId: 'dryer-response', answer: 'Starts normally'),
      _evidence(templateId: 'drum-turns', answer: 'Turns normally'),
      _evidence(templateId: 'heat-observed', answer: 'No warmth'),
    ];

    expect(shouldDeemphasizeDeadPowerModes(evidence), isTrue);

    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: evidence,
    );

    expect(standings['no-power-at-outlet']!.isWeakened, isTrue);
    expect(standings['missing-leg-240v-supply']!.isWeakened, isTrue);
    expect(standings['heating-element-failed']!.isSupported, isTrue);
  });

  test('dead-supply interview templates are deprioritized when power is fine', () {
    final evidence = [
      _evidence(templateId: 'panel-lights', answer: 'Yes, panel responds'),
      _evidence(templateId: 'drum-turns', answer: 'Turns normally'),
      _evidence(templateId: 'heat-observed', answer: 'No warmth'),
    ];
    final templates = package.evidenceTemplates;
    final activeFamilies = inferActiveObservationFamilies(
      recordedEvidence: evidence,
      templates: templates,
    );

    final panelTemplate = templates.firstWhere((t) => t.id == 'panel-lights');
    final panelScore = scoreObservationPrompt(
      template: panelTemplate,
      activeFamilies: activeFamilies,
      topFailureModeIds: const [],
      recordedCount: evidence.length,
      packageIndex: 0,
      recordedEvidence: evidence,
    );
    final heatScore = scoreObservationPrompt(
      template: templates.firstWhere((t) => t.id == 'heat-observed'),
      activeFamilies: activeFamilies,
      topFailureModeIds: const [],
      recordedCount: evidence.length,
      packageIndex: 0,
      recordedEvidence: evidence,
    );

    expect(panelScore, lessThan(heatScore));
  });
}
