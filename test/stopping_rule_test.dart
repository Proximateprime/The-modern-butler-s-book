import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/investigation_stop.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  EvidenceTemplate template(String id) {
    return EvidenceTemplate(
      id: id,
      promptText: 'Prompt $id',
      expectedEvidenceType: EvidenceType.textObservation,
      relatedFailureModeIds: const ['fm-1'],
    );
  }

  Evidence answered(String id) {
    return Evidence(
      id: 'e-$id',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.textObservation,
      observation: 'Prompt $id',
      answer: 'Yes',
      templateId: id,
      collectedAt: DateTime.utc(2026, 8, 17),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  final templates = [template('a'), template('b'), template('c')];

  test('safety hard-stop does not ask another question', () {
    final rule = stoppingRule(
      safetyStop: const SafetyStop(reason: 'Possible fire or smoke hazard'),
      templates: templates,
      recordedEvidence: [answered('a')],
    );

    expect(rule.askAnotherQuestion, isFalse);
    expect(rule.showDiagnosis, isTrue);
    expect(rule.safetyHardStop, isTrue);
  });

  test('asks while unused templates remain, under cap, no skip, no primary', () {
    final rule = stoppingRule(
      templates: templates,
      recordedEvidence: [answered('a')],
    );

    expect(rule.askAnotherQuestion, isTrue);
    expect(rule.showDiagnosis, isFalse);
    expect(rule.safetyHardStop, isFalse);
  });

  test('skip to best guess stops asking and shows diagnosis', () {
    final rule = stoppingRule(
      templates: templates,
      recordedEvidence: [answered('a')],
      skipToBestGuess: true,
    );

    expect(rule.askAnotherQuestion, isFalse);
    expect(rule.showDiagnosis, isTrue);
    expect(rule.safetyHardStop, isFalse);
  });

  test('soft cap of eight meaningful answers stops asking', () {
    final manyTemplates = [
      for (var i = 0; i < 9; i++) template('t$i'),
    ];
    final eightAnswers = [
      for (var i = 0; i < 8; i++) answered('t$i'),
    ];

    expect(
      shouldStopInvestigation(
        templates: manyTemplates,
        recordedEvidence: eightAnswers,
      ),
      isFalse,
    );

    final rule = stoppingRule(
      templates: manyTemplates,
      recordedEvidence: eightAnswers,
    );

    expect(rule.askAnotherQuestion, isFalse);
    expect(rule.showDiagnosis, isTrue);
    expect(rule.safetyHardStop, isFalse);
  });

  test(
    'existing recommend-primary id shows diagnosis and still asks',
    () {
      final rule = stoppingRule(
        templates: templates,
        recordedEvidence: [answered('a')],
        recommendPrimaryFailureModeId: 'fm-1',
      );

      expect(rule.askAnotherQuestion, isTrue);
      expect(rule.showDiagnosis, isTrue);
      expect(rule.safetyHardStop, isFalse);
    },
  );

  test('primary selected stops asking via existing investigation stop', () {
    final rule = stoppingRule(
      templates: templates,
      recordedEvidence: [answered('a')],
      primaryFailureModeId: 'fm-1',
    );

    expect(
      shouldStopInvestigation(
        templates: templates,
        recordedEvidence: [answered('a')],
        primaryFailureModeId: 'fm-1',
      ),
      isTrue,
    );
    expect(rule.askAnotherQuestion, isFalse);
    expect(rule.showDiagnosis, isTrue);
    expect(rule.safetyHardStop, isFalse);
  });

  test('resume JSON round-trips skipToBestGuess', () {
    const resume = SessionUiResumeState(
      starterConfirmed: true,
      skipToBestGuess: true,
    );
    final restored = SessionUiResumeState.fromJson(resume.toJson());
    expect(restored.skipToBestGuess, isTrue);
    expect(restored.starterConfirmed, isTrue);
  });

  testWidgets(
    'skip to best guess shows diagnosis and hides the current question',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 17, 11),
      );
      await openDryerSession(tester, dependencies, 'Stopping Rule House');

      expect(find.text('Current question'), findsOneWidget);
      expect(find.byKey(const Key('skip-to-best-guess')), findsOneWidget);
      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('skip-to-best-guess')));

      expect(find.text('Current question'), findsNothing);
      expect(find.byKey(const Key('skip-to-best-guess')), findsNothing);
      expect(find.byKey(const Key('recommended-primary-card')), findsOneWidget);
      expect(find.byKey(const Key('observation-paused-message')), findsNothing);
      expect(find.byKey(const Key('primary-hypothesis-banner')), findsNothing);
      expect(
        find.text('This is the current best guess from your answers.'),
        findsOneWidget,
      );
    },
  );
}
