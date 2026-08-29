import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/investigation_stop.dart';
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
      relatedFailureModeIds: const ['fm-1'],
    ),
    EvidenceTemplate(
      id: 'c',
      promptText: 'Prompt C',
      expectedEvidenceType: EvidenceType.textObservation,
      relatedFailureModeIds: const ['fm-2'],
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

  test('continues without primary while unused templates remain', () {
    final stop = shouldStopInvestigation(
      templates: templates,
      recordedEvidence: [evidence('Prompt A')],
    );

    expect(stop, isFalse);
  });

  test('stops immediately once a primary hypothesis is selected', () {
    final stop = shouldStopInvestigation(
      templates: templates,
      recordedEvidence: [evidence('Prompt A')],
      primaryFailureModeId: 'fm-1',
    );

    expect(stop, isTrue);
  });

  test('stops when no unused templates remain', () {
    final stop = shouldStopInvestigation(
      templates: templates,
      recordedEvidence: [
        evidence('Prompt A'),
        evidence('Prompt B'),
        evidence('Prompt C'),
      ],
    );

    expect(stop, isTrue);
  });

  test('verification returns first unused related template', () {
    final prompt = suggestVerificationObservation(
      templates: templates,
      recordedEvidence: [evidence('Prompt A')],
      primaryFailureModeId: 'fm-1',
    );

    expect(prompt?.id, 'b');
  });
}
