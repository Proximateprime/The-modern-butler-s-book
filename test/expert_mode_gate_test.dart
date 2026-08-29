import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/expert_mode.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('expert_ok mechanical steps stay hidden until Expert Mode is on', () {
    final path = closePathForFailureMode('broken-drive-belt')!;
    expect(path.expertOkSteps, isNotEmpty);
    final beginner = visibleSafeGuidanceSteps(path, expertMode: false);
    final expert = visibleSafeGuidanceSteps(path, expertMode: true);
    expect(
      beginner.join(' ').toLowerCase(),
      isNot(contains('service panel')),
    );
    expect(expert.join(' ').toLowerCase(), contains('service panel'));
    expect(beginner, path.safeGuidanceSteps);
  });

  test('Expert Mode still blocks gas, sealed-system, and refrigerant extras', () {
    const path = FailureModeClosePath(
      failureModeId: 'test-mode',
      verificationAsk: 'Ask?',
      verificationWhy: 'Why',
      safeGuidanceSteps: ['Unplug before you look.'],
      allowResolvedWhenConfirmed: true,
      preferProfessionalWhenNotConfirmed: true,
      expertOkSteps: [
        'Replace the gas valve on the dryer.',
        'Pierce the sealed system and add refrigerant.',
        'With power unplugged, inspect the accessible belt path.',
        'Do not add, recover, or handle refrigerant.',
      ],
    );
    final shown = visibleSafeGuidanceSteps(path, expertMode: true);
    expect(shown, contains('Unplug before you look.'));
    expect(shown, contains('With power unplugged, inspect the accessible belt path.'));
    expect(shown, contains('Do not add, recover, or handle refrigerant.'));
    expect(shown.join(' ').toLowerCase(), isNot(contains('replace the gas valve')));
    expect(shown.join(' ').toLowerCase(), isNot(contains('pierce the sealed')));
  });

  test('package expert_ok flag parses from mixed guidance lists', () {
    final split = splitGuidanceSteps([
      'Unplug the dryer.',
      {
        'text': 'Inspect the belt from an accessible service panel.',
        'expert_ok': true,
      },
    ]);
    expect(split.beginner, ['Unplug the dryer.']);
    expect(split.expertOk.single, contains('service panel'));
  });

  test('hard-stop checklist is unchanged when Expert Mode would be on', () {
    final stop = evaluateSafetyStop(
      evidence: [
        Evidence(
          id: 'e1',
          sessionId: 's1',
          applianceId: 'a1',
          type: EvidenceType.structuredAnswer,
          observation: 'Any smoke, burning smell, sparking, or melting?',
          answer: 'Yes',
          templateId: 'hazard-observation',
          collectedAt: DateTime.utc(2026, 8, 17, 15),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ],
    );
    expect(stop, isNotNull);
    expect(stop!.reason.toLowerCase(), contains('fire or smoke'));
  });

  test('Expert Mode stays off without adult confirmation', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15));
    expect(deps.expertMode, isFalse);
    deps.setExpertMode(enabled: true, adultConfirmed: false);
    expect(deps.expertMode, isFalse);
    deps.setExpertMode(enabled: true, adultConfirmed: true);
    expect(deps.expertMode, isTrue);
  });

  test('Expert Mode survives persist only after confirmation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 17, 15);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Expert House');
    first.setExpertMode(enabled: true, adultConfirmed: true);
    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    expect(second.expertMode, isTrue);
  });

  testWidgets('Settings gate requires warning, checkbox, then switch', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15));
    deps.createHousehold('Gate House');
    deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-expert-warning'));
    expect(find.byKey(const Key('settings-expert-warning')), findsOneWidget);
    expect(find.text(UserFacingCopy.expertModeWarning), findsOneWidget);
    expect(find.textContaining('gas'), findsWidgets);
    expect(find.textContaining('refrigerant'), findsWidgets);

    await tapVisible(tester, find.byKey(const Key('settings-expert-mode')));
    await tester.pumpAndSettle();
    expect(deps.expertMode, isFalse);

    await tapVisible(tester, find.byKey(const Key('settings-expert-adult-confirm')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('settings-expert-mode')));
    await tester.pumpAndSettle();
    expect(deps.expertMode, isTrue);
  });

  testWidgets('off keeps beginner guidance without expert_ok extras', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15, 10));
    await openDryerSession(tester, deps, 'Beginner Belt House');
    await selectFailureMode(tester, 'broken-drive-belt');
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('service panel'), findsNothing);
  });

  testWidgets('on shows expert_ok mechanical step and keeps gas forbidden', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15, 20));
    deps.setExpertMode(enabled: true, adultConfirmed: true);
    await openDryerSession(tester, deps, 'Expert Belt House');
    await selectFailureMode(tester, 'broken-drive-belt');
    await completeRepairReadinessIfPresent(tester);
    var sawPanel = false;
    var sawGasLimit = false;
    for (var i = 0; i < 16; i++) {
      if (find.textContaining('service panel').evaluate().isNotEmpty) {
        sawPanel = true;
      }
      if (find
          .textContaining('Do not work on gas connections')
          .evaluate()
          .isNotEmpty) {
        sawGasLimit = true;
      }
      final did = find.byKey(const Key('guidance-did-this'));
      if (did.evaluate().isEmpty) {
        break;
      }
      await tapVisible(tester, did);
    }
    expect(sawPanel, isTrue);
    expect(sawGasLimit, isTrue);
  });

  testWidgets('Expert Mode on still hard-stops a hazard without Fixed', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15, 30));
    deps.setExpertMode(enabled: true, adultConfirmed: true);
    await openWasherSession(tester, deps, 'Expert Hazard House');
    await selectObservation(tester, 'hazard-observation');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
    expect(find.textContaining('fire or smoke'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
  });
}
