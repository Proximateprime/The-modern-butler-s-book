import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/evidence_photo_picker.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/brand_mark.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

import 'support/session_test_helpers.dart';

class _DenyPhotoPicker implements EvidencePhotoPicker {
  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) async {
    throw const PhotoPermissionDeniedException();
  }
}

void main() {
  testWidgets('force splash shows brand mark then home', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 40));
    await prepareTallSurface(tester);
    await tester.pumpWidget(
      ModernButlerApp(dependencies: deps, forceBrandSplash: true),
    );
    await tester.pump();

    expect(find.byKey(const Key('splash-screen')), findsOneWidget);
    expect(find.byKey(const Key('brand-mark')), findsOneWidget);
    expect(find.text(UserFacingCopy.brandTagline), findsOneWidget);
    expect(find.byKey(const Key('create-household-button')), findsNothing);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splash-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(find.byType(BrandMark), findsWidgets);
  });

  testWidgets('widget tests skip splash by default', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 41));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    expect(find.byKey(const Key('splash-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
  });

  testWidgets('package load shows consistent loading copy', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23, 42),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Load Guide House');
    final dryer = deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(dependencies: deps)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-banner-package')), findsOneWidget);
    expect(find.text(UserFacingCopy.packageUnavailable), findsWidgets);

    await tester.tap(find.byKey(const Key('appliance-install-package')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('package-install-screen')), findsOneWidget);
    expect(find.byKey(const Key('error-banner-package')), findsWidgets);

    await tester.tap(find.byKey(const Key('package-install-local-button')));
    await tester.pump();
    expect(find.byKey(const Key('guide-loading-indicator')), findsOneWidget);
    expect(find.text(UserFacingCopy.guideLoading), findsOneWidget);
    await tester.pumpAndSettle();
    expect(deps.hasInstalledPackageFor('dryer'), isTrue);
  });

  testWidgets('camera denied shows a banner and the session continues', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 23, 43),
      photoPicker: _DenyPhotoPicker(),
    );
    await openDryerSession(tester, deps, 'Camera Banner');
    await tapVisible(tester, find.byKey(const Key('answer-photo-gallery')));
    await tester.pump();
    expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
    expect(find.text(UserFacingCopy.photoPermissionDenied), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
  });
}
