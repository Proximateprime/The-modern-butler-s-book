import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

/// Tall surface so expanded interview sections stay tappable in widget tests.
Future<void> prepareTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Hosted Pages short viewport (~656 logical px height) George walked.
Future<void> prepareShortViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 656);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> confirmAddAppliance(WidgetTester tester) async {
  final save = find.byKey(const Key('add-appliance-save-button'));
  if (save.evaluate().isEmpty) {
    return;
  }
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> openDryerSession(
  WidgetTester tester,
  AppDependencies dependencies,
  String householdName, {
  bool skipProblemStarter = true,
  Size? viewSize,
}) async {
  if (viewSize != null) {
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  } else {
    await prepareTallSurface(tester);
  }
  await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));
  await tester.tap(find.byKey(const Key('create-household-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('household-name-field')),
    householdName,
  );
  await tester.tap(find.byKey(const Key('confirm-household-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-dryer-button')));
  await tester.pumpAndSettle();
  await confirmAddAppliance(tester);
  await tester.tap(find.text('Laundry Room Dryer'));
  await tester.pumpAndSettle();
  await startRepairFromDetail(tester);
  if (skipProblemStarter) {
    await dismissProblemStarterIfPresent(tester);
  }
}

Future<void> openWasherSession(
  WidgetTester tester,
  AppDependencies dependencies,
  String householdName,
) async {
  await prepareTallSurface(tester);
  await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));
  await tester.tap(find.byKey(const Key('create-household-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('household-name-field')),
    householdName,
  );
  await tester.tap(find.byKey(const Key('confirm-household-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-washer-button')));
  await tester.pumpAndSettle();
  await confirmAddAppliance(tester);
  await tester.tap(find.text('Laundry Room Washer'));
  await tester.pumpAndSettle();
  await startRepairFromDetail(tester);
}

Future<void> openFridgeSession(
  WidgetTester tester,
  AppDependencies dependencies,
  String householdName,
) async {
  await prepareTallSurface(tester);
  await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));
  await tester.tap(find.byKey(const Key('create-household-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('household-name-field')),
    householdName,
  );
  await tester.tap(find.byKey(const Key('confirm-household-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-fridge-button')));
  await tester.pumpAndSettle();
  await confirmAddAppliance(tester);
  await tester.tap(find.text('Kitchen Fridge'));
  await tester.pumpAndSettle();
  await startRepairFromDetail(tester);
}

Future<void> openDishwasherSession(
  WidgetTester tester,
  AppDependencies dependencies,
  String householdName,
) async {
  await prepareTallSurface(tester);
  await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));
  await tester.tap(find.byKey(const Key('create-household-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('household-name-field')),
    householdName,
  );
  await tester.tap(find.byKey(const Key('confirm-household-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-dishwasher-button')));
  await tester.pumpAndSettle();
  await confirmAddAppliance(tester);
  await tester.tap(find.text('Kitchen Dishwasher'));
  await tester.pumpAndSettle();
  await startRepairFromDetail(tester);
}

Future<void> confirmNoHeatStarter(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('problem-starter-confirm')));
  await tester.pumpAndSettle();
  await answerElectricFuelIfAsked(tester);
}

/// Unknown-energy dryers ask fuel first. Tests that need the electric path
/// answer it here so later discriminators stay stable.
Future<void> answerElectricFuelIfAsked(WidgetTester tester) async {
  final fuel = find.byKey(const Key('observation-prompt-gas-dryer-type'));
  if (fuel.evaluate().isEmpty) {
    return;
  }
  await tapVisible(
    tester,
    find.byKey(const Key('answer-choice-electric-dryer')),
  );
}

Future<void> answerObservation(
  WidgetTester tester,
  String templateId,
  String choiceKeySuffix,
) async {
  await selectObservation(tester, templateId);
  await tapInspectOrAnswerChoice(tester, choiceKeySuffix);
}

/// Interview inspect uses LOOK FOR chips; other prompts use answer-choice-*.
Future<void> tapInspectOrAnswerChoice(
  WidgetTester tester,
  String choiceKeySuffix,
) async {
  final inspectDont = find.byKey(const Key('inspect-chip-doesnt-match'));
  final inspectOk = find.byKey(const Key('inspect-chip-matches-ok'));
  final weakOrRestricted = choiceKeySuffix == 'weak' ||
      choiceKeySuffix.contains('restricted') ||
      choiceKeySuffix.contains('clogged') ||
      choiceKeySuffix.contains('blocked');
  final normalOrClear =
      choiceKeySuffix == 'normal' || choiceKeySuffix.contains('looks-clear');
  if (weakOrRestricted && inspectDont.evaluate().isNotEmpty) {
    await tapVisible(tester, inspectDont);
    return;
  }
  if (normalOrClear && inspectOk.evaluate().isNotEmpty) {
    await tapVisible(tester, inspectOk);
    return;
  }
  await tapVisible(tester, find.byKey(Key('answer-choice-$choiceKeySuffix')));
}

