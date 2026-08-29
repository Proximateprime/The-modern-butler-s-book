import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/models/repair_session.dart';

void main() {
  final templates = [
    EvidenceTemplate(
      id: 'a',
      promptText: 'Prompt A',
      expectedEvidenceType: EvidenceType.textObservation,
      relatedFailureModeIds: const ['fm-1'],
    ),
    EvidenceTemplate(
      id: 'b',
      promptText: 'Prompt B',
      expectedEvidenceType: EvidenceType.textObservation,
      relatedFailureModeIds: const ['fm-2'],
    ),
    EvidenceTemplate(
      id: 'c',
      promptText: 'Prompt C',
      expectedEvidenceType: EvidenceType.textObservation,
      relatedFailureModeIds: const ['fm-1', 'fm-3'],
    ),
  ];

  Evidence evidence(String observation) {
    return Evidence(
      id: 'e-$observation',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.textObservation,
      observation: observation,
      collectedAt: DateTime.utc(2026, 7, 22),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  test('falls back to first unused template in package order', () {
    final suggestion = suggestNextObservation(
      templates: templates,
      recordedEvidence: const [],
    );

    expect(suggestion?.id, 'a');
  });

  test('prefers unused template related to primary hypothesis', () {
    final suggestion = suggestNextObservation(
      templates: templates,
      recordedEvidence: [evidence('Prompt A')],
      primaryFailureModeId: 'fm-1',
    );

    expect(suggestion?.id, 'c');
  });

  test('prefers unused template related to evidence-matched failure modes', () {
    final suggestion = suggestNextObservation(
      templates: templates,
      recordedEvidence: [evidence('Prompt A')],
      evidenceMatchedFailureModeIds: const {'fm-2'},
    );

    expect(suggestion?.id, 'b');
  });

  test('prefers unused template with best overlap on top modes', () {
    final suggestion = suggestNextObservation(
      templates: templates,
      recordedEvidence: [evidence('Prompt A')],
      topFailureModeIds: const ['fm-1', 'fm-3'],
    );

    expect(suggestion?.id, 'c');
  });

  test('returns null when every template is already recorded', () {
    final suggestion = suggestNextObservation(
      templates: templates,
      recordedEvidence: [
        evidence('Prompt A'),
        evidence('Prompt B'),
        evidence('Prompt C'),
      ],
      primaryFailureModeId: 'fm-1',
    );

    expect(suggestion, isNull);
  });
}
