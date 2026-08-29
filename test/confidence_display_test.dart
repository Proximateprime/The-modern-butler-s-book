import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/confidence_display.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  FailureMode mode(String id) {
    return FailureMode(
      id: id,
      label: id,
      description: 'desc',
      commonality: FailureModeCommonality.common,
      safetyNotes: '',
    );
  }

  test('early questioning never returns standing chrome or percents', () {
    const stronger = FailureModeStanding(supportCount: 3, excludeCount: 0);
    const possible = FailureModeStanding(supportCount: 1, excludeCount: 0);
    const less = FailureModeStanding(supportCount: 0, excludeCount: 2);
    expect(
      householdStandingPhrase(
        standing: stronger,
        surface: ConfidenceDisplaySurface.earlyQuestion,
      ),
      isNull,
    );
    expect(
      householdStandingPhrase(
        standing: possible,
        surface: ConfidenceDisplaySurface.earlyQuestion,
      ),
      isNull,
    );
    expect(
      householdStandingPhrase(
        standing: less,
        surface: ConfidenceDisplaySurface.earlyQuestion,
      ),
      isNull,
    );
    expect(
      rankedPossibilitiesForDisplay(
        orderedFailureModes: [mode('a')],
        standings: {'a': stronger},
        surface: ConfidenceDisplaySurface.earlyQuestion,
      ),
      isEmpty,
    );
  });

  test('summary phrases are honest and never look like percentages', () {
    const stronger = FailureModeStanding(supportCount: 3, excludeCount: 0);
    const possible = FailureModeStanding(supportCount: 1, excludeCount: 0);
    const less = FailureModeStanding(supportCount: 0, excludeCount: 2);
    expect(
      householdStandingPhrase(
        standing: stronger,
        surface: ConfidenceDisplaySurface.diagnosisSummary,
      ),
      contains('High'),
    );
    expect(
      householdStandingPhrase(
        standing: possible,
        surface: ConfidenceDisplaySurface.diagnosisSummary,
      ),
      contains('also consistent'),
    );
    expect(
      householdStandingPhrase(
        standing: less,
        surface: ConfidenceDisplaySurface.diagnosisSummary,
      ),
      contains('less likely given your answers'),
    );
    for (final surface in ConfidenceDisplaySurface.values) {
      for (final standing in [stronger, possible, less]) {
        final phrase = householdStandingPhrase(
          standing: standing,
          surface: surface,
        );
        if (phrase != null) {
          expect(standingLooksLikePercentage(phrase), isFalse);
        }
      }
    }
    expect(
      householdStandingPhrase(
        standing: possible,
        surface: ConfidenceDisplaySurface.recommendation,
      ),
      isNull,
    );
  });

  testWidgets(
    'early questions have no permanent Stronger match / Possible chrome',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 20));
      await openDryerSession(tester, deps, 'Early Confidence House');

      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);
      expect(find.text(UserFacingCopy.bestMatchSoFar), findsNothing);
      expect(find.text('Stronger match'), findsNothing);
      expect(find.text('Less likely given current evidence'), findsNothing);

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await tapVisible(tester, find.byKey(const Key('failure-modes-tile')));
      await tester.pumpAndSettle();

      expect(find.text('Stronger match'), findsNothing);
      expect(find.text('Possible'), findsNothing);
      expect(find.text('Less likely given current evidence'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);
    },
  );

  testWidgets(
    'diagnosis summary lists ranked possibilities without fake precision',
    (tester) async {
      final package = KnowledgePackageRepository().loadById('dryer-core')!;
      expect(package.id, 'dryer-core');
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 20, 5));
      await openDryerSession(tester, deps, 'Summary Confidence House');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectObservation(tester, 'cycle-heat-setting');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-yes-heat-cycle')),
      );
      await selectFailureMode(tester, 'heating-element-failed');

      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
      expect(find.byKey(const Key('current-conclusion-humble')), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(
        find.byKey(const Key('remaining-likely-modes-card')),
        findsOneWidget,
      );
      expect(find.text('Possible'), findsNothing);
      expect(find.text('Stronger match'), findsNothing);
      expect(
        find.textContaining('also consistent with some of your answers'),
        findsWidgets,
      );
    },
  );
}
