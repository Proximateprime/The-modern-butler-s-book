import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/clue_copy.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';
import 'package:modern_butlers_book/helpers/tool_honesty.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

const _screwdriver = RepairReadinessItem(
  id: 'screwdriver',
  label: 'Screwdriver for Expert Mode panel work (optional)',
  optional: true,
  liveElectrical: false,
);

Evidence _row({
  required String id,
  required String templateId,
  required String observation,
  String? answer,
}) {
  return Evidence(
    id: id,
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: observation,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 9, 4, 15),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

Finder _cluesHistoryTiles() {
  return find.descendant(
    of: find.byKey(const Key('evidence-history-tile')),
    matching: find.byType(ListTile),
  );
}

void main() {
  test('version is 0.1.4+26', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppBuildNumber, '26');
    expect(kAppVersionLabel, '0.1.4+26');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+26'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('chrome count and Clues list share one filter', () {
    final mixed = [
      _row(
        id: 'starter',
        templateId: problemStarterComplaintTemplateId,
        observation: 'What you noticed',
        answer: 'No heat',
      ),
      _row(
        id: 'clue-heat',
        templateId: 'heat-observed',
        observation: 'Did you feel warmth?',
        answer: 'No warmth',
      ),
      _row(
        id: 'note',
        templateId: 'free-observation-note',
        observation: 'Typed note',
        answer: 'squeal',
      ),
      _row(
        id: 'verify',
        templateId: 'close-verify-thermal-fuse-open',
        observation: 'Still no warmth?',
        answer: 'Yes',
      ),
      _row(
        id: 'clue-filter',
        templateId: 'lint-filter-condition',
        observation: 'Lint filter',
        answer: 'Packed',
      ),
    ];
    final chrome = householdCluesInOrder(mixed);
    final list = interviewObservationsInOrder(mixed);
    expect(chrome.map((item) => item.id), ['clue-heat', 'clue-filter']);
    expect(
      list.map((item) => item.id).toSet(),
      chrome.map((item) => item.id).toSet(),
    );
    expect(chrome.length, list.length);
    expect(householdClueSummary(chrome.length), '2 clues');
    expect(
      chrome.every(isInterviewObservationEvidence),
      isTrue,
    );
    expect(
      mixed.where(isInterviewObservationEvidence).map((item) => item.id),
      chrome.map((item) => item.id),
    );

    final session = _read('lib/ui/session_screen.dart');
    expect(session, contains('final clues = householdCluesInOrder('));
    expect(session, contains('final clueCount = clues.length;'));
    expect(session, contains('for (final evidenceItem in clues.reversed)'));
    expect(session, contains('if (clues.isEmpty)'));
    expect(
      session,
      isNot(contains('in decisionContext.evidence.reversed)')),
    );
  });

  test('panel/invasive honesty matches cover, housing, rear, back, and tags', () {
    const cover = 'Remove the front cover to reach the belt.';
    const housing = 'Open the heater housing to locate the fuse.';
    const rear = 'Remove the rear cover to reach the motor.';
    const back = 'Take off the back cover.';
    for (final step in [cover, housing, rear, back]) {
      expect(isPanelOffWorkStep(step), isTrue, reason: step);
      expect(isInvasiveGuidanceStep(step), isTrue, reason: step);
      expect(stepInstructsOpeningPanelInvasiveAccess(step), isTrue, reason: step);
      expect(stepMentionsPanelInvasiveAccessSite(step), isTrue, reason: step);
    }

    expect(
      isPanelOffWorkStep(
        'Look at the back of the dryer at the visible vent hose.',
      ),
      isFalse,
    );
    expect(
      isInvasiveGuidanceStep(
        'Look behind the dryer at the visible vent hose for crush.',
      ),
      isFalse,
    );
    expect(
      isPanelOffWorkStep('Unplug the dryer before inspecting the lint housing.'),
      isFalse,
    );

    const tagged = RepairReadinessItem(
      id: 'hex-key',
      label: 'Hex key',
      optional: true,
      liveElectrical: false,
      requiresPanelOff: true,
    );
    expect(toolItemRequiresPanelOff(tagged), isTrue);
    final parsed = readinessItemsFromToolsRequired(const [
      'Rear-cover driver requiresPanelOff (optional)',
    ]);
    expect(parsed, hasLength(1));
    expect(parsed.single.requiresPanelOff, isTrue);
    expect(toolItemRequiresPanelOff(parsed.single), isTrue);

    final declined = guidanceStepsForToolHonesty(
      steps: const [
        'Unplug the dryer.',
        cover,
        housing,
        rear,
        back,
      ],
      items: const [_screwdriver],
      haveByToolId: const {'screwdriver': false},
      continueWithCaution: false,
    );
    expect(declined, ['Unplug the dryer.']);
    expect(declined.any(isPanelOffWorkStep), isFalse);
    expect(declined.any(isInvasiveGuidanceStep), isFalse);
  });

  testWidgets(
    'Clues chrome count matches Clues list after starter plus interview',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 15, 26));
      await openDryerSession(
        tester,
        deps,
        'Clues Honesty Filter',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final recorded =
          deps.repairSessionRepository.evidenceForSession(session.id);
      final clues = householdCluesInOrder(recorded);
      expect(recorded.length, greaterThan(clues.length));
      expect(
        recorded.any(
          (item) => item.templateId == problemStarterComplaintTemplateId,
        ),
        isTrue,
      );
      expect(
        clues.any(
          (item) => item.templateId == problemStarterComplaintTemplateId,
        ),
        isFalse,
      );
      expect(find.text(householdClueSummary(clues.length)), findsWidgets);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('context-evidence-count')))
            .data,
        householdClueSummary(clues.length),
      );
      await expandEvidenceHistory(tester);
      if (clues.isEmpty) {
        expect(find.byKey(const Key('empty-evidence-message')), findsOneWidget);
        expect(_cluesHistoryTiles(), findsOneWidget);
      } else {
        expect(find.byKey(const Key('empty-evidence-message')), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const Key('evidence-history-tile')),
            matching: find.textContaining('Answer:'),
          ),
          findsNWidgets(clues.length),
        );
      }
    },
  );
}
