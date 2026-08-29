import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/repair_comfort_profile.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('defaults are standard with learn preferences off', () {
    const profile = RepairComfortProfile();
    expect(profile.learnPreferences, isFalse);
    for (final domain in RepairComfortProfile.domains) {
      expect(profile.levelFor(domain), RepairComfortLevel.standard);
    }
    expect(profile.shouldAskToShorten('dryer'), isFalse);
  });

  test('learn on only asks when steps are not already shorter', () {
    final learning = const RepairComfortProfile(
      learnPreferences: true,
    );
    expect(learning.shouldAskToShorten('washer'), isTrue);
    expect(
      learning
          .withLevel('washer', RepairComfortLevel.shorter)
          .shouldAskToShorten('washer'),
      isFalse,
    );
  });

  test('comfort profile survives persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 17, 16);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Comfort House');
    first.setRepairComfortLevel('dryer', RepairComfortLevel.moreDetail);
    first.setLearnPreferences(true);
    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    expect(second.repairComfort.learnPreferences, isTrue);
    expect(
      second.repairComfort.levelFor('dryer'),
      RepairComfortLevel.moreDetail,
    );
    expect(
      second.repairComfort.levelFor('washer'),
      RepairComfortLevel.standard,
    );
  });

  testWidgets('Settings explains comfort and keeps it editable', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 16, 5));
    deps.createHousehold('Comfort Settings');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-comfort-explainer')),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('settings-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text(UserFacingCopy.comfortSettingsExplainer), findsOneWidget);
    expect(find.byKey(const Key('settings-learn-preferences')), findsOneWidget);
    expect(deps.repairComfort.learnPreferences, isFalse);

    await tester.tap(find.byKey(const Key('settings-comfort-dryer-shorter')));
    await tester.pumpAndSettle();
    expect(deps.repairComfort.levelFor('dryer'), RepairComfortLevel.shorter);

    await scrollSettingsUntil(tester, const Key('settings-learn-preferences'));
    await tester.tap(find.byKey(const Key('settings-learn-preferences')));
    await tester.pumpAndSettle();
    expect(deps.repairComfort.learnPreferences, isTrue);
  });

  testWidgets('more detail shows why a guidance step matters', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 16, 10));
    deps.setRepairComfortLevel('dryer', RepairComfortLevel.moreDetail);
    await openDryerSession(tester, deps, 'More Detail House');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.byKey(const Key('guidance-result-means-1')), findsOneWidget);
    expect(find.textContaining('Step detail: More detail'), findsOneWidget);
  });

  testWidgets('shorter still keeps unplug / do-not wording', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 16, 15));
    deps.setRepairComfortLevel('dryer', RepairComfortLevel.shorter);
    await openDryerSession(tester, deps, 'Shorter House');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await completeRepairReadinessIfPresent(tester);
    await walkGuidanceUntilContaining(tester, 'Unplug the dryer');
    expect(find.textContaining('Unplug the dryer'), findsWidgets);
  });

  testWidgets('Fixed does not ask to shorten when learn is off', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 16, 20));
    await openDryerSession(tester, deps, 'No Ask House');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await completeRepairReadinessIfPresent(tester);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-resolved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('completion-done-screen')), findsOneWidget);
    expect(find.byKey(const Key('comfort-shorten-prompt')), findsNothing);
  });

  testWidgets('after Fixed with learn on, ask then save shorter', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 16, 25));
    deps.setLearnPreferences(true);
    await openDryerSession(tester, deps, 'Ask House');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await completeRepairReadinessIfPresent(tester);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-resolved')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('comfort-shorten-prompt')), findsOneWidget);
    expect(find.text(UserFacingCopy.comfortShortenAskBody), findsOneWidget);
    await tester.tap(find.byKey(const Key('comfort-shorten-yes')));
    await tester.pumpAndSettle();
    expect(deps.repairComfort.levelFor('dryer'), RepairComfortLevel.shorter);
    expect(find.byKey(const Key('comfort-shorten-saved')), findsOneWidget);
  });
}
