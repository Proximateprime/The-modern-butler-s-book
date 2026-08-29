import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('home mounts a product shell and keeps apostrophe household names', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 14, 12),
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));

    expect(find.byType(Wordmark), findsOneWidget);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(find.byKey(const Key('theme-toggle-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      "Mark's house",
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.text("Mark's house"), findsOneWidget);
    expect(find.byKey(const Key('add-dryer-button')), findsOneWidget);
  });

  testWidgets('session chrome stays mounted with question, chips, back, and exit', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 14, 12),
    );
    await openDryerSession(
      tester,
      dependencies,
      'Demo Shell Household',
      skipProblemStarter: false,
    );
    await confirmNoHeatStarter(tester);

    expect(find.byType(SessionChromeBar), findsOneWidget);
    expect(find.byKey(const Key('session-exit-button')), findsOneWidget);
    expect(find.byType(SafetyStatusLight), findsOneWidget);
    expect(find.text('Current question'), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.byKey(const Key('other-observations-picker')), findsOneWidget);
    expect(find.text('Something else I noticed'), findsOneWidget);
    expect(
      find.text('Is there any warmth after the dryer has run briefly?'),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('session-exit-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appliance-detail-name')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Demo Shell Household'), findsOneWidget);
  });
}
