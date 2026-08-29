import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  test('heat-pattern uses observation-level answer choices', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final template = package.evidenceTemplates.firstWhere(
      (item) => item.id == 'heat-pattern',
    );

    expect(template.promptText.toLowerCase(), isNot(contains('behave')));
    expect(template.promptText.toLowerCase(), isNot(contains('erratic')));
    expect(
      template.answerChoices,
      containsAll([
        'No heat',
        'Some heat but clothes stay damp',
        'Too hot / overheating',
        'Heat seems normal',
        'Not sure',
      ]),
    );
    expect(
      template.answerChoices,
      isNot(contains('Intermittent / comes and goes')),
    );
  });

  test('verification guidance does not use placeholder copy or repeat the ask', () {
    final block = guidanceForVerification(
      ask:
          'After the safe checks below on a heat cycle, is the load sometimes warm but still damp, or too hot — rather than completely cold with no heat at all?',
      why: 'Partial warmth points toward sensor faults.',
      failureModeId: 'thermistor-fault-electronic',
    );

    expect(block.what, isNot('What we are checking'));
    expect(block.how, isNot(contains('erratically')));
    expect(block.how, isNot(startsWith(block.what)));
    expect(block.how.trim(), isNotEmpty);
  });

  test('heat-pattern guidance uses plain load-feel language', () {
    final block = observationGuidanceForTemplate('heat-pattern');
    expect(block, isNotNull);
    expect(block!.what.toLowerCase(), contains('load'));
    expect(block.how.toLowerCase(), isNot(contains('intermittent')));
  });
}
