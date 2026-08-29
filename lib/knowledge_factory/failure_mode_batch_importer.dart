import 'dart:convert';

import '../helpers/dryer_close_path.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_batch_01.dart';
import 'dryer_batch_02.dart';
import 'failure_mode_authoring_record.dart';
import 'golden_examples.dart';

/// Result of merging authoring records into a [KnowledgePackage].
class FailureModeBatchImportResult {
  const FailureModeBatchImportResult({
    required this.package,
    required this.importedIds,
    required this.addedModeIds,
    required this.updatedModeIds,
  });

  final KnowledgePackage package;
  final List<String> importedIds;
  final List<String> addedModeIds;
  final List<String> updatedModeIds;
}

/// Deterministic Knowledge Factory importer for dryer failure-mode batches.
///
/// Merges authoring records into package failure modes, symptoms, evidence
/// support/exclude maps, optional first-line templates, and close-path overlays.
/// No LLM. Does not invent confidence scores.
class FailureModeBatchImporter {
  const FailureModeBatchImporter();

  /// Parses and validates a JSON array or `{ "failureModes": [...] }` document.
  List<FailureModeAuthoringRecord> parseBatchJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded['failureModes'] is List) {
      items = List<dynamic>.from(decoded['failureModes'] as List);
    } else if (decoded is Map) {
      items = [decoded];
    } else {
      throw const FormatException(
        'Batch JSON must be an object, an array, or { "failureModes": [...] }.',
      );
    }

    final records = <FailureModeAuthoringRecord>[];
    for (final item in items) {
      final record = FailureModeAuthoringRecord.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      validateFailureModeAuthoringRecord(record);
      records.add(record);
    }
    return records;
  }

  /// Merges [records] into [base]. Existing mode ids are updated in place.
  FailureModeBatchImportResult mergeIntoPackage({
    required KnowledgePackage base,
    required List<FailureModeAuthoringRecord> records,
    bool registerClosePaths = true,
  }) {
    for (final record in records) {
      validateFailureModeAuthoringRecord(
        record,
        expectedApplianceFamily: base.category,
      );
    }

    final modesById = {
      for (final mode in base.failureModes) mode.id: mode,
    };
    final templatesById = {
      for (final template in base.evidenceTemplates) template.id: template,
    };

    final added = <String>[];
    final updated = <String>[];

    for (final record in records) {
      final existed = modesById.containsKey(record.id);
      modesById[record.id] = record.toFailureMode();
      if (existed) {
        updated.add(record.id);
      } else {
        added.add(record.id);
      }

      // Symptom phrasings remain authoring metadata. Existing package symptoms
      // are not auto-expanded from free-text phrasings during import.

      for (final question in record.firstLineQuestions) {
        final existing = templatesById[question.templateId];
        if (existing == null) {
          templatesById[question.templateId] = question.toEvidenceTemplate(
            failureModeId: record.id,
          );
        } else {
          templatesById[question.templateId] = _withAuthoredPrompt(
            existing: existing,
            question: question,
            failureModeId: record.id,
          );
        }
      }

      for (final hint in record.evidenceSupports) {
        templatesById[hint.templateId] = _withAnswerHint(
          template: templatesById[hint.templateId],
          templateId: hint.templateId,
          promptFallback: hint.templateId,
          failureModeId: record.id,
          answer: hint.answer,
          support: true,
        );
      }
      for (final hint in record.evidenceExcludes) {
        templatesById[hint.templateId] = _withAnswerHint(
          template: templatesById[hint.templateId],
          templateId: hint.templateId,
          promptFallback: hint.templateId,
          failureModeId: record.id,
          answer: hint.answer,
          support: false,
        );
      }

      if (registerClosePaths) {
        registerImportedClosePath(
          FailureModeClosePath(
            failureModeId: record.id,
            verificationAsk: record.verificationAsk,
            verificationWhy: record.verificationWhy,
            safeGuidanceSteps: record.safeGuidanceBoundary,
            expertOkSteps: record.expertOkSteps.isNotEmpty
                ? record.expertOkSteps
                : (closePathForFailureMode(record.id)?.expertOkSteps ??
                    const []),
            allowResolvedWhenConfirmed: record.allowResolvedWhenConfirmed,
            preferProfessionalWhenNotConfirmed:
                record.preferProfessionalWhenNotConfirmed,
            visualGuides: record.visualGuides.isNotEmpty
                ? record.visualGuides
                : builtInVisualGuidesFor(record.id),
            inspectSteps: builtInInspectStepsFor(record.id),
          ),
        );
      }
    }

    // Preserve original template order, then append any newly authored templates.
    final orderedTemplateIds = [
      ...base.evidenceTemplates.map((t) => t.id),
      ...templatesById.keys.where(
        (id) => !base.evidenceTemplates.any((t) => t.id == id),
      ),
    ];

    final package = KnowledgePackage(
      id: base.id,
      category: base.category,
      version: base.version,
      displayName: base.displayName,
      schemaVersion: base.schemaVersion,
      failureModes: [
        ...base.failureModes.map((mode) => modesById[mode.id]!),
        ...added.map((id) => modesById[id]!),
      ],
      symptoms: base.symptoms,
      evidenceTemplates: [
        for (final id in orderedTemplateIds) templatesById[id]!,
      ],
      safeChecks: base.safeChecks,
      inspectSteps: base.inspectSteps,
      createdAt: base.createdAt,
      source: base.source,
      status: base.status,
    );

    return FailureModeBatchImportResult(
      package: package,
      importedIds: records.map((r) => r.id).toList(growable: false),
      addedModeIds: List.unmodifiable(added),
      updatedModeIds: List.unmodifiable(updated),
    );
  }

  /// Convenience: parse JSON text and merge into [base].
  FailureModeBatchImportResult mergeJsonIntoPackage({
    required KnowledgePackage base,
    required String rawJson,
    bool registerClosePaths = true,
  }) {
    return mergeIntoPackage(
      base: base,
      records: parseBatchJson(rawJson),
      registerClosePaths: registerClosePaths,
    );
  }

  /// Merges the built-in dryer golden example into [base].
  FailureModeBatchImportResult mergeDryerGoldenExample(
    KnowledgePackage base,
  ) {
    return mergeJsonIntoPackage(
      base: base,
      rawJson: dryerThermalFuseRestrictedVentGoldenJson,
    );
  }

  /// Merges Dryer Failure Mode Batch 01 (20 modes) into [base].
  FailureModeBatchImportResult mergeDryerBatch01(KnowledgePackage base) {
    return mergeJsonIntoPackage(
      base: base,
      rawJson: dryerBatch01Json,
    );
  }

  /// Merges Dryer Failure Mode Batch 02 (20 modes) into [base].
  FailureModeBatchImportResult mergeDryerBatch02(KnowledgePackage base) {
    return mergeJsonIntoPackage(
      base: base,
      rawJson: dryerBatch02Json,
    );
  }
}

