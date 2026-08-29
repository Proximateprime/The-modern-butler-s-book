import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_batch_01.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_record.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_batch_importer.dart';
import 'package:modern_butlers_book/knowledge_factory/golden_examples.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  setUp(clearImportedClosePaths);

  group('FailureModeAuthoringRecord template validity', () {
    test('golden example validates and round-trips JSON', () {
      const importer = FailureModeBatchImporter();
      final records = importer.parseBatchJson(
        dryerThermalFuseRestrictedVentGoldenJson,
      );
      expect(records, hasLength(1));
      final record = records.single;
      expect(record.id, 'thermal-fuse-open');
      expect(record.immediateCause, isNotEmpty);
      expect(record.rootCause, contains('restricted'));
      expect(record.preventionActions, isNotEmpty);
      expect(record.commonMisdiagnoses, isNotEmpty);
      expect(record.safeGuidanceBoundary, isNotEmpty);
      expect(record.stopProfessionalConditions, isNotEmpty);

      final again = FailureModeAuthoringRecord.fromJson(record.toJson());
      expect(again.id, record.id);
      expect(again.rootCause, record.rootCause);
      expect(again.evidenceSupports.length, record.evidenceSupports.length);
    });

    test('data file stays aligned with embedded golden JSON', () {
      final file = File(
        'lib/knowledge_factory/data/dryer_thermal_fuse_restricted_vent.v1.json',
      );
      expect(file.existsSync(), isTrue);
      const importer = FailureModeBatchImporter();
      final fromFile = importer.parseBatchJson(file.readAsStringSync()).single;
      final fromEmbedded =
          importer.parseBatchJson(dryerThermalFuseRestrictedVentGoldenJson)
              .single;
      expect(fromFile.toJson(), fromEmbedded.toJson());
    });

    test('rejects records missing safety boundaries', () {
      expect(
        () => validateFailureModeAuthoringRecord(
          FailureModeAuthoringRecord(
            id: 'bad-mode',
            title: 'Bad',
            applianceFamily: 'dryer',
            symptomPhrasings: const ['x'],
            immediateCause: 'cause',
            rootCause: 'root',
            contributingFactors: const [],
            evidenceSupports: const [],
            evidenceExcludes: const [],
            commonMisdiagnoses: const ['mis'],
            firstLineQuestions: const [],
            verificationAsk: 'ask?',
            verificationWhy: 'why',
            verificationSteps: const [],
            safeGuidanceBoundary: const [],
            stopProfessionalConditions: const [],
            preventionActions: const ['clean lint'],
            toolsRequired: const [],
            difficultyNotes: '',
            commonality: 'common',
            safetyNotes: '',
          ),
        ),
        throwsA(isA<AuthoringValidationException>()),
      );
    });
  });

  group('FailureModeBatchImporter', () {
    test('merges Batch 01+02 into dryer package (41 modes)', () {
      final package =
          KnowledgePackageRepository().loadById('dryer-core')!;
      expect(package.failureModes, hasLength(41));
      expect(package.symptoms, hasLength(8));
      expect(package.version, '1.4.2');
      expect(
        package.evidenceTemplates.map((t) => t.id),
        containsAll([
          'heat-observed',
          'heat-pattern',
          'control-lock-status',
          'outlet-power-check',
          'odor-type',
          'load-size-wetness',
          'gas-dryer-type',
          'breaker-tripped-check',
          'lint-housing-slot',
          'noise-timing',
          'heat-before-failure',
          'door-held-closed-start',
        ]),
      );
      expect(
        package.evidenceTemplates
            .firstWhere((t) => t.id == 'control-lock-status')
            .promptText
            .toLowerCase(),
        contains('lock icon'),
      );

      final thermal = package.failureModes.firstWhere(
        (mode) => mode.id == 'thermal-fuse-open',
      );
      expect(thermal.safetyNotes.toLowerCase(), contains('bypass'));
      expect(
        closePathForFailureMode('thermal-fuse-open')?.safeGuidanceSteps.first
            .toLowerCase(),
        contains('lint filter'),
      );
      expect(
        package.failureModes.map((m) => m.id),
        containsAll([
          'air-fluff-cycle-selected',
          'electrical-burning-smell-hazard',
          'dusty-lint-smell',
          'blower-wheel-obstruction',
          'gas-dryer-no-ignition-professional-only',
          'start-capacitor-or-start-assist-weak',
        ]),
      );
    });

    test('Batch 02 JSON data file validates all 20 modes', () {
      final file = File('lib/knowledge_factory/data/dryer_batch_02.v1.json');
      expect(file.existsSync(), isTrue);
      const importer = FailureModeBatchImporter();
      final fromFile = importer.parseBatchJson(file.readAsStringSync());
      expect(fromFile, hasLength(20));
      for (final record in fromFile) {
        expect(record.evidenceSupports, isNotEmpty);
        expect(record.evidenceExcludes, isNotEmpty);
      }
    });

    test('Batch 01 JSON data file validates all 20 modes', () {
      final file = File('lib/knowledge_factory/data/dryer_batch_01.v1.json');
      expect(file.existsSync(), isTrue);
      const importer = FailureModeBatchImporter();
      final fromFile = importer.parseBatchJson(file.readAsStringSync());
      final fromEmbedded = importer.parseBatchJson(dryerBatch01Json);
      expect(fromFile, hasLength(20));
      expect(fromEmbedded, hasLength(20));
      expect(
        fromFile.map((r) => r.id).toList(),
        fromEmbedded.map((r) => r.id).toList(),
      );
      for (final record in fromFile) {
        expect(record.evidenceSupports, isNotEmpty);
        expect(record.evidenceExcludes, isNotEmpty);
        expect(record.verificationSteps, isNotEmpty);
        expect(record.commonMisdiagnoses, isNotEmpty);
        expect(record.safeGuidanceBoundary, isNotEmpty);
        expect(record.stopProfessionalConditions, isNotEmpty);
      }
    });

    test('can import an additional mode via batch JSON', () {
      clearImportedClosePaths();
      final repo = KnowledgePackageRepository();
      const batch = '''
{
  "id": "factory-demo-mode",
  "title": "Factory demo mode",
  "applianceFamily": "dryer",
  "symptomPhrasings": ["demo symptom"],
  "immediateCause": "A demo immediate cause for import testing.",
  "rootCause": "A demo root cause used only in unit tests.",
  "contributingFactors": ["Test factor"],
  "evidenceSupports": [
    { "templateId": "heat-observed", "answer": "No warmth" }
  ],
  "evidenceExcludes": [
    { "templateId": "heat-observed", "answer": "Normal heat" }
  ],
  "commonMisdiagnoses": ["Wrong demo diagnosis"],
  "firstLineQuestions": [],
  "verificationAsk": "Did the demo check pass?",
  "verificationWhy": "Confirms the import registered a close path.",
  "verificationSteps": ["Observe demo outcome"],
  "safeGuidanceBoundary": ["Do not open live circuits for this demo mode"],
  "stopProfessionalConditions": ["Any electrical probing required"],
  "preventionActions": ["Keep lint filter clean"],
  "toolsRequired": ["None"],
  "difficultyNotes": "Test-only mode",
  "commonality": "moderate",
  "safetyNotes": "Demo mode — escalate rather than DIY electrical work."
}
''';
      final result = repo.importFailureModeBatchJson(
        packageId: 'dryer-core',
        rawJson: batch,
      );
      expect(result.addedModeIds, ['factory-demo-mode']);
      expect(repo.loadById('dryer-core')!.failureModes, hasLength(42));
      expect(
        closePathForFailureMode('factory-demo-mode')?.verificationAsk,
        'Did the demo check pass?',
      );
      expect(
        closePathForFailureMode('factory-demo-mode')!.allowResolvedWhenConfirmed,
        isFalse,
      );
      final heat = repo
          .loadById('dryer-core')!
          .evidenceTemplates
          .firstWhere((t) => t.id == 'heat-observed');
      expect(heat.supportByAnswer['No warmth'], contains('factory-demo-mode'));
    });
  });
}