Future<void> startRepairFromDetail(WidgetTester tester) async {
  await tapVisible(
    tester,
    find.byKey(const Key('appliance-detail-start-repair')),
  );
}

/// Skips the deterministic problem starter so interview tests stay focused.
Future<void> dismissProblemStarterIfPresent(WidgetTester tester) async {
  final skip = find.byKey(const Key('problem-starter-skip'));
  if (skip.evaluate().isEmpty) {
    return;
  }
  await tester.tap(skip);
  await tester.pumpAndSettle();
}

/// Brings a Settings row into view from wherever the list currently sits.
///
/// Rewinds to the top first: a row above the current offset is unreachable by
/// downward scrolling alone, and dragging past the end can detach the
/// scrollable the finder was resolved against.
Future<void> scrollSettingsUntil(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  final scrollable = find
      .descendant(
        of: find.byKey(const Key('settings-screen')),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 24; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(scrollable, const Offset(0, 320));
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 40; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  final enclosing = find.ancestor(
    of: finder,
    matching: find.byType(Scrollable),
  );
  final scrollable =
      enclosing.evaluate().isNotEmpty ? enclosing : find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) {
    await tester.tap(finder);
    await tester.pumpAndSettle();
    return;
  }
  await tester.scrollUntilVisible(finder, 120, scrollable: scrollable.first);
  await tester.pumpAndSettle();
  for (var i = 0; i < 20; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      break;
    }
    await tester.drag(scrollable.first, const Offset(0, -280));
    await tester.pumpAndSettle();
  }
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

/// Marks every readiness item as owned so Safe Guidance can appear.
Future<void> advanceClosePathFromConclusionIfPresent(
  WidgetTester tester,
) async {
  final continueBtn = find.byKey(const Key('close-path-continue'));
  if (continueBtn.evaluate().isNotEmpty) {
    await tapVisible(tester, continueBtn);
  }
  final illRepair = find.byKey(const Key('close-path-ill-repair'));
  if (illRepair.evaluate().isNotEmpty) {
    await tapVisible(tester, illRepair);
  }
  final partsContinue = find.byKey(const Key('close-path-parts-continue'));
  if (partsContinue.evaluate().isNotEmpty) {
    await tapVisible(tester, partsContinue);
  }
}

/// Completes inspect chips then Parts continue when that card is showing.
Future<void> completeClosePathInspectThenPartsIfPresent(
  WidgetTester tester,
) async {
  await completeInspectStepsIfPresent(tester);
  final partsContinue = find.byKey(const Key('close-path-parts-continue'));
  if (partsContinue.evaluate().isNotEmpty) {
    await tapVisible(tester, partsContinue);
  }
}

/// Marks every readiness item as owned. Does not tap Continue to guidance.
Future<void> markRepairReadinessHaveIfPresent(WidgetTester tester) async {
  await advanceClosePathFromConclusionIfPresent(tester);
  await completeClosePathInspectThenPartsIfPresent(tester);
  final tapped = <String>{};
  for (var i = 0; i < 24; i++) {
    final card = find.byKey(const Key('repair-readiness-card'));
    if (card.evaluate().isEmpty) {
      return;
    }
    Key? nextKey;
    for (final element in find
        .descendant(
          of: card,
          matching: find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('readiness-have-');
          }),
        )
        .evaluate()) {
      final key = element.widget.key;
      if (key is ValueKey<String> && tapped.add(key.value)) {
        nextKey = key;
        break;
      }
    }
    if (nextKey == null) {
      return;
    }
    await tapVisible(tester, find.byKey(nextKey));
  }
}

/// Marks every readiness item as owned so Safe Guidance can appear.
Future<void> completeRepairReadinessIfPresent(WidgetTester tester) async {
  await markRepairReadinessHaveIfPresent(tester);
  final cont = find.byKey(const Key('close-path-tools-continue'));
  if (cont.evaluate().isNotEmpty) {
    await tapVisible(tester, cont);
  }
  await completeInspectStepsIfPresent(tester);
  await acknowledgeProScopeIfPresent(tester);
}

Future<void> acknowledgeProScopeIfPresent(WidgetTester tester) async {
  final doChecks = find.byKey(const Key('pro-scope-do-safe-checks'));
  if (doChecks.evaluate().isNotEmpty) {
    await tapVisible(tester, doChecks);
  }
}

Future<void> completeInspectStepsIfPresent(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    final chip = find.byKey(const Key('inspect-chip-matches-ok'));
    if (chip.evaluate().isEmpty) {
      return;
    }
    if (chip.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(chip.hitTestable());
      await tester.pumpAndSettle();
      continue;
    }
    await tapVisible(tester, chip);
  }
}

