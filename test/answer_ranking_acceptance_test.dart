import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

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
      collectedAt: DateTime.utc(2026, 7, 22),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('acceptance paths', () {
    test('Path 1 — no-heat with drum turning ranks heat above no-turn', () {
      final evidenceList = [
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
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: evidenceList,
      );

      expect(standings['broken-drive-belt']!.isWeakened, isTrue);
      expect(standings['motor-failure']!.isWeakened, isTrue);
      expect(standings['heating-element-failed']!.isSupported, isTrue);
      expect(standings['thermal-fuse-open']!.rankLabelText, 'Possible');
      expect(
        standings['heating-element-failed']!.rankLabelText,
        'Possible',
      );

      final ordered = orderFailureModesByStanding(
        failureModes: package.failureModes,
        standings: standings,
      );
      final topIds = ordered.take(3).map((mode) => mode.id).toList();
      expect(topIds.contains('broken-drive-belt'), isFalse);
      expect(topIds.contains('relay-or-control-no-heat-output'), isFalse);
      expect(
        topIds.any(
          (id) =>
              id == 'heating-element-failed' ||
              id == 'thermal-fuse-open',
        ),
        isTrue,
      );
      expect(clearLeader(standings), isNull);
    });

    test(
      'Path 1b — no-heat + heat cycle + no overheat history clears heating primary',
      () {
        final standings = evaluateFailureModeStandings(
          package: package,
          evidence: [
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
          ],
        );

        expect(
          clearLeader(standings),
          anyOf('heating-element-failed', 'relay-or-control-no-heat-output'),
        );
        expect(
          standings['heating-element-failed']!.net,
          greaterThan(standings['thermal-fuse-open']!.net),
        );
      },
    );

    test('Path 2 — airflow restriction rises with damp + weak vent', () {
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

      expect(standings['restricted-exhaust-airflow']!.net, greaterThanOrEqualTo(2));
      expect(
        standings['restricted-exhaust-airflow']!.rankLabelText,
        'Stronger match',
      );
      expect(
        standings['restricted-exhaust-airflow']!.net,
        greaterThan(standings['clogged-lint-pathway']!.net),
      );
      expect(
        clearLeader(standings),
        'restricted-exhaust-airflow',
      );
    });

    test('Path 2b — hot-damp clothes exclude no-heat modes', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(
            templateId: 'clothes-feel-after-cycle',
            observation: 'After a full cycle, how do the clothes feel?',
            answer: 'Warm or hot but still damp',
          ),
          evidence(
            templateId: 'exterior-airflow',
            observation: 'Is exterior vent airflow weak?',
            answer: 'Weak',
          ),
        ],
      );

      expect(standings['heating-element-failed']!.isWeakened, isTrue);
      expect(standings['restricted-exhaust-airflow']!.isSupported, isTrue);
      expect(
        clearLeader(standings),
        'restricted-exhaust-airflow',
      );
    });

    test('Path 3 — hazard answer keeps absolute safety stop', () {
      final evidenceList = [
        evidence(
          templateId: 'hazard-observation',
          observation:
              'Do you observe a burning smell or smoke?',
          answer: 'Yes',
        ),
      ];
      final stop = evaluateSafetyStop(evidence: evidenceList);
      expect(stop, isNotNull);
      expect(stop!.reason, 'Possible fire or smoke hazard');

      final suggestion = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: evidenceList,
        topFailureModeIds: const ['restricted-exhaust-airflow'],
      );
      expect(suggestion?.id, isNot('hazard-observation'));
    });

    test('Path 4 — no evidence means no automatic Primary / clear leader', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: const [],
      );
      expect(clearLeader(standings), isNull);
      for (final standing in standings.values) {
        expect(standing.supportCount, 0);
        expect(standing.excludeCount, 0);
        expect(standing.isSupported, isFalse);
      }
    });

    test('Won’t-start — soft door + panel response favors door switch', () {
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
      expect(standings['electric-supply-connection-fault']!.isWeakened, isTrue);
    });

    test('Belt — motor runs while drum still clears broken belt', () {
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
      expect(standings['motor-failure']!.isWeakened, isTrue);
    });

    test('No-heat — recent overheat history clears thermal fuse', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
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
    });

    test(
      'No-heat — normal airflow + no overheat history clears heating element',
      () {
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
          anyOf('heating-element-failed', 'relay-or-control-no-heat-output'),
        );
        expect(
          clearLeader(standings),
          isNot('thermal-fuse-open'),
        );
        expect(standings['restricted-exhaust-airflow']!.isWeakened, isTrue);
      },
    );

    test(
      'No-heat — overheat history + weak airflow favors fuse over element',
      () {
        final standings = evaluateFailureModeStandings(
          package: package,
          evidence: [
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
            evidence(
              templateId: 'exterior-airflow',
              observation: 'Is exterior vent airflow weak?',
              answer: 'Weak',
            ),
          ],
        );

        expect(
          standings['thermal-fuse-open']!.net,
          greaterThan(standings['heating-element-failed']!.net),
        );
        expect(
          clearLeader(standings),
          anyOf('thermal-fuse-open', 'restricted-exhaust-airflow'),
        );
      },
    );

    test('No-heat — seated wall plug weakens supply vs heating element', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
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
            templateId: 'wall-plug-seated',
            observation:
                'Is the dryer wall plug fully pushed in (no looseness; cord and '
                'plug look normal)?',
            answer: 'Fully seated, looks normal',
          ),
        ],
      );

      expect(
        clearLeader(standings),
        'heating-element-failed',
      );
      expect(
        standings['electric-supply-connection-fault']!.isSupported,
        isFalse,
      );
    });

    test('Noise while tumbling favors rollers/idler over belt', () {
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
        ],
      );

      expect(standings['broken-drive-belt']!.isWeakened, isTrue);
      expect(standings['worn-drum-rollers']!.isSupported, isTrue);
      expect(
        clearLeader(standings),
        'worn-drum-rollers',
      );
    });
  });

  test('clear leader requires meaningful lead, not a single weak support', () {
    expect(
      clearLeaderFailureModeId(
        standings: const {
          'heating-element-failed': FailureModeStanding(
            supportCount: 1,
            excludeCount: 0,
          ),
          'thermal-fuse-open': FailureModeStanding(
            supportCount: 1,
            excludeCount: 0,
          ),
        },
      ),
      isNull,
    );

    expect(
      clearLeaderFailureModeId(
        standings: const {
          'restricted-exhaust-airflow': FailureModeStanding(
            supportCount: 3,
            excludeCount: 0,
          ),
          'heating-element-failed': FailureModeStanding(
            supportCount: 1,
            excludeCount: 0,
          ),
        },
      ),
      'restricted-exhaust-airflow',
    );

    expect(
      clearLeaderFailureModeId(
        standings: const {
          'heating-element-failed': FailureModeStanding(
            supportCount: 3,
            excludeCount: 0,
          ),
          'thermal-fuse-open': FailureModeStanding(
            supportCount: 2,
            excludeCount: 0,
          ),
        },
      ),
      'heating-element-failed',
    );
  });

  test('suggested next prefers templates that overlap top modes', () {
    final recorded = [
      evidence(
        templateId: 'heat-observed',
        observation: 'Is there any warmth after the dryer has run briefly?',
        answer: 'No warmth',
      ),
    ];
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: recorded,
    );
    final top = topSupportedFailureModeIds(standings: standings);
    final suggestion = suggestNextObservation(
      templates: package.evidenceTemplates,
      recordedEvidence: recorded,
      topFailureModeIds: top,
      energySource: ApplianceEnergySource.electric,
    );
    expect(suggestion, isNotNull);
    expect(
      suggestion!.relatedFailureModeIds.any(top.contains),
      isTrue,
    );
  });

  test('after Starts normally, auto-next prefers drum/heat branch', () {
    final recorded = [
      evidence(
        templateId: 'dryer-response',
        observation: 'What happens when you press Start?',
        answer: 'Starts normally',
      ),
    ];
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: recorded,
    );
    final top = topSupportedFailureModeIds(standings: standings);
    final suggestion = suggestNextObservation(
      templates: package.evidenceTemplates,
      recordedEvidence: recorded,
      topFailureModeIds: top,
    );
    expect(suggestion?.id, 'drum-turns');
  });

  test('package v1.4.0 ships ordered interview prompts', () {
    expect(package.version, '1.4.2');
    expect(package.evidenceTemplates.length, greaterThanOrEqualTo(17));
    final ids = package.evidenceTemplates.map((item) => item.id).toList();
    expect(ids.indexOf('dryer-response'), lessThan(ids.indexOf('drum-turns')));
    expect(ids.indexOf('drum-turns'), lessThan(ids.indexOf('heat-observed')));
    expect(
      ids.indexOf('recent-overheat'),
      lessThan(ids.indexOf('wall-plug-seated')),
    );
    expect(
      ids,
      containsAll([
        'panel-lights',
        'motor-audible',
        'recent-overheat',
        'wall-plug-seated',
        'clothes-feel-after-cycle',
      ]),
    );
  });
}