/// True when [template] carries no human prompt yet (id used as placeholder).
///
/// Answer-hint merging seeds templates before their authored prompt is known,
/// so those stubs must stay upgradeable regardless of record order.
bool isPlaceholderPromptText(EvidenceTemplate template) {
  final text = template.promptText.trim();
  return text.isEmpty || text == template.id;
}

/// Adds [failureModeId] to [existing] and backfills authored prompt/choices.
///
/// Only placeholder prompt text and empty answer choices are replaced, so a
/// template authored earlier (base package or another batch) keeps its wording.
EvidenceTemplate _withAuthoredPrompt({
  required EvidenceTemplate existing,
  required FirstLineObservation question,
  required String failureModeId,
}) {
  final related = existing.relatedFailureModeIds.contains(failureModeId)
      ? existing.relatedFailureModeIds
      : [...existing.relatedFailureModeIds, failureModeId];
  final authoredPrompt = question.promptText.trim();
  return EvidenceTemplate(
    id: existing.id,
    promptText:
        isPlaceholderPromptText(existing) && authoredPrompt.isNotEmpty
            ? question.promptText
            : existing.promptText,
    expectedEvidenceType: existing.expectedEvidenceType,
    relatedFailureModeIds: related,
    answerChoices: existing.answerChoices.isEmpty
        ? question.answerChoices
        : existing.answerChoices,
    supportByAnswer: existing.supportByAnswer,
    excludeByAnswer: existing.excludeByAnswer,
  );
}

EvidenceTemplate _withAnswerHint({
  required EvidenceTemplate? template,
  required String templateId,
  required String promptFallback,
  required String failureModeId,
  required String answer,
  required bool support,
}) {
  final base =
      template ??
      EvidenceTemplate(
        id: templateId,
        promptText: promptFallback,
        expectedEvidenceType: EvidenceType.structuredAnswer,
        relatedFailureModeIds: const [],
      );

  final related = base.relatedFailureModeIds.contains(failureModeId)
      ? base.relatedFailureModeIds
      : [...base.relatedFailureModeIds, failureModeId];

  final supportMap = _copyAnswerMap(base.supportByAnswer);
  final excludeMap = _copyAnswerMap(base.excludeByAnswer);
  final target = support ? supportMap : excludeMap;
  final existing = target[answer] ?? <String>[];
  if (!existing.contains(failureModeId)) {
    target[answer] = [...existing, failureModeId];
  }

  return EvidenceTemplate(
    id: base.id,
    promptText: base.promptText,
    expectedEvidenceType: base.expectedEvidenceType,
    relatedFailureModeIds: related,
    answerChoices: base.answerChoices,
    supportByAnswer: supportMap,
    excludeByAnswer: excludeMap,
  );
}

Map<String, List<String>> _copyAnswerMap(Map<String, List<String>> source) {
  return {
    for (final entry in source.entries)
      entry.key: List<String>.from(entry.value),
  };
}
