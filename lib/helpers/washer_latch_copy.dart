import '../models/appliance.dart';
import '../models/knowledge_package.dart';

/// Latch wording for washer interview chips. Inspect already says door or lid.
String washerLatchNoun(WasherLoadStyle style) {
  return switch (style) {
    WasherLoadStyle.topLoad => 'lid',
    WasherLoadStyle.frontLoad => 'door',
    WasherLoadStyle.unknown => 'door or lid',
  };
}

String washerLatchWontCloseChip(WasherLoadStyle style) {
  return switch (style) {
    WasherLoadStyle.topLoad => "Lid won't close",
    WasherLoadStyle.frontLoad => "Door won't close",
    WasherLoadStyle.unknown => "Door or lid won't close",
  };
}

String washerLatchClickPrompt(WasherLoadStyle style) {
  final noun = washerLatchNoun(style);
  return 'Does the $noun close firmly until you feel or hear a solid click?';
}

/// Rewrites washer complaint / latch templates for the household's machine type.
List<EvidenceTemplate> washerLatchInterviewTemplates(
  List<EvidenceTemplate> templates,
  WasherLoadStyle style,
) {
  return [
    for (final template in templates)
      _relabelWasherLatchTemplate(template, style),
  ];
}

EvidenceTemplate _relabelWasherLatchTemplate(
  EvidenceTemplate template,
  WasherLoadStyle style,
) {
  if (template.id == 'washer-door-click') {
    return EvidenceTemplate(
      id: template.id,
      promptText: washerLatchClickPrompt(style),
      expectedEvidenceType: template.expectedEvidenceType,
      relatedFailureModeIds: template.relatedFailureModeIds,
      answerChoices: template.answerChoices,
      supportByAnswer: template.supportByAnswer,
      excludeByAnswer: template.excludeByAnswer,
    );
  }
  if (template.id != 'washer-complaint') {
    return template;
  }
  final oldChip = "Door won't close";
  final newChip = washerLatchWontCloseChip(style);
  if (oldChip == newChip) {
    return template;
  }
  return EvidenceTemplate(
    id: template.id,
    promptText: template.promptText,
    expectedEvidenceType: template.expectedEvidenceType,
    relatedFailureModeIds: template.relatedFailureModeIds,
    answerChoices: [
      for (final choice in template.answerChoices)
        choice == oldChip ? newChip : choice,
    ],
    supportByAnswer: {
      for (final entry in template.supportByAnswer.entries)
        (entry.key == oldChip ? newChip : entry.key): entry.value,
    },
    excludeByAnswer: template.excludeByAnswer,
  );
}
