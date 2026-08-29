import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/session_timeline.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/evidence_photo_picker.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/evidence_photo_thumb.dart';
import 'package:modern_butlers_book/ui/how_we_got_here_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

class _FakePhotoPicker implements EvidencePhotoPicker {
  _FakePhotoPicker({
    this.path = '/tmp/butler-photo-test.jpg',
    this.deny = false,
  });

  final String path;
  final bool deny;
  EvidencePhotoOrigin? lastOrigin;

  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) async {
    lastOrigin = origin;
    if (deny) {
      throw const PhotoPermissionDeniedException();
    }
    return path;
  }
}

Evidence _photoEvidence(String path) {
  return Evidence(
    id: 'photo-1',
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.photo,
    observation: 'Photo',
    answer: 'Attached photo',
    collectedAt: DateTime.utc(2026, 8, 16, 22),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.photo,
    schemaVersion: '1.0',
    localPhotoPath: path,
  );
}

void main() {
  test('evidence stores a local photo path without diagnosing', () {
    final evidence = _photoEvidence('/local/dryer.jpg');
    expect(evidence.localPhotoPath, '/local/dryer.jpg');
    expect(evidence.type, EvidenceType.photo);
  });

  test('permission denied maps to household copy', () {
    expect(
      userFacingErrorMessage(const PhotoPermissionDeniedException()),
      UserFacingCopy.photoPermissionDenied,
    );
  });

  test('local photo path survives persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      store: store,
    );
    first.createHousehold('Photo House');
    final dryer = first.addDryer();
    final sessionId = first.startOrResumeSession(dryer);
    first.sessionCoordinator.addEvidence(
      evidence: Evidence(
        id: first.nextId('evidence'),
        sessionId: sessionId,
        applianceId: dryer.id,
        type: EvidenceType.photo,
        observation: 'Photo',
        answer: 'Attached photo',
        collectedAt: first.nextTimestamp(),
        collectedInState:
            first.repairSessionRepository.getSession(sessionId)!.currentState,
        source: EvidenceSource.photo,
        schemaVersion: '1.0',
        localPhotoPath: '/local/persist.jpg',
      ),
      evidenceLinkId: first.nextId('evidence-link'),
    );
    await first.flushPersist();

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      store: store,
    );
    await second.restore();
    final restored = second.repairSessionRepository.listAllEvidence().single;
    expect(restored.localPhotoPath, '/local/persist.jpg');
    expect(restored.type, EvidenceType.photo);
  });

  test('photo evidence does not change ranking', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final answers = [
      Evidence(
        id: 'e-heat',
        sessionId: 'session-1',
        applianceId: 'appliance-1',
        type: EvidenceType.structuredAnswer,
        observation: 'Is there any warmth after the dryer has run briefly?',
        answer: 'No warmth',
        templateId: 'heat-observed',
        collectedAt: DateTime.utc(2026, 8, 16, 22),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
        localPhotoPath: '/local/ignored-by-rank.jpg',
      ),
    ];
    final withPhoto = [...answers, _photoEvidence('/local/extra.jpg')];
    final without = evaluateFailureModeStandings(
      package: package,
      evidence: answers,
    );
    final withIt = evaluateFailureModeStandings(
      package: package,
      evidence: withPhoto,
    );
    expect(
      withIt.map((key, value) => MapEntry(key, value.net)),
      without.map((key, value) => MapEntry(key, value.net)),
    );
  });

  test('timeline includes photo thumbnail path', () {
    final items = sessionTimelineObservations([
      _photoEvidence('/local/timeline.jpg'),
    ]);
    expect(items, hasLength(1));
    expect(items.single.localPhotoPath, '/local/timeline.jpg');
    expect(items.single.answer, 'Attached photo');
  });

  testWidgets('question gallery attach stores path on the answer', (
    tester,
  ) async {
    final picker = _FakePhotoPicker();
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      photoPicker: picker,
    );
    await openDryerSession(tester, deps, 'Photo Question');
    await selectObservation(tester, 'clothes-remain-damp');
    await tapVisible(tester, find.byKey(const Key('answer-photo-gallery')));
    expect(picker.lastOrigin, EvidencePhotoOrigin.gallery);
    await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));

    final recorded = deps.repairSessionRepository.listAllEvidence();
    expect(
      recorded.any((item) => item.localPhotoPath == picker.path),
      isTrue,
    );

    await tapVisible(tester, find.byKey(const Key('evidence-history-tile')));
    expect(find.byType(EvidencePhotoThumb), findsWidgets);
  });

  testWidgets('timeline tile shows a thumbnail for a local photo', (
    tester,
  ) async {
    await prepareTallSurface(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HowWeGotHereTile(
            observations: [
              SessionTimelineObservation(
                prompt: 'Were they still damp?',
                answer: 'Still damp',
                localPhotoPath: '/tmp/butler-photo-test.jpg',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('how-we-got-here-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('how-we-got-here-photo-0')), findsOneWidget);
  });

  testWidgets('something else camera attach is photo evidence only', (
    tester,
  ) async {
    final picker = _FakePhotoPicker();
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      photoPicker: picker,
    );
    await openDryerSession(tester, deps, 'Photo Other');
    await tapVisible(
      tester,
      find.byKey(const Key('other-observations-picker')),
    );
    await tapVisible(tester, find.byKey(const Key('other-photo-camera')));
    expect(picker.lastOrigin, EvidencePhotoOrigin.camera);

    final photos =
        deps.repairSessionRepository
            .listAllEvidence()
            .where((item) => item.type == EvidenceType.photo)
            .toList();
    expect(photos, hasLength(1));
    expect(photos.single.localPhotoPath, picker.path);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
  });

  testWidgets('permission denied shows a human message and continues', (
    tester,
  ) async {
    final picker = _FakePhotoPicker(deny: true);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 22),
      photoPicker: picker,
    );
    await openDryerSession(tester, deps, 'Photo Denied');
    await tapVisible(tester, find.byKey(const Key('answer-photo-gallery')));
    await tester.pump();
    expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
    expect(find.text(UserFacingCopy.photoPermissionDenied), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(deps.repairSessionRepository.listAllEvidence(), isEmpty);
  });
}
