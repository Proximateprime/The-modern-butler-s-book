import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/observation_prompt_quality.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';

void main() {
  final repo = KnowledgePackageRepository();
  final package = repo.loadById('dryer-core')!;
  final index = repo.authoringIndexFor('dryer-core')!;
  const ranking = RankingService();

  Evidence e({
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

  RankingSnapshot snap(List<Evidence> recorded) {
    return ranking.evaluate(
      package: package,
      evidence: recorded,
      authoringIndex: index,
    );
  }

  int rankOf(List<String> order, String modeId) => order.indexOf(modeId);

  void expectNoRecommend(List<Evidence> recorded) {
    expect(
      recommendPrimaryFailureModeId(
        standings: evaluateFailureModeStandings(
          package: package,
          evidence: recorded,
        ),
        evidence: recorded,
        templates: package.evidenceTemplates,
      ),
      isNull,
    );
  }

  void expectGuidanceHow(Iterable<String> templateIds) {
    for (final id in templateIds) {
      final block = observationGuidanceForTemplate(id);
      expect(block, isNotNull, reason: 'missing guidance for $id');
      expect(block!.how, isNotEmpty, reason: 'missing HOW for $id');
    }
  }

  group('Top 10 complaint path proof', () {
    test('A — No heat, drum turns: heat family, element leads, gated until earned', () {
      final early = [
        e(templateId: 'heat-observed', answer: 'No warmth'),
        e(templateId: 'drum-turns', answer: 'Turns normally'),
      ];
      final families = inferActiveObservationFamilies(
        recordedEvidence: early,
        templates: package.evidenceTemplates,
        authoringIndex: index,
      );
      expect(families, contains(ObservationFamily.heat));
      expect(families, contains(ObservationFamily.drum));

      final earlySnap = snap(early);
      expectNoRecommend(early);
      expect(
        rankOf(earlySnap.orderedFailureModes.map((m) => m.id).toList(),
            'relay-or-control-no-heat-output'),
        greaterThan(
          rankOf(earlySnap.orderedFailureModes.map((m) => m.id).toList(),
              'heating-element-failed'),
        ),
      );

      final earned = [
        ...early,
        e(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        e(templateId: 'recent-overheat', answer: 'No'),
        e(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Cold and still damp',
        ),
        e(
          templateId: 'wall-plug-seated',
          answer: 'Fully seated, looks normal',
        ),
      ];
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: earned,
          ),
          evidence: earned,
          templates: package.evidenceTemplates,
        ),
        'heating-element-failed',
      );
      expectGuidanceHow(['heat-observed', 'cycle-heat-setting', 'recent-overheat']);
    });

    test('B — Won\'t start: start family, door-switch rises, gated early', () {
      final early = [
        e(templateId: 'dryer-response', answer: 'Nothing happens'),
      ];
      final families = inferActiveObservationFamilies(
        recordedEvidence: early,
        templates: package.evidenceTemplates,
        authoringIndex: index,
      );
      expect(families, contains(ObservationFamily.start));
      expectNoRecommend(early);

      final next = suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: early,
        topFailureModeIds: snap(early).topFailureModeIds,
        authoringIndex: index,
      );
      expect(next?.id, anyOf('panel-lights', 'door-closed-firmly'));

      final earned = [
        ...early,
        e(templateId: 'panel-lights', answer: 'Yes, panel responds'),
        e(templateId: 'door-closed-firmly', answer: 'Soft close / no click'),
        e(templateId: 'control-lock-status', answer: 'Lock off / not shown'),
        e(templateId: 'motor-audible', answer: 'Silent — no motor sound'),
      ];
      final order = snap(earned).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(order, 'door-switch-failure'),
        lessThan(rankOf(order, 'motor-failure')),
      );
      expect(
        rankOf(order, 'door-switch-failure'),
        lessThan(rankOf(order, 'start-switch-failure')),
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: earned,
          ),
          evidence: earned,
          templates: package.evidenceTemplates,
        ),
        'door-switch-failure',
      );
      expectGuidanceHow(['dryer-response', 'door-closed-firmly', 'panel-lights']);
    });

    test('C — Motor hums, drum doesn\'t turn: start-cap leads, gated early', () {
      final early = [
        e(templateId: 'dryer-response', answer: 'Hums but does not start'),
        e(templateId: 'motor-audible', answer: 'Hum / struggle only'),
      ];
      expectNoRecommend(early);

      final earned = [
        ...early,
        e(templateId: 'drum-turns', answer: 'Turns briefly then stops'),
        e(templateId: 'door-closed-firmly', answer: 'Clicks shut firmly'),
      ];
      final order = snap(earned).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(order, 'start-capacitor-or-start-assist-weak'),
        lessThan(rankOf(order, 'motor-failure')),
      );
      expect(
        rankOf(order, 'start-capacitor-or-start-assist-weak'),
        lessThan(rankOf(order, 'broken-drive-belt')),
      );
      expectGuidanceHow(['motor-audible', 'dryer-response', 'drum-turns']);
    });

    test('D — Slow dry / very hot: vent vs overheat paths separate', () {
      final slowDry = [
        e(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Warm or hot but still damp',
        ),
        e(templateId: 'exterior-airflow', answer: 'Weak'),
        e(templateId: 'dry-time-change', answer: 'Much longer'),
      ];
      final slowOrder = snap(slowDry).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(slowOrder, 'restricted-exhaust-airflow'),
        lessThan(rankOf(slowOrder, 'heating-element-failed')),
      );
      expectNoRecommend(slowDry);

      final veryHot = [
        e(templateId: 'heat-observed', answer: 'Very hot'),
        e(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        e(
          templateId: 'recent-overheat',
          answer: 'Yes, very hot or shut off from heat',
        ),
        e(templateId: 'exterior-airflow', answer: 'Weak'),
        e(
          templateId: 'clothes-feel-after-cycle',
          answer: 'Warm or hot but still damp',
        ),
      ];
      final hotOrder = snap(veryHot).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(hotOrder, 'cycling-thermostat-stuck-closed'),
        lessThan(rankOf(hotOrder, 'restricted-exhaust-airflow')),
      );
      expectGuidanceHow(['exterior-airflow', 'heat-observed', 'dry-time-change']);
    });

    test('E — Burning smell / smoke: immediate hazard hard-stop', () {
      final hazard = [
        e(templateId: 'hazard-observation', answer: 'Yes'),
      ];
      final stop = evaluateSafetyStop(evidence: hazard);
      expect(stop, isNotNull);
      expect(stop!.reason, contains('fire'));

      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: hazard,
      );
      expect(
        standings['electrical-burning-smell-hazard']!.isSupported,
        isTrue,
      );
      expectNoRecommend(hazard);
      expectGuidanceHow(['hazard-observation']);
    });

    test('F — Squealing while running: idler leads, noise family', () {
      final early = [
        e(templateId: 'drum-turns', answer: 'Turns normally'),
      ];
      final families = inferActiveObservationFamilies(
        recordedEvidence: early,
        templates: package.evidenceTemplates,
        authoringIndex: index,
      );
      expect(families, contains(ObservationFamily.drum));

      final earned = [
        ...early,
        e(templateId: 'running-noise', answer: 'Squeal'),
      ];
      final order = snap(earned).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(order, 'idler-pulley-wear'),
        lessThan(rankOf(order, 'broken-drive-belt')),
      );
      expect(
        rankOf(order, 'idler-pulley-wear'),
        lessThan(rankOf(order, 'motor-failure')),
      );
      expectNoRecommend(earned);
      expectGuidanceHow(['running-noise', 'drum-turns']);
    });

    test('G — Auto-dry ends early: moisture sensor path, not no-heat', () {
      final early = [
        e(templateId: 'heat-observed', answer: 'Normal heat'),
        e(templateId: 'exterior-airflow', answer: 'Normal'),
      ];
      expectNoRecommend(early);

      final earned = [
        ...early,
        e(
          templateId: 'moisture-sensor-bars',
          answer: 'Auto-dry ends early, clothes damp',
        ),
        e(templateId: 'clothes-remain-damp', answer: 'Still damp'),
        e(templateId: 'dry-time-change', answer: 'Somewhat longer'),
      ];
      final order = snap(earned).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(order, 'moisture-sensor-bars-contaminated'),
        lessThan(rankOf(order, 'heating-element-failed')),
      );
      expect(
        rankOf(order, 'moisture-sensor-bars-contaminated'),
        lessThan(rankOf(order, 'restricted-exhaust-airflow')),
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: earned,
          ),
          evidence: earned,
          templates: package.evidenceTemplates,
        ),
        'moisture-sensor-bars-contaminated',
      );
      expectGuidanceHow(['moisture-sensor-bars', 'heat-observed']);
    });

    test('H — Timed dry only: sensor rises, timed-OK answer excludes sensor', () {
      final sensorPath = [
        e(templateId: 'heat-observed', answer: 'Normal heat'),
        e(
          templateId: 'moisture-sensor-bars',
          answer: 'Auto-dry ends early, clothes damp',
        ),
        e(templateId: 'exterior-airflow', answer: 'Normal'),
      ];
      final order = snap(sensorPath).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(order, 'moisture-sensor-bars-contaminated'),
        lessThan(rankOf(order, 'heating-element-failed')),
      );

      final timedOk = [
        e(templateId: 'heat-observed', answer: 'Normal heat'),
        e(
          templateId: 'moisture-sensor-bars',
          answer: 'Bars look clean, timed dry works normally',
        ),
      ];
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: timedOk,
      );
      expect(
        standings['moisture-sensor-bars-contaminated']!.isSupported,
        isFalse,
      );
      expectGuidanceHow(['moisture-sensor-bars']);
    });

    test('I — Dead: no lights / no response: supply path, external checks only', () {
      final early = [
        e(templateId: 'panel-lights', answer: 'No lights at all'),
        e(templateId: 'dryer-response', answer: 'Nothing happens'),
      ];
      expectNoRecommend(early);

      final earned = [
        ...early,
        e(templateId: 'motor-audible', answer: 'Silent — no motor sound'),
        e(
          templateId: 'outlet-power-check',
          answer: 'Outlet appears dead / breaker tripped',
        ),
      ];
      final deadOrder = snap(earned).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(deadOrder, 'no-power-at-outlet'),
        lessThan(rankOf(deadOrder, 'door-switch-failure')),
      );
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: earned,
          ),
          evidence: earned,
          templates: package.evidenceTemplates,
        ),
        'no-power-at-outlet',
      );

      final path = closePathForFailureMode('no-power-at-outlet');
      expect(path, isNotNull);
      final joined = path!.safeGuidanceSteps.join(' ').toLowerCase();
      expect(joined, contains('do not measure live voltage'));
      expectGuidanceHow(['panel-lights', 'outlet-power-check', 'dryer-response']);
    });

    test('J — Gas no heat / no ignition: professional-only, no DIY gas repair', () {
      final early = [
        e(templateId: 'gas-dryer-type', answer: 'Yes, gas dryer'),
      ];
      expectNoRecommend(early);

      final earned = [
        ...early,
        e(templateId: 'gas-ignition-observed', answer: 'No flame / no ignition'),
        e(templateId: 'heat-observed', answer: 'No warmth'),
        e(templateId: 'cycle-heat-setting', answer: 'Yes, heat cycle'),
        e(templateId: 'drum-turns', answer: 'Turns normally'),
      ];
      final order = snap(earned).orderedFailureModes.map((m) => m.id).toList();
      expect(
        rankOf(order, 'gas-dryer-no-ignition-professional-only'),
        lessThan(rankOf(order, 'heating-element-failed')),
      );
      expect(
        standingsFor(earned)['heating-element-failed']!.net,
        lessThan(standingsFor(earned)['gas-dryer-no-ignition-professional-only']!.net),
      );

      final path = closePathForFailureMode(
        'gas-dryer-no-ignition-professional-only',
      );
      expect(path, isNotNull);
      expect(path!.allowResolvedWhenConfirmed, isFalse);
      expect(path.preferProfessionalWhenNotConfirmed, isTrue);
      final joined = path.safeGuidanceSteps.join(' ').toLowerCase();
      expect(joined, contains('do not attempt gas ignition repair'));
      expect(joined, isNot(contains('replace igniter')));

      final electricExclude = evaluateFailureModeStandings(
        package: package,
        evidence: [e(templateId: 'gas-dryer-type', answer: 'Electric dryer')],
      );
      expect(
        electricExclude['gas-dryer-no-ignition-professional-only']!.isSupported,
        isFalse,
      );
      expectGuidanceHow(['gas-dryer-type', 'gas-ignition-observed']);
    });
  });
}

Map<String, FailureModeStanding> standingsFor(List<Evidence> recorded) {
  return evaluateFailureModeStandings(
    package: KnowledgePackageRepository().loadById('dryer-core')!,
    evidence: recorded,
  );
}
