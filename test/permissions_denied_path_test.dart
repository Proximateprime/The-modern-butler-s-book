import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/rating_plate_ocr.dart';
import 'package:modern_butlers_book/services/voice_answer.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

class _AvailableOcr implements RatingPlateOcr {
  @override
  bool get isAvailable => true;

  @override
  Future<String?> recognizeFile(String imagePath) async => null;
}

void main() {
  testWidgets(
    'simulated camera/mic deny still completes a dryer chip-only no-heat path',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 18, 18),
        voiceAnswer: ScriptedVoiceAnswerListener(
          VoiceAnswerCapture.permissionDenied,
        ),
      );
      deps.simulateMediaDenied = true;

      await openDryerSession(
        tester,
        deps,
        'Denied Chip Dryer',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);

      expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
      expect(find.byKey(const Key('error-banner-microphone')), findsOneWidget);
      expect(find.byKey(const Key('answer-photo-gallery')), findsNothing);
      expect(find.byKey(const Key('answer-photo-camera')), findsNothing);
      expect(find.byKey(const Key('voice-answer-mic')), findsNothing);
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);

      await answerObservation(tester, 'drum-turns', 'turns-normally');
      for (var i = 0; i < 4; i++) {
        final inspectOk = find.byKey(const Key('inspect-chip-matches-ok'));
        if (inspectOk.evaluate().isEmpty) {
          break;
        }
        await tapVisible(tester, inspectOk);
      }
      await answerObservation(tester, 'cycle-heat-setting', 'yes-heat-cycle');
      await answerObservation(tester, 'recent-overheat', 'no');
      await answerObservation(
        tester,
        'clothes-feel-after-cycle',
        'cold-and-still-damp',
      );

      await _acceptOrSelectPrimary(tester, 'heating-element-failed');

      expect(find.byKey(const Key('close-path-continue')), findsOneWidget);
      expect(find.byKey(const Key('answer-photo-gallery')), findsNothing);
      expect(find.byKey(const Key('voice-answer-mic')), findsNothing);

      await completeRepairReadinessIfPresent(tester);
      await completeGuidanceStepsIfPresent(tester);
      expect(find.byKey(const Key('answer-photo-gallery')), findsNothing);
      expect(find.byKey(const Key('voice-answer-mic')), findsNothing);
      expect(find.byKey(const Key('voice-answer-mic-close')), findsNothing);
      expect(find.byKey(const Key('visual-guide-use-camera')), findsNothing);
      expect(find.byKey(const Key('inspect-use-camera')), findsNothing);
      expect(find.byKey(const Key('inspect-camera-on-phone')), findsNothing);

      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));
      await saveSessionOutcome(
        tester,
        choiceKey: const Key('outcome-needs-professional'),
      );

      final dryer = deps.appliancesForCurrentHousehold().single;
      final history = deps.repairHistoryForAppliance(dryer.id);
      expect(history, hasLength(1));
      expect(
        history.single.outcome.closeKind,
        SessionCloseKind.calledProfessional,
      );
      expect(find.byKey(const Key('answer-photo-gallery')), findsNothing);
      expect(find.byKey(const Key('voice-answer-mic')), findsNothing);
    },
  );

  testWidgets(
    'first launch never requires camera; denied sim still opens a dryer session',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 22, 13),
        firstRunComplete: false,
        voiceAnswer: ScriptedVoiceAnswerListener(
          VoiceAnswerCapture.permissionDenied,
        ),
      );
      deps.simulateMediaDenied = true;

      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));
      expect(find.byKey(const Key('first-run-screen')), findsOneWidget);
      expect(find.byKey(const Key('answer-photo-camera')), findsNothing);
      expect(find.byKey(const Key('add-appliance-scan-rating-plate')), findsNothing);

      await tester.tap(find.byKey(const Key('first-run-skip-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('first-run-screen')), findsNothing);
      expect(find.byKey(const Key('create-household-button')), findsOneWidget);

      deps.createHousehold('First Launch Denied');
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-dryer-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-appliance-scan-rating-plate')), findsNothing);
      await tester.tap(find.byKey(const Key('add-appliance-save-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laundry Room Dryer'));
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await confirmNoHeatStarter(tester);

      expect(find.byKey(const Key('answer-photo-gallery')), findsNothing);
      expect(find.byKey(const Key('answer-photo-camera')), findsNothing);
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    },
  );

  testWidgets(
    'simulate denied hides scan; typed brand and model still save',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 18, 18, 5),
        ratingPlateOcr: _AvailableOcr(),
      );
      deps.simulateMediaDenied = true;
      deps.createHousehold('Denied Scan House');

      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));
      await tester.tap(find.byKey(const Key('add-dryer-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
      expect(find.byKey(const Key('add-appliance-scan-rating-plate')), findsNothing);
      expect(find.byKey(const Key('add-appliance-brand-field')), findsOneWidget);
      expect(find.byKey(const Key('add-appliance-model-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('add-appliance-brand-field')),
        'Whirlpool',
      );
      await tester.enterText(
        find.byKey(const Key('add-appliance-model-field')),
        'WED5000DW',
      );
      await tester.tap(find.byKey(const Key('add-appliance-save-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laundry Room Dryer'));
      await tester.pumpAndSettle();
      expect(find.text('Brand: Whirlpool'), findsOneWidget);
      expect(find.text('Model: WED5000DW'), findsOneWidget);
      expect(
        find.byKey(const Key('appliance-detail-scan-rating-plate')),
        findsNothing,
      );
    },
  );

  testWidgets('demo settings expose the simulate-denied switch', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 18, 10));
    deps.createHousehold('Denied Settings');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-simulate-media-denied'));
    await tester.tap(find.byKey(const Key('settings-simulate-media-denied')));
    await tester.pumpAndSettle();
    expect(deps.simulateMediaDenied, isTrue);
  });
}

Future<void> _acceptOrSelectPrimary(
  WidgetTester tester,
  String failureModeId,
) async {
  final accept = find.byKey(Key('accept-recommended-primary-$failureModeId'));
  if (accept.evaluate().isNotEmpty) {
    await tapVisible(tester, accept);
    return;
  }
  final skip = find.byKey(const Key('skip-to-best-guess'));
  if (skip.evaluate().isNotEmpty) {
    await tapVisible(tester, skip);
    if (accept.evaluate().isNotEmpty) {
      await tapVisible(tester, accept);
      return;
    }
  }
  await selectFailureMode(tester, failureModeId);
}
