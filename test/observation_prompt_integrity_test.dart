import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_batch_importer.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

/// Guards the interview against leaking template ids and generic yes/no
/// answers for categorical observations.
void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  EvidenceTemplate templateById(String id) {
    return package.evidenceTemplates.firstWhere((t) => t.id == id);
  }

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: templateById(templateId).promptText,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 7, 25),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('package prompt integrity', () {
    test('no template uses its id as the human prompt', () {
      final leaking = [
        for (final template in package.evidenceTemplates)
          if (template.promptText.trim().isEmpty ||
              template.promptText.trim() == template.id)
            template.id,
      ];
      expect(
        leaking,
        isEmpty,
        reason: 'These templates would render a raw slug as the question title',
      );
    });

    test('every template defines its own answer choices', () {
      final generic = [
        for (final template in package.evidenceTemplates)
          if (template.answerChoices.isEmpty) template.id,
      ];
      expect(
        generic,
        isEmpty,
        reason: 'These templates would fall back to generic Yes/No answers',
      );
    });

    test('gas-dryer-type offers fuel categories, not Yes/No', () {
      final choices = answerChoicesFor(templateById('gas-dryer-type'));
      expect(choices, contains('Yes, gas dryer'));
      expect(choices, contains('Electric dryer'));
      expect(choices, isNot(contains('Yes')));
      expect(choices, isNot(contains('No')));
      expect(choices, isNot(contains('Sometimes')));
      expect(choices, isNot(equals(observationAnswerChoices)));
    });

    test('effect-only stub infers categorical chips instead of Yes/No fallback', () {
      final stub = EvidenceTemplate(
        id: 'fuel-type-probe',
        promptText: 'fuel-type-probe',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const ['hint-only-mode'],
        supportByAnswer: const {
          'Yes, gas dryer': ['hint-only-mode'],
          'Electric dryer': ['hint-only-mode'],
        },
        excludeByAnswer: const {
          'Electric dryer': ['other-mode'],
        },
      );

      expect(usesGenericBooleanAnswerFallback(stub), isFalse);
      final choices = answerChoicesFor(stub);
      expect(choices, contains('Yes, gas dryer'));
      expect(choices, contains('Electric dryer'));
      expect(choices, contains('Not sure'));
      expect(choices, isNot(contains('Sometimes')));
      expect(choices, isNot(equals(observationAnswerChoices)));
    });

    test('observation prompts use plain language, not expert diagnosis phrasing', () {
      const forbidden = [
        'erratic',
        'steadily absent',
        'what failed',
        'behave erratically',
        'intermittent / comes and goes',
      ];
      for (final template in package.evidenceTemplates) {
        final lower = template.promptText.toLowerCase();
        for (final phrase in forbidden) {
          expect(
            lower,
            isNot(contains(phrase)),
            reason: '${template.id} prompt leaks expert phrasing: $phrase',
          );
        }
      }
    });

    test('relay-heat-output asks a human question', () {
      final template = templateById('relay-heat-output');
      expect(template.promptText, isNot('relay-heat-output'));
      expect(template.promptText, contains('heat cycle'));
      expect(observationPromptTitle(template), template.promptText);
    });
  });

  group('display title fallback', () {
    test('placeholder prompt falls back to a humanized label', () {
      final placeholder = EvidenceTemplate(
        id: 'gas-dryer-type',
        promptText: 'gas-dryer-type',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [],
      );
      expect(observationPromptTitle(placeholder), 'Is this dryer gas or electric?');
    });

    test('empty prompt falls back to a humanized label', () {
      final empty = EvidenceTemplate(
        id: 'relay-heat-output',
        promptText: '',
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [],
      );
      expect(observationPromptTitle(empty), 'Relay heat output');
    });

    test('authored prompt is never rewritten', () {
      final template = templateById('heat-observed');
      expect(observationPromptTitle(template), template.promptText);
    });
  });

  group('importer keeps authored prompts regardless of record order', () {
    const importer = FailureModeBatchImporter();

    /// Record that only references [templateId] through an answer hint, so the
    /// importer seeds a placeholder template before the prompt is authored.
    Map<String, dynamic> hintOnlyRecord(String templateId) {
      return {
        'schemaVersion': '1.0',
        'id': 'hint-only-mode',
        'title': 'Hint only mode',
        'applianceFamily': 'dryer',
        'symptomPhrasings': ['no heat'],
        'immediateCause': 'Cause',
        'rootCause': 'Root',
        'contributingFactors': ['Factor'],
        'evidenceSupports': [
          {'templateId': templateId, 'answer': 'Some answer'},
        ],
        'evidenceExcludes': [
          {'templateId': templateId, 'answer': 'Other answer'},
        ],
        'commonMisdiagnoses': ['Misdiagnosis'],
        'firstLineQuestions': const [],
        'verificationAsk': 'Ask?',
        'verificationWhy': 'Why',
        'verificationSteps': ['Step'],
        'safeGuidanceBoundary': ['Boundary'],
        'stopProfessionalConditions': ['Stop'],
        'preventionActions': ['Prevent'],
        'toolsRequired': ['None'],
        'difficultyNotes': 'Notes',
        'commonality': 'common',
        'safetyNotes': 'Safety',
      };
    }

    Map<String, dynamic> authoringRecord(String templateId) {
      return {
        ...hintOnlyRecord(templateId),
        'id': 'authoring-mode',
        'title': 'Authoring mode',
        'firstLineQuestions': [
          {
            'templateId': templateId,
            'promptText': 'Is this a gas dryer rather than an electric dryer?',
            'answerChoices': ['Yes, gas dryer', 'Electric dryer', 'Not sure'],
          },
        ],
      };
    }

    KnowledgePackage emptyBase() {
      return KnowledgePackage(
        id: 'dryer-core',
        category: 'dryer',
        version: '1.0',
        displayName: 'Test dryer package',
        schemaVersion: '1.0',
        failureModes: const [],
        symptoms: const [],
        evidenceTemplates: const [],
        safeChecks: const [],
        createdAt: DateTime.utc(2026, 7, 25),
        source: 'test-fixture',
        status: KnowledgePackageStatus.production,
      );
    }

    EvidenceTemplate importedTemplate(List<Map<String, dynamic>> records) {
      final result = importer.mergeIntoPackage(
        base: emptyBase(),
        records: importer.parseBatchJson(
          jsonEncode({'failureModes': records}),
        ),
        registerClosePaths: false,
      );
      return result.package.evidenceTemplates.firstWhere(
        (t) => t.id == 'fuel-type-probe',
      );
    }

    test('answer hint first, authored prompt second', () {
      final template = importedTemplate([
        hintOnlyRecord('fuel-type-probe'),
        authoringRecord('fuel-type-probe'),
      ]);
      expect(template.promptText, contains('gas dryer'));
      expect(template.answerChoices, contains('Electric dryer'));
      expect(template.relatedFailureModeIds, contains('hint-only-mode'));
      expect(template.relatedFailureModeIds, contains('authoring-mode'));
    });

    test('authored prompt first, answer hint second', () {
      final template = importedTemplate([
        authoringRecord('fuel-type-probe'),
        hintOnlyRecord('fuel-type-probe'),
      ]);
      expect(template.promptText, contains('gas dryer'));
      expect(template.answerChoices, contains('Electric dryer'));
    });

    test('answer hints still record support and exclude maps', () {
      final template = importedTemplate([
        hintOnlyRecord('fuel-type-probe'),
        authoringRecord('fuel-type-probe'),
      ]);
      expect(template.supportByAnswer['Some answer'], contains('hint-only-mode'));
      expect(template.excludeByAnswer['Other answer'], contains('hint-only-mode'));
    });

    test('placeholder detection only flags id-equal prompts', () {
      expect(
        isPlaceholderPromptText(
          EvidenceTemplate(
            id: 'gas-dryer-type',
            promptText: 'gas-dryer-type',
            expectedEvidenceType: EvidenceType.structuredAnswer,
            relatedFailureModeIds: const [],
          ),
        ),
        isTrue,
      );
      expect(
        isPlaceholderPromptText(
          EvidenceTemplate(
            id: 'gas-dryer-type',
            promptText: 'Is this a gas dryer?',
            expectedEvidenceType: EvidenceType.structuredAnswer,
            relatedFailureModeIds: const [],
          ),
        ),
        isFalse,
      );
    });
  });

  group('fuel type constrains the no-heat ranking', () {
    const ranking = RankingService();

    final beginnerNoHeat = [
      evidence(templateId: 'drum-turns', answer: 'Turns normally'),
      evidence(templateId: 'heat-observed', answer: 'No warmth'),
      evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
      evidence(
        templateId: 'wall-plug-seated',
        answer: 'Fully seated, looks normal',
      ),
    ];

    test('electric-only modes are weakened on a gas dryer', () {
      final snapshot = ranking.evaluate(
        package: package,
        evidence: [
          ...beginnerNoHeat,
          evidence(templateId: 'gas-dryer-type', answer: 'Yes, gas dryer'),
        ],
      );
      for (final modeId in const [
        'heating-element-failed',
        'relay-or-control-no-heat-output',
        'missing-leg-240v-supply',
        'loose-power-cord-connection-electric',
      ]) {
        expect(
          snapshot.standings[modeId]!.excludeCount,
          greaterThan(0),
          reason: '$modeId is electric-only and must be excluded on gas',
        );
      }
    });

    test('gas answer does not let an electric mode lead', () {
      final snapshot = ranking.evaluate(
        package: package,
        evidence: [
          ...beginnerNoHeat,
          evidence(templateId: 'gas-dryer-type', answer: 'Yes, gas dryer'),
          evidence(
            templateId: 'gas-ignition-observed',
            answer: 'No flame / no ignition',
          ),
        ],
      );
      final gasNet =
          snapshot.standings['gas-dryer-no-ignition-professional-only']!.net;
      for (final modeId in const [
        'heating-element-failed',
        'relay-or-control-no-heat-output',
        'missing-leg-240v-supply',
      ]) {
        expect(
          snapshot.standings[modeId]!.net,
          lessThan(gasNet),
          reason: '$modeId must not outrank the gas ignition mode',
        );
      }
    });

    test('electric answer still leaves electric modes available', () {
      final snapshot = ranking.evaluate(
        package: package,
        evidence: [
          ...beginnerNoHeat,
          evidence(templateId: 'gas-dryer-type', answer: 'Electric dryer'),
        ],
      );
      expect(
        snapshot.standings['gas-dryer-no-ignition-professional-only']!
            .excludeCount,
        greaterThan(0),
      );
      expect(
        snapshot.standings['heating-element-failed']!.isSupported,
        isTrue,
      );
    });

    test('fuel type is offered before the interview runs out', () {
      final snapshot = ranking.evaluate(
        package: package,
        evidence: beginnerNoHeat,
      );
      expect(snapshot.standings, isNotEmpty);
      final unanswered = unusedTemplates(
        templates: package.evidenceTemplates,
        recordedEvidence: beginnerNoHeat,
      ).map((t) => t.id);
      expect(unanswered, contains('gas-dryer-type'));
    });
  });

  group('no-heat session never shows a slug', () {
    testWidgets('beginner no-heat path renders human questions only', (
      tester,
    ) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 25, 12),
      );
      await openDryerSession(tester, dependencies, 'Slug Guard Household');

      const answers = <String, String>{
        'heat-observed': 'No warmth',
        'cycle-heat-setting': 'Yes, heat cycle',
        'drum-turns': 'Turns normally',
        'wall-plug-seated': 'Fully seated, looks normal',
        'gas-dryer-type': 'Electric dryer',
        'relay-heat-output': 'No heat despite heat cycle and tumble',
      };

      for (final entry in answers.entries) {
        await selectObservation(tester, entry.key);
        expect(
          find.text(entry.key),
          findsNothing,
          reason: 'Template id ${entry.key} leaked as visible text',
        );
        expect(
          find.text(observationPromptTitle(templateById(entry.key))),
          findsOneWidget,
          reason: 'Human prompt missing for ${entry.key}',
        );
        await tapVisible(
          tester,
          find.byKey(Key('answer-choice-${answerChoiceKeySuffix(entry.value)}')),
        );
      }

      expect(tester.takeException(), isNull);

      for (final template in package.evidenceTemplates) {
        expect(
          find.text(template.id),
          findsNothing,
          reason: 'Template id ${template.id} leaked as visible text',
        );
      }
    });

    testWidgets('closing a no-heat session explains what is still possible', (
      tester,
    ) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 25, 12),
      );
      await openDryerSession(tester, dependencies, 'Closure Household');

      const answers = <String, String>{
        'heat-observed': 'No warmth',
        'cycle-heat-setting': 'Yes, heat cycle',
        'drum-turns': 'Turns normally',
        'wall-plug-seated': 'Fully seated, looks normal',
        'gas-dryer-type': 'Electric dryer',
      };
      for (final entry in answers.entries) {
        await selectObservation(tester, entry.key);
        await tapVisible(
          tester,
          find.byKey(Key('answer-choice-${answerChoiceKeySuffix(entry.value)}')),
        );
      }

      await selectFailureMode(tester, 'heating-element-failed');

      expect(
        find.byKey(const Key('remaining-likely-modes-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('remaining-likely-modes-reason')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('remaining-likely-mode-heating-element-failed')),
        findsNothing,
        reason: 'The accepted primary must not repeat in the remaining list',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('categorical observation renders no Yes/No buttons', (
      tester,
    ) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 25, 12),
      );
      await openDryerSession(tester, dependencies, 'Fuel Choice Household');

      await selectObservation(tester, 'gas-dryer-type');

      expect(
        find.byKey(const Key('answer-choice-yes-gas-dryer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('answer-choice-electric-dryer')),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Yes'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'No'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Sometimes'), findsNothing);
    });
  });
}
