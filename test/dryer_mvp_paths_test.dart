import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

/// Dryer guided MVP definition-of-done coverage for the four real-world paths.
void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  final commonalityById = {
    for (final mode in package.failureModes) mode.id: mode.commonality,
  };

  String? clearLeader(Map<String, FailureModeStanding> standings) {
    return clearLeaderFailureModeId(
      standings: standings,
      commonalityByModeId: commonalityById,
    );
  }

  Evidence evidence({
    required String templateId,
    required String observation,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-$answer',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: observation,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 7, 24),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('MVP path 1 — no heat / drum turns', () {
    test('recommends heating-element-failed without overheat history', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'drum-turns',
            observation: 'Does the drum turn during the cycle?',
            answer: 'Turns normally',
          ),
          evidence(
            templateId: 'heat-observed',
            observation:
                'Is there any warmth after the dryer has run briefly?',
            answer: 'No warmth',
          ),
          evidence(
            templateId: 'cycle-heat-setting',
            observation:
                'Is the dryer set to a heat cycle rather than air-only / fluff?',
            answer: 'Yes, heat cycle',
          ),
          evidence(
            templateId: 'recent-overheat',
            observation:
                'Has the dryer recently overheated, shut off mid-cycle from '
                'heat, or been used with a badly clogged vent?',
            answer: 'No',
          ),
          evidence(
            templateId: 'clothes-feel-after-cycle',
            observation: 'After a full cycle, how do the clothes feel?',
            answer: 'Cold and still damp',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'heating-element-failed',
      );
      expect(closePathForFailureMode('heating-element-failed'), isNotNull);
      expect(
        evaluateSafetyStop(evidence: const [], primaryFailureModeId: 'heating-element-failed'),
        isNull,
      );
    });

    test('heat-before-failure always-cold favors element over fuse', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'drum-turns',
            observation: 'Does the drum turn during the cycle?',
            answer: 'Turns normally',
          ),
          evidence(
            templateId: 'heat-observed',
            observation:
                'Is there any warmth after the dryer has run briefly?',
            answer: 'No warmth',
          ),
          evidence(
            templateId: 'cycle-heat-setting',
            observation:
                'Is the dryer set to a heat cycle rather than air-only / fluff?',
            answer: 'Yes, heat cycle',
          ),
          evidence(
            templateId: 'heat-before-failure',
            observation:
                'Before this no-heat problem, did the dryer still heat on a '
                'heat cycle?',
            answer: 'Never heated on this complaint / always cold',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'heating-element-failed',
      );
      expect(
        standings['heating-element-failed']!.net,
        greaterThan(standings['thermal-fuse-open']!.net),
      );
    });

    test('recommends thermal-fuse-open with overheat history', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'drum-turns',
            observation: 'Does the drum turn during the cycle?',
            answer: 'Turns normally',
          ),
          evidence(
            templateId: 'heat-observed',
            observation:
                'Is there any warmth after the dryer has run briefly?',
            answer: 'No warmth',
          ),
          evidence(
            templateId: 'cycle-heat-setting',
            observation:
                'Is the dryer set to a heat cycle rather than air-only / fluff?',
            answer: 'Yes, heat cycle',
          ),
          evidence(
            templateId: 'recent-overheat',
            observation:
                'Has the dryer recently overheated, shut off mid-cycle from '
                'heat, or been used with a badly clogged vent?',
            answer: 'Yes, very hot or shut off from heat',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'thermal-fuse-open',
      );
      expect(closePathForFailureMode('thermal-fuse-open'), isNotNull);
      expect(
        evaluateSafetyStop(
          evidence: const [],
          primaryFailureModeId: 'thermal-fuse-open',
        ),
        isNull,
      );
    });

    test('burning/smoke evidence hard-stops regardless of primary', () {
      final stop = evaluateSafetyStop(
        evidence: [
          evidence(
            templateId: 'hazard-observation',
            observation:
                'Do you observe a burning smell or smoke?',
            answer: 'Yes',
          ),
        ],
        primaryFailureModeId: 'heating-element-failed',
      );
      expect(stop?.reason, 'Possible fire or smoke hazard');
    });
  });

  group('MVP path 2 — won’t start', () {
    test('recommends door-switch-failure for soft door + panel response', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'dryer-response',
            observation: 'What happens when you press Start?',
            answer: 'Nothing happens',
          ),
          evidence(
            templateId: 'panel-lights',
            observation:
                'Do any lights, display, or control-panel indicators respond '
                'when you try to start?',
            answer: 'Yes, panel responds',
          ),
          evidence(
            templateId: 'door-closed-firmly',
            observation: 'Does the door click firmly shut and stay closed?',
            answer: 'Soft close / no click',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'door-switch-failure',
      );
      expect(closePathForFailureMode('door-switch-failure'), isNotNull);
    });

    test('recommends door-switch-failure when start works only while holding', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'dryer-response',
            observation: 'What happens when you press Start?',
            answer: 'Nothing happens',
          ),
          evidence(
            templateId: 'panel-lights',
            observation:
                'Do any lights, display, or control-panel indicators respond '
                'when you try to start?',
            answer: 'Yes, panel responds',
          ),
          evidence(
            templateId: 'door-closed-firmly',
            observation: 'Does the door click firmly shut and stay closed?',
            answer: 'Clicks shut firmly',
          ),
          evidence(
            templateId: 'door-held-closed-start',
            observation:
                'If you hold the door firmly closed and press Start, what happens?',
            answer: 'Starts only while I hold the door closed',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'door-switch-failure',
      );
    });

    test('recommends motor-failure for hum-without-start', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'dryer-response',
            observation: 'What happens when you press Start?',
            answer: 'Hums but does not start',
          ),
          evidence(
            templateId: 'motor-audible',
            observation:
                'While the dryer tries to run, do you hear the motor humming '
                'or whirring?',
            answer: 'Hum / struggle only',
          ),
        ],
      );

      expect(clearLeader(standings), 'motor-failure');
    });
  });

  group('MVP path 3 — drum doesn’t turn', () {
    test('recommends broken-drive-belt for motor-runs-drum-still', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'drum-turns',
            observation: 'Does the drum turn during the cycle?',
            answer: 'Motor runs, drum still',
          ),
          evidence(
            templateId: 'motor-audible',
            observation:
                'While the dryer tries to run, do you hear the motor humming '
                'or whirring?',
            answer: 'Yes, clear motor sound',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'broken-drive-belt',
      );
      expect(closePathForFailureMode('broken-drive-belt'), isNotNull);
    });

    test('recommends idler-pulley-wear for squeal while tumbling', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'drum-turns',
            observation: 'Does the drum turn during the cycle?',
            answer: 'Turns normally',
          ),
          evidence(
            templateId: 'running-noise',
            observation:
                'Do you hear a squeal, thump, grind, hum, or another sound?',
            answer: 'Squeal',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'idler-pulley-wear',
      );
      expect(closePathForFailureMode('idler-pulley-wear'), isNotNull);
    });

    test('recommends worn-drum-rollers for drum-timed thump', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'drum-turns',
            observation: 'Does the drum turn during the cycle?',
            answer: 'Turns normally',
          ),
          evidence(
            templateId: 'running-noise',
            observation:
                'Do you hear a squeal, thump, grind, hum, or another sound?',
            answer: 'Thump',
          ),
          evidence(
            templateId: 'noise-timing',
            observation:
                'Does the noise follow each drum turn, or is it a squeal that '
                'starts after a few minutes of tumbling?',
            answer: 'Repeats with each drum turn (thump/rumble)',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'worn-drum-rollers',
      );
      expect(closePathForFailureMode('worn-drum-rollers'), isNotNull);
    });
  });

  group('MVP path 4 — slow dry / weak airflow', () {
    test('recommends restricted-exhaust-airflow for damp + weak vent', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-remain-damp',
            observation: 'After a full cycle, are the clothes still damp?',
            answer: 'Still damp',
          ),
          evidence(
            templateId: 'exterior-airflow',
            observation: 'Is exterior vent airflow weak?',
            answer: 'Weak',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'restricted-exhaust-airflow',
      );
      expect(closePathForFailureMode('restricted-exhaust-airflow'), isNotNull);
    });

    test('hot-damp clothes exclude no-heat modes toward vent path', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-feel-after-cycle',
            observation: 'After a full cycle, how do the clothes feel?',
            answer: 'Warm or hot but still damp',
          ),
          evidence(
            templateId: 'vent-hose-condition',
            observation:
                'Is the visible vent hose crushed, kinked, or packed with lint?',
            answer: 'Yes, restricted',
          ),
        ],
      );

      expect(standings['heating-element-failed']!.isWeakened, isTrue);
      expect(
        clearLeader(standings),
        'restricted-exhaust-airflow',
      );
    });

    test('packed lint housing with a clean screen leads clogged-lint-pathway', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-remain-damp',
            observation: 'After a full cycle, are the clothes still damp?',
            answer: 'Still damp',
          ),
          evidence(
            templateId: 'clothes-feel-after-cycle',
            observation: 'After a full cycle, how do the clothes feel?',
            answer: 'Warm or hot but still damp',
          ),
          evidence(
            templateId: 'lint-filter-condition',
            observation: 'What do you observe on the lint filter?',
            answer: 'Clean',
          ),
          evidence(
            templateId: 'lint-housing-slot',
            observation:
                'With the lint filter pulled out, is the slot or housing packed '
                'with lint?',
            answer: 'Packed with lint',
          ),
          evidence(
            templateId: 'vent-hose-condition',
            observation:
                'Is the visible vent hose crushed, kinked, or packed with lint?',
            answer: 'Looks clear',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'clogged-lint-pathway',
      );
      expect(closePathForFailureMode('clogged-lint-pathway'), isNotNull);
    });
  });

  test('package version pins the guided MVP knowledge set', () {
    expect(package.version, '1.4.2');
    expect(package.evidenceTemplates.length, greaterThanOrEqualTo(30));
    expect(package.failureModes, hasLength(41));
    expect(
      package.evidenceTemplates.map((t) => t.id),
      containsAll([
        'lint-housing-slot',
        'noise-timing',
        'heat-before-failure',
        'door-held-closed-start',
      ]),
    );
  });
}
