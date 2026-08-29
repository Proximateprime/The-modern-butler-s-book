import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_inspect_steps.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  EvidenceTemplate template(String id) {
    return package.evidenceTemplates.firstWhere((item) => item.id == id);
  }

  group('whyAskThisQuestion', () {
    test('no-heat path templates all have non-empty structured copy', () {
      const ids = [
        'cycle-heat-setting',
        'heat-observed',
        'lint-filter-condition',
        'exterior-airflow',
        'vent-hose-condition',
        'drum-turns',
        'recent-overheat',
        'dry-time-change',
        'clothes-feel-after-cycle',
        'clothes-remain-damp',
        'heat-before-failure',
      ];
      for (final id in ids) {
        final explanation = whyAskThisQuestion(
          template: template(id),
          remainingModes: package.failureModes,
          packageModes: package.failureModes,
        );
        expect(explanation.body.trim(), isNotEmpty, reason: id);
        expect(explanation.body.toLowerCase(), isNot(contains('chain of thought')));
        expect(explanation.body.toLowerCase(), isNot(contains('algorithm')));
      }
    });

    test('uses package maps to name remaining hypotheses', () {
      final explanation = whyAskThisQuestion(
        template: template('heat-observed'),
        remainingModes: [
          package.failureModes.firstWhere((mode) => mode.id == 'thermal-fuse-open'),
          package.failureModes.firstWhere(
            (mode) => mode.id == 'heating-element-failed',
          ),
        ],
        packageModes: package.failureModes,
      );
      expect(explanation.code, WhyAskReasonCode.heatPolarity);
      expect(explanation.body, contains('Thermal fuse open'));
      expect(explanation.body, contains('Heating element open or failed'));
    });

    test('lint inspect uses the same airflow split, not a dump', () {
      final explanation = whyAskThisQuestion(
        template: template('lint-filter-condition'),
        inspectStep: dryerLintFilterInspectStep,
        remainingModes: package.failureModes,
        packageModes: package.failureModes,
      );
      expect(explanation.body.trim(), isNotEmpty);
      expect(explanation.code, WhyAskReasonCode.inspectLook);
      expect(explanation.body.toLowerCase(), contains('lint'));
    });
  });

  testWidgets(
    'dryer no-heat path exposes Why ask this? with non-empty content',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 19));
      await openDryerSession(
        tester,
        deps,
        'Why Ask No Heat',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();
      await answerElectricFuelIfAsked(tester);

      expect(find.byKey(const Key('why-ask-this-tile')), findsOneWidget);
      expect(find.text(UserFacingCopy.whyAskThis), findsOneWidget);

      await tester.tap(find.byKey(const Key('why-ask-this-tile')));
      await tester.pumpAndSettle();

      final body = tester.widget<Text>(find.byKey(const Key('why-ask-this-body')));
      expect(body.data, isNotNull);
      expect(body.data!.trim(), isNotEmpty);
    },
  );
}
