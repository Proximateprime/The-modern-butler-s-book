import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';

void main() {
  final repo = KnowledgePackageRepository();
  final package = repo.loadById('dryer-core')!;
  final index = repo.authoringIndexFor('dryer-core')!;
  const ranking = RankingService();

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-${answer.hashCode}',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: templateId,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 7, 25),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  List<String> orderedIds(List<Evidence> recorded) {
    return ranking
        .evaluate(
          package: package,
          evidence: recorded,
          authoringIndex: index,
        )
        .orderedFailureModes
        .map((mode) => mode.id)
        .toList();
  }

  int rankOf(List<String> order, String modeId) => order.indexOf(modeId);

  group('discrimination hardening — sibling collision groups', () {
    test('no heat / drum turns: relay does not lead on generic early answers', () {
      final generic = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
      ];
      final order = orderedIds(generic);

      expect(
        rankOf(order, 'relay-or-control-no-heat-output'),
        greaterThan(rankOf(order, 'heating-element-failed')),
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: generic,
          ),
          evidence: generic,
          templates: package.evidenceTemplates,
        ),
        isNull,
      );
    });

    test('no heat / drum turns: relay overtakes element after relay-heat-output', () {
      final before = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'panel-lights', answer: 'Yes, panel responds'),
        evidence(templateId: 'exterior-airflow', answer: 'Normal'),
      ];
      final after = [
        ...before,
        evidence(
          templateId: 'relay-heat-output',
          answer: 'No heat despite heat cycle and tumble',
        ),
      ];

      final orderBefore = orderedIds(before);
      final orderAfter = orderedIds(after);

      expect(
        rankOf(orderBefore, 'relay-or-control-no-heat-output'),
        greaterThan(rankOf(orderBefore, 'heating-element-failed')),
      );
      expect(
        rankOf(orderAfter, 'relay-or-control-no-heat-output'),
        lessThan(rankOf(orderAfter, 'heating-element-failed')),
      );
    });

    test('overheat path: thermal fuse leads high-limit when weak airflow arrives', () {
      final before = [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
        evidence(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        evidence(
          templateId: 'recent-overheat',
          answer: 'Yes, very hot or shut off from heat',
        ),
      ];
      final after = [
        ...before,
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Cold and still damp',
        ),
      ];

      final orderAfter = orderedIds(after);

      expect(
        rankOf(orderAfter, 'thermal-fuse-open'),
        lessThan(rankOf(orderAfter, 'high-limit-thermostat-open')),
      );
      expect(
        rankOf(orderAfter, 'thermal-fuse-open'),
        lessThan(rankOf(orderAfter, 'restricted-exhaust-airflow')),
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: after,
          ),
          evidence: after,
          templates: package.evidenceTemplates,
          commonalityByModeId: {
            for (final mode in package.failureModes) mode.id: mode.commonality,
          },
        ),
        'thermal-fuse-open',
      );
    });

    test('slow dry: restricted vent leads when weak airflow, not no-heat modes', () {
      final recorded = [
        evidence(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Warm or hot but still damp',
        ),
        evidence(templateId: 'exterior-airflow', answer: 'Weak'),
        evidence(templateId: 'dry-time-change', answer: 'Much longer'),
      ];
      final order = orderedIds(recorded);

      expect(
        rankOf(order, 'restricted-exhaust-airflow'),
        lessThan(rankOf(order, 'heating-element-failed')),
      );
      expect(
        rankOf(order, 'restricted-exhaust-airflow'),
        lessThan(rankOf(order, 'thermal-fuse-open')),
      );
    });

    test('sensor dry ends early: moisture sensor leads heating element on normal heat', () {
      final recorded = [
        evidence(templateId: 'heat-observed', answer: 'Normal heat'),
        evidence(templateId: 'exterior-airflow', answer: 'Normal'),
        evidence(
          templateId: 'moisture-sensor-bars',
          answer: 'Auto-dry ends early, clothes damp',
        ),
      ];
      final order = orderedIds(recorded);

      expect(
        rankOf(order, 'moisture-sensor-bars-contaminated'),
        lessThan(rankOf(order, 'heating-element-failed')),
      );
      expect(
        standingsFor(recorded)['heating-element-failed']!.isWeakened,
        isTrue,
      );
    });

    test('motor hum / brief tumble: start capacitor ranks above motor failure', () {
      final recorded = [
        evidence(templateId: 'dryer-response', answer: 'Hums but does not start'),
        evidence(templateId: 'motor-audible', answer: 'Hum / struggle only'),
        evidence(templateId: 'drum-turns', answer: 'Turns briefly then stops'),
        evidence(templateId: 'door-closed-firmly', answer: 'Clicks shut firmly'),
      ];
      final order = orderedIds(recorded);

      expect(
        rankOf(order, 'start-capacitor-or-start-assist-weak'),
        lessThan(rankOf(order, 'motor-failure')),
      );
    });

    test('squeal while tumbling: idler leads belt and motor paths', () {
      final recorded = [
        evidence(templateId: 'drum-turns', answer: 'Turns normally'),
        evidence(templateId: 'running-noise', answer: 'Squeal'),
      ];
      final order = orderedIds(recorded);

      expect(
        rankOf(order, 'idler-pulley-wear'),
        lessThan(rankOf(order, 'broken-drive-belt')),
      );
      expect(
        rankOf(order, 'idler-pulley-wear'),
        lessThan(rankOf(order, 'motor-failure')),
      );
    });

    test('gas no ignition stays professional-only and electric excludes it', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(templateId: 'gas-dryer-type', answer: 'Electric dryer'),
        ],
      );

      expect(
        standings['gas-dryer-no-ignition-professional-only']!.excludeCount,
        greaterThan(0),
      );
      expect(
        standings['gas-dryer-no-ignition-professional-only']!.isSupported,
        isFalse,
      );
    });
  });
}

Map<String, FailureModeStanding> standingsFor(List<Evidence> recorded) {
  return evaluateFailureModeStandings(
    package: KnowledgePackageRepository().loadById('dryer-core')!,
    evidence: recorded,
  );
}
