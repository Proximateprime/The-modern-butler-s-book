import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
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
const _flashlight = RepairReadinessItem(
  id: 'flashlight',
  label: 'Flashlight (optional)',
  optional: true,
  liveElectrical: false,
);
const _pan = RepairReadinessItem(
  id: 'shallow-pan',
  label: 'Shallow pan and towel',
  optional: false,
  liveElectrical: false,
);
const _meter = RepairReadinessItem(
  id: 'multimeter',
  label: 'Multimeter',
  optional: false,
  liveElectrical: true,
);

const _fuseSteps = [
  'Check airflow before opening the cabinet. Pull the lint filter and look at the screen.',
  'Unplug the dryer and turn OFF the dryer circuit breaker at the panel.',
  'Do not measure live voltage, test the fuse while energized, or bypass it.',
  'With the dryer unplugged and the breaker off, you may open an accessible heater service panel to locate the thermal fuse.',
  'If you can reach it without live testing, you may replace the fuse with an exact-match part.',
];

void main() {
  test('version is 0.1.4+25', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+25');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+25'));
  });

  test('no tools / I don’t screwdriver does not offer panel-off as next step', () {
    final noTools = guidanceStepsForToolHonesty(
      steps: _fuseSteps,
      items: const [_screwdriver, _flashlight],
      haveByToolId: const {
        'screwdriver': false,
        'flashlight': false,
      },
      continueWithCaution: false,
    );
    expect(noTools.any(isPanelOffWorkStep), isFalse);
    expect(noTools.any(isInvasiveGuidanceStep), isFalse);
    expect(
      noTools.first,
      contains('lint filter'),
    );
    expect(
      noTools.join(' '),
      isNot(contains('heater service panel')),
    );
    expect(noTools.join(' '), contains('Unplug the dryer'));
    expect(noTools.join(' '), contains('Do not measure live voltage'));

    final taggedPanel = RepairReadinessItem(
      id: 'hex-key',
      label: 'Hex key requiresPanelOff',
      optional: true,
      liveElectrical: false,
      requiresPanelOff: true,
    );
    expect(toolItemRequiresPanelOff(taggedPanel), isTrue);
    expect(
      toolItemRequiresPanelOff(
        const RepairReadinessItem(
          id: 'flashlight',
          label: 'Flashlight',
          optional: true,
          liveElectrical: false,
          requiresPanelOff: false,
        ),
      ),
      isFalse,
    );
    expect(
      toolItemRequiresMeter(
        const RepairReadinessItem(
          id: 'custom-probe',
          label: 'Custom probe requiresMeter',
          optional: false,
          liveElectrical: false,
          requiresMeter: true,
        ),
      ),
      isTrue,
    );

    final parsed = readinessItemsFromToolsRequired(const [
      'Hex key requiresPanelOff (optional)',
      'Clamp meter requiresMeter',
    ]);
    expect(parsed, hasLength(2));
    expect(parsed[0].requiresPanelOff, isTrue);
    expect(parsed[1].requiresMeter, isTrue);

    expect(
      guidanceEmptyBecauseHonesty(
        authoredSteps: const [
          'With the dryer unplugged, you may open an accessible heater service panel.',
        ],
        items: const [_screwdriver],
        haveByToolId: const {'screwdriver': false},
        continueWithCaution: false,
      ),
      isTrue,
    );
    expect(
      guidanceEmptyBecauseHonesty(
        authoredSteps: const [
          'Check airflow before opening the cabinet. Pull the lint filter.',
        ],
        items: const [_screwdriver],
        haveByToolId: const {'screwdriver': false},
        continueWithCaution: false,
      ),
      isFalse,
    );

    final declinedDriver = guidanceStepsForToolHonesty(
      steps: _fuseSteps,
      items: const [_screwdriver, _flashlight],
      haveByToolId: const {
        'screwdriver': false,
        'flashlight': true,
      },
      continueWithCaution: false,
    );
    expect(declinedDriver.any(isPanelOffWorkStep), isFalse);
    expect(
      declinedDriver.join(' '),
      isNot(contains('heater service panel')),
    );
  });

  test('I have screwdriver still keeps panel-off when that work is listed', () {
    final haveTools = guidanceStepsForToolHonesty(
      steps: _fuseSteps,
      items: const [_screwdriver, _flashlight],
      haveByToolId: const {
        'screwdriver': true,
        'flashlight': true,
      },
      continueWithCaution: false,
    );
    expect(haveTools.any(isPanelOffWorkStep), isTrue);
    expect(haveTools.join(' '), contains('heater service panel'));
  });

  test('optional flashlight I don’t does not strip panel-off', () {
    final gated = guidanceStepsForToolHonesty(
      steps: _fuseSteps,
      items: const [_screwdriver, _flashlight],
      haveByToolId: const {
        'screwdriver': true,
        'flashlight': false,
      },
      continueWithCaution: false,
    );
    expect(gated.join(' '), contains('heater service panel'));
  });

  test('missing required tool without caution still empties invasive path', () {
    expect(
      guidanceStepsForToolHonesty(
        steps: const [
          'Look for an accessible drain filter at the front or bottom.',
          'Open only the user-accessible filter or pump trap.',
        ],
        items: const [_pan, _flashlight],
        haveByToolId: const {
          'shallow-pan': false,
          'flashlight': false,
        },
        continueWithCaution: false,
      ),
      isEmpty,
    );
    final caution = guidanceStepsForToolHonesty(
      steps: const [
        'Look for an accessible drain filter at the front or bottom.',
        'Open only the user-accessible filter or pump trap.',
      ],
      items: const [_pan, _flashlight],
      haveByToolId: const {
        'shallow-pan': false,
        'flashlight': true,
      },
      continueWithCaution: true,
    );
    expect(caution, [
      'Look for an accessible drain filter at the front or bottom.',
    ]);
  });

  test('declined meter does not paint a meter how-to; do-not lines stay', () {
    final gated = guidanceStepsForToolHonesty(
      steps: const [
        'Unplug the dryer.',
        'Do not meter live circuits or jumper the fuse.',
        'Use a multimeter to measure live voltage at the fuse.',
      ],
      items: const [_meter],
      haveByToolId: const {'multimeter': false},
      continueWithCaution: true,
    );
    expect(gated, [
      'Unplug the dryer.',
      'Do not meter live circuits or jumper the fuse.',
    ]);
  });

  test('safety stop still fires when tools were declined', () {
    final capabilities = toolHonestyFromChecklist(
      items: const [_screwdriver, _flashlight],
      haveByToolId: const {
        'screwdriver': false,
        'flashlight': false,
      },
    );
    expect(capabilities.recordedNoTools, isTrue);
    expect(capabilities.blocksPanelOff, isTrue);
    final stop = evaluateSafetyStop(
      evidence: [
        Evidence(
          id: 'e1',
          sessionId: 's1',
          applianceId: 'a1',
          type: EvidenceType.structuredAnswer,
          observation: 'Any smoke, burning smell, sparking, or melting?',
          answer: 'Yes',
          templateId: 'hazard-observation',
          collectedAt: DateTime.utc(2026, 9, 4, 2),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ],
    );
    expect(stop, isNotNull);
    expect(stop!.reason.toLowerCase(), contains('fire or smoke'));
  });

  test('unmarked checklist is not treated as no-tools', () {
    final capabilities = toolHonestyFromChecklist(
      items: const [_screwdriver],
      haveByToolId: const {},
    );
    expect(capabilities.recordedNoTools, isFalse);
    expect(capabilities.declinedPanelOff, isFalse);
  });

  testWidgets(
    'Expert Mode + I don’t screwdriver never offers heater panel as next action',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 3));
      deps.setExpertMode(enabled: true, adultConfirmed: true);
      await openDryerSession(tester, deps, 'Honesty No Tools');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-missing-screwdriver')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-missing-flashlight')),
      );
      await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));
      await acknowledgeProScopeIfPresent(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      for (var i = 0; i < 20; i++) {
        expect(find.textContaining('heater service panel'), findsNothing);
        expect(find.textContaining('Open the heater service panel'), findsNothing);
        expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
        final did = find.byKey(const Key('guidance-did-this'));
        if (did.evaluate().isEmpty) {
          break;
        }
        await tapVisible(tester, did);
      }
      expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
      expect(find.textContaining('heater service panel'), findsNothing);
    },
  );

  testWidgets(
    'Expert Mode + I have screwdriver still reaches the panel-off step',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 4));
      deps.setExpertMode(enabled: true, adultConfirmed: true);
      await openDryerSession(tester, deps, 'Honesty Has Tools');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await completeRepairReadinessIfPresent(tester);

      var sawPanel = false;
      for (var i = 0; i < 20; i++) {
        if (find.textContaining('heater service panel').evaluate().isNotEmpty) {
          sawPanel = true;
          break;
        }
        final did = find.byKey(const Key('guidance-did-this'));
        if (did.evaluate().isEmpty) {
          break;
        }
        await tapVisible(tester, did);
      }
      expect(sawPanel, isTrue);
    },
  );

  testWidgets(
    'no-tools path still hard-stops fire or smoke',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 5));
      deps.setExpertMode(enabled: true, adultConfirmed: true);
      await openDryerSession(tester, deps, 'Honesty Safety Stop');
      await selectObservation(tester, 'hazard-observation');
      await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
      expect(find.textContaining('fire or smoke'), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('outcome-resolved')), findsNothing);
    },
  );
}
