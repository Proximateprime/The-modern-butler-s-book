import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/degraded_mode.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/evidence_photo_picker.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/services/voice_answer.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/error_banner.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

class _DenyPhotoPicker implements EvidencePhotoPicker {
  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) async {
    throw const PhotoPermissionDeniedException();
  }
}

Future<void> _pumpBanner(WidgetTester tester, DegradedModeKind kind) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DegradedModeBanner(kind: kind),
      ),
    ),
  );
}

void _expectDegradedActions(DegradedModeKind kind) {
  expect(find.byKey(degradedBannerKey(kind)), findsOneWidget);
  expect(find.text(degradedModeMessage(kind)), findsOneWidget);
  expect(find.text(UserFacingCopy.continueManually), findsOneWidget);
  expect(find.text(UserFacingCopy.startFresh), findsOneWidget);
  expect(find.text(UserFacingCopy.ok), findsOneWidget);
  expect(find.textContaining('StateError'), findsNothing);
  expect(find.textContaining('#0'), findsNothing);
  expect(find.textContaining('Exception:'), findsNothing);
}

void main() {
  test('corrupt snapshot and resume failures map to human copy', () {
    expect(
      userFacingErrorMessage(const CorruptSnapshotException()),
      UserFacingCopy.corruptSnapshot,
    );
    expect(
      userFacingErrorMessage(const ResumeFailedException()),
      UserFacingCopy.resumeFailed,
    );
  });

  testWidgets('package missing banner has human actions', (tester) async {
    await _pumpBanner(tester, DegradedModeKind.packageMissing);
    _expectDegradedActions(DegradedModeKind.packageMissing);
  });

  testWidgets('offline banner has human actions', (tester) async {
    await _pumpBanner(tester, DegradedModeKind.offline);
    _expectDegradedActions(DegradedModeKind.offline);
  });

  testWidgets('camera denied banner has human actions', (tester) async {
    await _pumpBanner(tester, DegradedModeKind.cameraDenied);
    _expectDegradedActions(DegradedModeKind.cameraDenied);
  });

  testWidgets('mic denied banner has human actions', (tester) async {
    await _pumpBanner(tester, DegradedModeKind.micDenied);
    _expectDegradedActions(DegradedModeKind.micDenied);
  });

  testWidgets('corrupt snapshot banner has human actions', (tester) async {
    await _pumpBanner(tester, DegradedModeKind.corruptSnapshot);
    _expectDegradedActions(DegradedModeKind.corruptSnapshot);
  });

  testWidgets('resume failed banner has human actions', (tester) async {
    await _pumpBanner(tester, DegradedModeKind.resumeFailed);
    _expectDegradedActions(DegradedModeKind.resumeFailed);
  });

  testWidgets('home shows package-missing banner on the appliance', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Degraded Package');
    final dryer = deps.addDryer();
    await prepareTallSurface(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(dependencies: deps)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-banner-package')), findsOneWidget);
    expect(find.text(UserFacingCopy.continueManually), findsWidgets);
    expect(find.text(UserFacingCopy.startFresh), findsWidgets);
    expect(find.text(UserFacingCopy.ok), findsWidgets);
    expect(find.textContaining('#0'), findsNothing);
  });

  testWidgets('offline home shows a degraded banner', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 1),
      isOnline: () => false,
    );
    deps.createHousehold('Degraded Offline');
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('error-banner-offline')), findsOneWidget);
    expect(find.text(UserFacingCopy.offlineGuidesStillWork), findsOneWidget);
    expect(find.text(UserFacingCopy.ok), findsOneWidget);
    expect(find.textContaining('stack'), findsNothing);
  });

  testWidgets('camera denied session shows degraded banner', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 2),
      photoPicker: _DenyPhotoPicker(),
    );
    await openDryerSession(tester, deps, 'Degraded Camera');
    await tapVisible(tester, find.byKey(const Key('answer-photo-gallery')));
    await tester.pump();

    expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
    expect(find.text(UserFacingCopy.continueManually), findsOneWidget);
    expect(find.text(UserFacingCopy.startFresh), findsOneWidget);
    expect(find.text(UserFacingCopy.ok), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.byKey(const Key('answer-photo-gallery')), findsNothing);
    expect(find.byKey(const Key('answer-photo-camera')), findsNothing);
  });

  testWidgets('mic denied session shows degraded banner', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 3),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.permissionDenied,
      ),
    );
    await openDryerSession(tester, deps, 'Degraded Mic');
    await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));

    expect(find.byKey(const Key('error-banner-microphone')), findsOneWidget);
    expect(find.text(UserFacingCopy.continueManually), findsOneWidget);
    expect(find.text(UserFacingCopy.ok), findsOneWidget);
    expect(find.byKey(const Key('voice-answer-mic')), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });

  testWidgets('corrupt snapshot restore shows home banner', (tester) async {
    SharedPreferences.setMockInitialValues({
      'modern_butler_domain_v1': '{not-valid-json',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 4),
      store: store,
    );
    await deps.restore();
    expect(deps.snapshotCorrupt, isTrue);

    await prepareTallSurface(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(dependencies: deps)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-banner-snapshot')), findsOneWidget);
    expect(find.text(UserFacingCopy.corruptSnapshot), findsOneWidget);
    expect(find.text(UserFacingCopy.continueManually), findsOneWidget);
    expect(find.text(UserFacingCopy.startFresh), findsOneWidget);
    expect(find.text(UserFacingCopy.ok), findsOneWidget);
    expect(find.textContaining('#0'), findsNothing);
  });

  testWidgets('unknown resume question shows resume-failed banner', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 5),
    );
    deps.createHousehold('Degraded Resume');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.saveSessionUiResume(
      sessionId,
      const SessionUiResumeState(
        pendingObservationTemplateId: 'does-not-exist',
        starterConfirmed: true,
      ),
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          dependencies: deps,
          appliance: dryer,
          sessionId: sessionId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-banner-resume')), findsOneWidget);
    expect(find.text(UserFacingCopy.resumeFailed), findsOneWidget);
    expect(find.text(UserFacingCopy.continueManually), findsOneWidget);
    expect(find.text(UserFacingCopy.startFresh), findsOneWidget);
    expect(find.text(UserFacingCopy.ok), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
  });
}
