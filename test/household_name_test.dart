import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/household.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  const apostropheName = "Mark's house";
  const quotedName = 'Mark\'s "guest" wing';

  group('household name encoding', () {
    test('domain snapshot JSON round-trip preserves apostrophe and quotes', () {
      final snapshot = DomainSnapshot(
        idCounter: 1,
        lastTimestamp: DateTime.utc(2026, 8, 9),
        currentHouseholdId: 'household-1',
        sessionIdByApplianceId: const {},
        packageRefsBySession: const {},
        households: [
          Household(
            id: 'household-1',
            name: quotedName,
            ownerUserId: 'developer-user',
            createdAt: DateTime.utc(2026, 8, 9),
            schemaVersion: '1.0',
          ),
        ],
        appliances: const [],
        sessions: const [],
        evidence: const [],
        evidenceLinks: const [],
        hypotheses: const [],
        hypothesisIdsBySession: const {},
        outcomes: const [],
      );

      final encoded = jsonEncode(snapshot.toJson());
      expect(encoded, contains("Mark's"));
      expect(encoded, contains('guest'));

      final restored = DomainSnapshot.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(restored.households.single.name, quotedName);
    });

    test('local store save and load preserves apostrophe household name', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final fixedTime = DateTime.utc(2026, 8, 9, 12);

      final deps = AppDependencies(
        clock: () => fixedTime,
        store: store,
      );
      deps.createHousehold(apostropheName);
      await deps.flushPersist();

      final restored = AppDependencies(
        clock: () => fixedTime,
        store: store,
      );
      await restored.restore();

      expect(restored.currentHousehold?.name, apostropheName);
    });
  });

  testWidgets('create household with apostrophe does not crash', (tester) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 9, 12),
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));

    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      apostropheName,
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.text(apostropheName), findsOneWidget);
    expect(find.byKey(const Key('add-dryer-button')), findsOneWidget);
  });
}
