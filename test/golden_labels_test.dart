import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/easy_airflow_checks.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

/// Freeze for docs/qa/GOLDEN_LABELS.md — prompts and first guidance titles.
void main() {
  final dryer = KnowledgePackageRepository().loadById('dryer-core')!;
  final washer = buildWasherMvpPackage();

  EvidenceTemplate dryerTemplate(String id) {
    return dryer.evidenceTemplates.firstWhere((item) => item.id == id);
  }

  test('dryer no-heat easy-check and drum-turns questions match GOLDEN_LABELS', () {
    expect(
      dryerTemplate('drum-turns').promptText,
      'Does the drum turn during the cycle?',
    );
    expect(dryerTemplate('drum-turns').answerChoices, contains('Turns normally'));

    expect(
      lintFilterEasyPrompt,
      'Check airflow before opening the cabinet. Pull the lint filter and look '
      'at the screen. What do you see?',
    );
    expect(dryerTemplate('lint-filter-condition').promptText, lintFilterEasyPrompt);
    expect(
      exteriorAirflowEasyPrompt,
      'Check airflow before opening the cabinet. Go outside to the vent hood '
      'while the dryer runs. How strong is the air at the outside vent?',
    );
    expect(
      ventHoseEasyPrompt,
      'Check airflow before opening the cabinet. Look behind the dryer at the '
      'visible vent hose. Is it crushed, kinked, packed with lint, or a long '
      'restricted run?',
    );
    for (final id in easyAirflowCheckTemplateIds) {
      final choices = answerChoicesFor(dryerTemplate(id));
      expect(choices, contains(alreadyCheckedEasyCheckAnswer));
      expect(choices, contains('Not sure'));
    }
    expect(UserFacingCopy.skipToBestGuess, 'Skip to best guess');
  });

  test('dryer first gated guidance step is check the lint filter', () {
    for (final id in ['thermal-fuse-open', 'heating-element-failed']) {
      final first = orderEasyAirflowGuidanceFirst(
        closePathForFailureMode(id)!.safeGuidanceSteps,
      ).first;
      expect(
        first,
        startsWith(
          'Check airflow before opening the cabinet. Pull the lint filter '
          'and look at the screen.',
        ),
      );
      expect(guidanceForSafeStep(first).what, 'Check the lint filter');
      expect(first.toLowerCase(), isNot(contains('service panel')));
    }
  });

  test('dryer fuse beginner tools are optional flashlight only', () {
    final items = readinessItemsFromToolsRequired(
      FailureModeAuthoringRegistry.toolsRequiredFor('thermal-fuse-open'),
    );
    expect(items.map((item) => item.id).toSet(), {'screwdriver', 'flashlight'});
    expect(items.every((item) => item.optional), isTrue);
    expect(readinessDisplayLabel(items.firstWhere((item) => item.id == 'flashlight')), 'Flashlight');
    expect(items.firstWhere((item) => item.id == 'flashlight').optional, isTrue);
  });

  test('washer won’t-drain easy checks and first guidance match GOLDEN_LABELS', () {
    expect(
      washer.evidenceTemplates
          .firstWhere((item) => item.id == washerComplaintTemplateId)
          .promptText,
      'What is the washer doing?',
    );
    expect(
      washer.evidenceTemplates
          .firstWhere((item) => item.id == washerComplaintTemplateId)
          .answerChoices,
      contains("Won't drain"),
    );
    expect(
      washer.evidenceTemplates
          .firstWhere((item) => item.id == 'washer-door-click')
          .promptText,
      'Does the door close firmly until you feel or hear a solid click?',
    );
    expect(
      washer.evidenceTemplates
          .firstWhere((item) => item.id == 'washer-drain-filter-access')
          .promptText,
      'After unplugging, looking at the accessible coin trap / drain '
      'filter from outside (do not split a sealed pump), does it look '
      'packed with lint, coins, or sludge?',
    );
    expect(
      washer.failureModes
          .firstWhere((mode) => mode.id == washerCloggedDrainFilterId)
          .label,
      'Clogged drain filter or pump trap',
    );

    final first = closePathForFailureMode(washerCloggedDrainFilterId)!
        .safeGuidanceSteps
        .first;
    expect(
      first,
      'Check that the washer door closes firmly until you feel or hear a click. '
      'Do not bypass the door switch.',
    );
    expect(guidanceForSafeStep(first).what, 'Safety limit for this check');
    expect(first.toLowerCase(), isNot(contains('unplug the washer')));
  });

  test('washer drain tools checklist labels match GOLDEN_LABELS', () {
    final items = readinessItemsFromToolsRequired(
      FailureModeAuthoringRegistry.toolsRequiredFor(washerCloggedDrainFilterId),
    );
    expect(
      readinessDisplayLabel(items.firstWhere((item) => item.id == 'shallow-pan')),
      'Shallow pan and towel',
    );
    expect(items.firstWhere((item) => item.id == 'shallow-pan').optional, isFalse);
    expect(readinessDisplayLabel(items.firstWhere((item) => item.id == 'flashlight')), 'Flashlight');
    expect(items.firstWhere((item) => item.id == 'flashlight').optional, isTrue);
  });
}
