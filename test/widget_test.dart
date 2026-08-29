import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

void main() {
  testWidgets('app opens the household start screen', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ModernButlerApp(
        dependencies: AppDependencies(clock: () => DateTime.utc(2026, 8, 18)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
  });
}
