import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('version is 0.1.4+24', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+24');
  });

  testWidgets(
    'short viewport scrolls to Other / describe and records the note',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 20));
      await openDryerSession(tester, deps, 'Short Viewport House');
      tester.view.physicalSize = const Size(800, 656);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('session-scroll-view')), findsOneWidget);
      expect(find.text('Current question'), findsOneWidget);
      expect(find.byKey(const Key('why-ask-this-tile')), findsOneWidget);
      expect(find.byKey(const Key('session-secondary-details')), findsOneWidget);
      expect(find.byKey(const Key('evidence-history-tile')), findsOneWidget);

      final other = find.byKey(const Key('answer-choice-other-describe'));
      expect(other, findsOneWidget);
      await tapVisible(tester, other);
      expect(find.byKey(const Key('answer-other-note-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('answer-other-note-field')),
        'rattle behind the drum',
      );
      await tester.tap(find.byKey(const Key('answer-other-confirm')));
      await tester.pumpAndSettle();

      await expandEvidenceHistory(tester);
      expect(
        find.textContaining(
          'Answer: Other / describe: rattle behind the drum',
        ),
        findsOneWidget,
      );

      final recorded = deps.repairSessionRepository.listAllEvidence();
      expect(
        recorded.any(
          (item) =>
              normalizeObservationAnswer(item.answer) ==
                  kOtherDescribeChoiceId &&
              (item.answer ?? '').startsWith('$kOtherDescribeChoiceId:'),
        ),
        isTrue,
      );
    },
  );

  testWidgets('first-run Skip completes on the first tap after splash', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 29, 20, 5),
      firstRunComplete: false,
      disclaimerAcknowledged: false,
    );

    await prepareShortViewport(tester);
    await tester.pumpWidget(
      ModernButlerApp(dependencies: deps, forceBrandSplash: true),
    );
    await tester.pump();
    expect(find.byKey(const Key('splash-screen')), findsOneWidget);
    expect(find.byKey(const Key('first-run-skip-button')), findsNothing);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsOneWidget);
    final skip = find.byKey(const Key('first-run-skip-button'));
    expect(skip.hitTestable(), findsOneWidget);

    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(find.byKey(const Key('create-household-button')), findsNothing);
    expect(deps.firstRunComplete, isTrue);
    expect(deps.disclaimerAcknowledged, isFalse);
  });

  testWidgets('burning-smell Stop stays on a short viewport after scroll', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 20, 10));
    await openDryerSession(
      tester,
      deps,
      'Short Stop House',
      skipProblemStarter: false,
    );
    tester.view.physicalSize = const Size(800, 656);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('starter-chip-hazard-signs')));
    await tapVisible(tester, find.byKey(const Key('problem-starter-confirm')));

    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(find.byKey(const Key('safety-stop-banner')).hitTestable(), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('safety-stop-title'))).data,
      'Needs a professional',
    );
    expect(find.textContaining('Unplug if it is safe'), findsOneWidget);
    expect(find.textContaining('ventilate'), findsOneWidget);
    expect(find.textContaining('do not keep running'), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsNothing);

    final scrollable = find.descendant(
      of: find.byKey(const Key('session-scroll-view')),
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('safety-stop-banner')).hitTestable(), findsOneWidget);
    expect(find.textContaining(UserFacingCopy.safetyStopOfficial), findsWidgets);
  });
}
