import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('version is 0.1.4+27', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppBuildNumber, '27');
    expect(kAppVersionLabel, '0.1.4+27');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+27'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('showProHandoff is gated on !_choseRepair', () {
    final screen = _read('lib/ui/session_screen.dart');
    expect(
      screen,
      contains(
        'final showProHandoff =\n'
        '            diyPro && !_choseRepair && !showProWarning && safeChecksDone;',
      ),
    );
  });

  testWidgets(
    'after I\'ll repair tap, Pro handoff chrome is not shown',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 14, 25));
      await openDryerSession(tester, deps, 'Diy Pro Handoff Gate');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await tapVisible(tester, find.byKey(const Key('close-path-continue')));
      expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));
      await completeInspectStepsIfPresent(tester);
      await markRepairReadinessHaveIfPresent(tester);
      final cont = find.byKey(const Key('close-path-tools-continue'));
      if (cont.evaluate().isNotEmpty) {
        await tapVisible(tester, cont);
      }
      await completeGuidanceStepsIfPresent(tester);
      expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
      expect(find.byKey(const Key('pro-handoff-why')), findsNothing);
      expect(find.byKey(const Key('pro-handoff-understand')), findsNothing);
    },
  );
}
