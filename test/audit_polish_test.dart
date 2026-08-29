import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/household_entitlement.dart';
import 'package:modern_butlers_book/helpers/household_tools.dart';
import 'package:modern_butlers_book/helpers/parts_cost.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';
import 'package:modern_butlers_book/ui/parts_cost_card.dart';

void main() {
  group('pro-only paths never quote a DIY repair', () {
    const proOnlyModeIds = [
      'thermal-fuse-open',
      'heating-element-failed',
      'door-switch-failure',
      'motor-failure',
      'electric-supply-connection-fault',
    ];

    test('every pro-only mode reports DIY out of scope', () {
      for (final id in proOnlyModeIds) {
        final path = closePathForFailureMode(id);
        expect(path, isNotNull, reason: '$id has no close path');
        expect(
          closePathDiyCannotComplete(path!),
          isTrue,
          reason: '$id should be pro-only',
        );
        expect(
          partsCostDiyOutOfScope(id),
          isTrue,
          reason: '$id must not offer a DIY price',
        );
      }
    });

    test('a DIY-completable path still shows both estimates', () {
      expect(partsCostDiyOutOfScope('broken-drive-belt'), isFalse);
      expect(partsCostDiyOutOfScope('restricted-exhaust-airflow'), isFalse);
      expect(partsCostDiyOutOfScope('clogged-washer-drain-filter'), isFalse);
      expect(partsCostDiyOutOfScope(null), isFalse);
      expect(partsCostDiyOutOfScope('not-a-real-mode'), isFalse);
    });

    testWidgets('thermal fuse card hides the DIY price and I\'ll repair', (
      tester,
    ) async {
      final parts = partsEstimatesForSelectedPath(
        parts: partsCostCatalog['thermal-fuse-open']!,
        failureModeId: 'thermal-fuse-open',
      );
      expect(parts, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartsCostCard(
              parts: parts,
              diyOutOfScope: partsCostDiyOutOfScope('thermal-fuse-open'),
              onIllRepair: () {},
              onCallPro: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('parts-cost-pro-only-note')), findsOneWidget);
      expect(find.textContaining('DIY ~'), findsNothing);
      expect(find.textContaining('Pro ~'), findsOneWidget);
      expect(find.byKey(const Key('parts-cost-ill-repair')), findsNothing);
      expect(find.byKey(const Key('parts-cost-call-pro')), findsOneWidget);
    });

    testWidgets('a DIY path keeps the DIY price and I\'ll repair', (
      tester,
    ) async {
      final parts = partsEstimatesForSelectedPath(
        parts: partsCostCatalog['broken-drive-belt']!,
        failureModeId: 'broken-drive-belt',
      );
      expect(parts, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartsCostCard(
              parts: parts,
              diyOutOfScope: partsCostDiyOutOfScope('broken-drive-belt'),
              onIllRepair: () {},
              onCallPro: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('parts-cost-pro-only-note')), findsNothing);
      expect(find.textContaining('DIY ~'), findsWidgets);
      expect(find.byKey(const Key('parts-cost-ill-repair')), findsOneWidget);
    });

    test('the early notice explains scope without shaming or panic', () {
      final blob = '$proScopeWarningTitle $proScopeNoticeBody'.toLowerCase();
      expect(blob, contains('pro'));
      expect(blob, contains('safe checks'));
      for (final word in ['dangerous', 'you failed', 'warning!', 'urgent']) {
        expect(blob, isNot(contains(word)));
      }
    });
  });

  group('no live-electrical affordances', () {
    test('meters are not offered in the addable tools catalog', () {
      final ids = catalogHouseholdTools.map((tool) => tool.id).toSet();
      expect(ids, isNot(contains('multimeter')));
      expect(ids, isNot(contains('voltage-tester')));
      expect(ids, contains('screwdriver'));
      expect(ids, contains('shallow-pan'));
    });

    test('a meter saved by an older build still renders a label', () {
      expect(householdToolLabel('multimeter'), 'Multimeter');
      expect(householdToolLabel('voltage-tester'), 'Voltage Tester');
    });
  });

  group('debug chrome', () {
    test('Household Pro toggle is debug-only and Store is still stubbed', () {
      expect(kStoreBillingWired, isFalse);
      // Tests run in debug, so the toggle is visible here and compiled out of
      // a release build.
      expect(householdProToggleVisible, isTrue);
    });
  });
}
