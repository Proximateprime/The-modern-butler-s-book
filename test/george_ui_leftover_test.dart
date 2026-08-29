import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/blocking_reason.dart';
import 'package:modern_butlers_book/helpers/repair_history_display.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/appliance_detail_screen.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('stop banner title uses Needs a professional', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 14));
    await openDryerSession(
      tester,
      deps,
      'Leftover Stop Title',
      skipProblemStarter: false,
    );
    await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('safety-stop-title'))).data,
      'Needs a professional',
    );
    expect(find.text('Stop — Call a professional'), findsNothing);
    expect(find.text('Calling a professional'), findsNothing);
    expect(find.textContaining('Unplug if it is safe'), findsWidgets);
    expect(find.textContaining('ventilate'), findsWidgets);
    expect(
      find.textContaining(UserFacingCopy.safetyStopOfficial),
      findsWidgets,
    );
    expect(find.text(blockingReasonSafetyLine), findsOneWidget);
    expect(blockingReasonSafetyLine, contains('Needs a professional'));
    expect(
      safetyStopDisplayCopy(
        const SafetyStop(reason: 'Possible fire or smoke hazard'),
      ),
      contains(UserFacingCopy.safetyStopOfficial),
    );

    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    expect(find.byKey(const Key('recent-activity-title')), findsNothing);
  });

  test('sessionSafetyLevelFor professional drives Check carefully without close path', () {
    final level = sessionSafetyLevelFor(
      evidence: const [],
      primaryFailureModeId: 'thermal-fuse-open',
    );
    expect(level, 'professional');
    expect(
      safetyLightForSession(
        safetyStop: false,
        closePathActive: false,
        safetyLevel: level,
      ),
      SafetyLightKind.caution,
    );
  });

  test('safetyLightForSession(professional) is caution, not calm', () {
    expect(
      safetyLightForSession(
        safetyStop: false,
        closePathActive: false,
        safetyLevel: 'professional',
      ),
      SafetyLightKind.caution,
    );
    expect(
      safetyLightForSession(
        safetyStop: false,
        closePathActive: false,
        safetyLevel: 'professional',
      ),
      isNot(SafetyLightKind.calm),
    );
    expect(
      safetyLightForSession(
        safetyStop: false,
        closePathActive: false,
        safetyLevel: 'professional',
      ),
      isNot(SafetyLightKind.watch),
    );
    expect(
      safetyLightForSession(
        safetyStop: true,
        closePathActive: false,
        safetyLevel: 'professional',
      ),
      SafetyLightKind.stop,
    );
    expect(
      safetyLightForSession(
        safetyStop: false,
        closePathActive: false,
        safetyLevel: 'clear',
      ),
      SafetyLightKind.calm,
    );
    expect(
      safetyLightForSession(
        safetyStop: true,
        closePathActive: false,
        safetyLevel: 'stop',
      ),
      SafetyLightKind.stop,
    );
  });

  test('top-load history label uses lid', () {
    final outcome = SessionOutcome(
      sessionId: 'latch-1',
      resolutionStatus: SessionResolutionStatus.resolved,
      closeKind: SessionCloseKind.fixed,
      immediateCause:
          'The door or lid switch is open, so the cycle will not start.',
      contributingFactors: const [],
      preventiveActions: const [],
      verified: true,
      schemaVersion: '1.0',
      rankingLeaderFailureModeId: 'washer-door-not-latched',
      rankingLeaderLabel: 'Door not latched',
    );
    expect(
      repairHistoryHeadline(
        outcome,
        washerLoadStyle: WasherLoadStyle.topLoad,
      ),
      'Lid latch path — verified',
    );
    expect(
      repairHistoryHeadline(
        outcome,
        washerLoadStyle: WasherLoadStyle.frontLoad,
      ),
      'Door latch path — verified',
    );
    expect(
      repairHistoryHeadline(outcome),
      'Door or lid latch path — verified',
    );
    expect(outcome.rankingLeaderFailureModeId, 'washer-door-not-latched');
  });

  testWidgets('top-load appliance history shows Lid latch path', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 14, 10));
    deps.createHousehold('Lid History House');
    final washer = deps.addWasher(washerLoadStyle: WasherLoadStyle.topLoad);
    final sessionId = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      rankingLeaderFailureModeId: 'washer-door-not-latched',
      immediateCause:
          'The door or lid switch is open, so the cycle will not start.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ApplianceDetailScreen(
          dependencies: deps,
          appliance: washer,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Lid latch path'), findsWidgets);
    expect(find.text('Door latch path'), findsNothing);
  });

  testWidgets('history ListTile does not overflow at Size(360, 800)', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 14, 20));
    deps.createHousehold('Phone History House');
    final dryer = deps.addDryer(
      name:
          'Laundry Room Super Long Dryer Name That Should Ellipsize On A Phone',
    );
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.calledProfessional,
      whatFixedIt:
          'Stopped after a sharp burning-electrical smell near the cabinet '
          'and a crushed vent hose behind the dryer that still needs a tech',
      userNote:
          'Also told the technician about the lint behind the drum and the '
          'warm plug that we did not keep using',
    );

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed') || text.contains('OVERFLOWING')) {
        overflows.add(text);
      }
      previousOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(Key('recent-outcome-$sessionId')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('recent-outcome-$sessionId')), findsOneWidget);
    expect(find.text('Needs a professional'), findsWidgets);
    expect(find.byKey(Key('export-repair-$sessionId')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });

  testWidgets(
    'thermal-fuse primary emits professional and Check carefully, not Stop',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 14, 30));
      await openDryerSession(tester, deps, 'Fuse Lamp House');
      final dryer = deps.appliancesForCurrentHousehold().single;
      final sessionId = deps.startOrResumeSession(dryer);
      await selectFailureMode(tester, 'thermal-fuse-open');

      expect(deps.buildDecisionContext(sessionId).safetyLevel, 'professional');
      expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
      expect(
        tester.widget<SafetyStatusLight>(find.byType(SafetyStatusLight)).kind,
        SafetyLightKind.caution,
      );
    },
  );

  testWidgets(
    'appliance-detail history title does not overflow at Size(360, 800)',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 14, 40));
      deps.createHousehold('Detail Title House');
      final dryer = deps.addDryer();
      final sessionId = deps.startOrResumeSession(dryer);
      final session = deps.repairSessionRepository.getSession(sessionId)!;
      const longSymptom =
          'Clothes stay damp after a long heat cycle and the cabinet near the '
          'lint slot and crushed vent hose still feels warmer than it should '
          'on a phone-width history row';
      deps.sessionCoordinator.addEvidence(
        evidence: Evidence(
          id: deps.nextId('evidence'),
          sessionId: sessionId,
          applianceId: dryer.id,
          type: EvidenceType.structuredAnswer,
          observation: 'What is going on?',
          answer: longSymptom,
          templateId: problemStarterComplaintTemplateId,
          collectedAt: deps.nextTimestamp(),
          collectedInState: session.currentState,
          source: EvidenceSource.user,
          schemaVersion: session.schemaVersion,
        ),
        evidenceLinkId: deps.nextId('evidence-link'),
      );
      deps.endSession(
        sessionId: sessionId,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Cleared the crushed vent hose',
        rootCause:
            'Restricted exhaust overheated the cabinet and packed lint behind '
            'the drum for months without a vent cleaning on this phone-width row',
        userNote:
            'Also told the technician about the warm plug we did not keep using '
            'and the crushed hose behind the dryer that still needs a clamp',
        contributingFactors: const [
          'Skipped filter cleaning for a long stretch of weekly loads',
        ],
        preventiveActions: const [
          'Check pockets before washing and clean the lint filter about every '
              'thirty days so this does not pack again',
        ],
      );

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overflows = <String>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed') || text.contains('OVERFLOWING')) {
          overflows.add(text);
        }
        previousOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ApplianceDetailScreen(
            dependencies: deps,
            appliance: dryer,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(Key('repair-history-headline-$sessionId')),
      );
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(
        find.byKey(Key('repair-history-headline-$sessionId')),
      );
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      final causeText = tester.widget<Text>(
        find.byKey(Key('repair-history-cause-$sessionId')),
      );
      expect(causeText.maxLines, 1);
      expect(causeText.overflow, TextOverflow.ellipsis);
      final extraText = tester.widget<Text>(
        find.byKey(Key('repair-history-extra-0-$sessionId')),
      );
      expect(extraText.maxLines, 1);
      expect(extraText.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    },
  );
}