Future<void> completeGuidanceStepsIfPresent(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pumpAndSettle();
    await acknowledgeProScopeIfPresent(tester);
    if (find.byKey(const Key('pro-recommended-card')).evaluate().isNotEmpty) {
      return;
    }
    final did = find.byKey(const Key('guidance-did-this'));
    if (did.evaluate().isNotEmpty) {
      if (did.hitTestable().evaluate().isNotEmpty) {
        await tester.tap(did.hitTestable());
      } else {
        await tapVisible(tester, did);
      }
      continue;
    }
    final inspect = find.byKey(const Key('inspect-chip-matches-ok'));
    if (inspect.evaluate().isNotEmpty &&
        find.byKey(const Key('safe-guidance-card')).evaluate().isEmpty) {
      if (inspect.hitTestable().evaluate().isNotEmpty) {
        await tester.tap(inspect.hitTestable());
      } else {
        await tapVisible(tester, inspect);
      }
      continue;
    }
    final unlock = find.text('Continue to verification');
    if (unlock.evaluate().isNotEmpty) {
      await tapVisible(tester, unlock);
      continue;
    }
    return;
  }
}

Future<void> tapConfirmedVerificationIfPresent(WidgetTester tester) async {
  final confirmed = find.byKey(const Key('answer-choice-confirmed'));
  for (var i = 0; i < 16; i++) {
    await tester.pumpAndSettle();
    await acknowledgeProScopeIfPresent(tester);
    if (find.byKey(const Key('pro-recommended-card')).evaluate().isNotEmpty) {
      return;
    }
    if (confirmed.evaluate().isNotEmpty) {
      await tester.ensureVisible(confirmed);
      await tester.pumpAndSettle();
      await tester.tap(confirmed);
      await tester.pumpAndSettle();
      return;
    }
    final did = find.byKey(const Key('guidance-did-this'));
    if (did.evaluate().isNotEmpty) {
      await tester.ensureVisible(did);
      await tester.pumpAndSettle();
      await tester.tap(did);
      continue;
    }
    final inspect = find.byKey(const Key('inspect-chip-matches-ok'));
    if (inspect.evaluate().isNotEmpty) {
      await tester.ensureVisible(inspect);
      await tester.pumpAndSettle();
      await tester.tap(inspect);
      continue;
    }
    return;
  }
}

/// Advances one-step guidance until [text] is on screen, or steps run out.
Future<void> walkGuidanceUntilContaining(
  WidgetTester tester,
  String text, {
  int maxSteps = 16,
}) async {
  await completeInspectStepsIfPresent(tester);
  await acknowledgeProScopeIfPresent(tester);
  for (var i = 0; i < maxSteps; i++) {
    if (find.textContaining(text).evaluate().isNotEmpty) {
      return;
    }
    await acknowledgeProScopeIfPresent(tester);
    final did = find.byKey(const Key('guidance-did-this'));
    if (did.evaluate().isEmpty) {
      return;
    }
    await tapVisible(tester, did);
  }
}

Future<void> reachClosePathVerificationIfPresent(WidgetTester tester) async {
  await completeRepairReadinessIfPresent(tester);
  await completeGuidanceStepsIfPresent(tester);
}

Future<void> selectObservation(WidgetTester tester, String templateId) async {
  final promptKey = Key('observation-prompt-$templateId');
  final alreadyActive =
      find
          .descendant(
            of: find.byKey(const Key('answer-choice-panel')),
            matching: find.byKey(promptKey),
          )
          .evaluate()
          .isNotEmpty;
  if (alreadyActive) {
    return;
  }
  await tapVisible(tester, find.byKey(const Key('other-observations-picker')));
  await tapVisible(tester, find.byKey(promptKey));
}

Future<void> selectFailureMode(WidgetTester tester, String failureModeId) async {
  final modeFinder = find.byKey(Key('failure-mode-$failureModeId'));
  if (modeFinder.hitTestable().evaluate().isEmpty) {
    await tapVisible(tester, find.byKey(const Key('failure-modes-tile')));
  }
  await tapVisible(tester, modeFinder);
}

Future<void> saveSessionOutcome(
  WidgetTester tester, {
  Key choiceKey = const Key('outcome-resolved'),
  String? note,
}) async {
  await tester.tap(find.byKey(choiceKey));
  await tester.pumpAndSettle();
  if (note != null) {
    await tester.enterText(find.byKey(const Key('outcome-note-field')), note);
  }
  final save = find.byKey(const Key('outcome-save-button'));
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
  final goHome = find.byKey(const Key('completion-save-home'));
  if (goHome.evaluate().isNotEmpty) {
    await tapVisible(tester, goHome);
  }
}

Future<void> expandEvidenceHistory(WidgetTester tester) async {
  final empty = find.byKey(const Key('empty-evidence-message'));
  final answered = find.textContaining('Answer:');
  if (empty.hitTestable().evaluate().isNotEmpty ||
      answered.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  await tapVisible(tester, find.byKey(const Key('evidence-history-tile')));
}
