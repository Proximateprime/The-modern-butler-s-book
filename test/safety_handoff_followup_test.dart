import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/pro_handoff.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('version is 0.1.4+27', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+27');
  });

  test('hazard-observation prompt does not bundle repeated stopping', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final hazard = package.evidenceTemplates.firstWhere(
      (template) => template.id == 'hazard-observation',
    );
    final prompt = hazard.promptText.toLowerCase();
    expect(prompt, contains('burning'));
    expect(prompt, contains('smoke'));
    expect(prompt, isNot(contains('repeated stopping')));
    expect(prompt, isNot(contains('stopping')));
  });

  test('hazard-observation Yes is still a fire stop; stopping alone is not', () {
    expect(
      evaluateSafetyStop(evidence: [_hazardYes()])?.reason,
      'Possible fire or smoke hazard',
    );
    expect(
      evaluateSafetyStop(
        evidence: [
          _evidence(
            templateId: 'hazard-observation',
            observation: 'Do you observe a burning smell or smoke?',
            answer: 'The motor keeps stopping',
          ),
        ],
      ),
      isNull,
    );
    expect(
      evaluateSafetyStop(
        evidence: [
          _evidence(
            observation: 'The motor keeps stopping repeatedly.',
            answer: 'Yes',
          ),
        ],
      ),
      isNull,
    );
  });

  test(
    'safety-stop Symptom is the mid-session hazard, not empty or leftover starter',
    () {
      final hazardOnly = [_hazardYes()];
      expect(symptomFromEvidence(hazardOnly), hazardSymptomLabel);
      expect(
        symptomForSession(evidence: hazardOnly),
        hazardSymptomLabel,
      );

      final leftoverStarter = [
        _evidence(
          templateId: 'problem-starter-complaint',
          observation: "What's going on with the dryer?",
          answer: 'Won’t start',
        ),
        _hazardYes(),
      ];
      expect(
        symptomForSession(
          evidence: leftoverStarter,
          startSymptom: 'Won’t start',
        ),
        hazardSymptomLabel,
      );

      final text = formatProHandoffForSession(
        evidence: hazardOnly,
        applianceName: 'Laundry Room Dryer',
        outcome: _supplyLeaderOutcome(startSymptom: null),
      );
      expect(text, contains('Symptom: $hazardSymptomLabel'));
      expect(text, isNot(contains('Symptom: —')));

      final spoken = formatProHandoffSpokenForSession(
        evidence: hazardOnly,
        applianceName: 'Laundry Room Dryer',
        outcome: _supplyLeaderOutcome(startSymptom: null),
      );
      expect(spoken, contains('Symptom: $hazardSymptomLabel'));
      expect(spoken.toLowerCase(), isNot(contains('symptom: not recorded')));
    },
  );

  test(
    'hard stop leftover ranking leader is labeled leftover; whyStopping is the hazard',
    () {
      const leftover = 'Loose or faulty electric supply connection';
      final text = formatProHandoffForSession(
        evidence: [_hazardYes()],
        applianceName: 'Laundry Room Dryer',
        outcome: _supplyLeaderOutcome(startSymptom: null),
      );
      expect(text, contains('Why we’re stopping'));
      expect(text.toLowerCase(), contains('needs a professional'));
      expect(text.toLowerCase(), contains('fire or smoke'));
      expect(text, contains(leftoverLeaderPrefix));
      expect(text, contains(leftover));
      expect(text, contains('not why we stopped'));
      expect(
        text,
        isNot(contains('This is the leading household-guide match')),
      );

      final spoken = formatProHandoffSpokenForSession(
        evidence: [_hazardYes()],
        applianceName: 'Laundry Room Dryer',
        outcome: _supplyLeaderOutcome(startSymptom: null),
      );
      expect(spoken, contains(leftoverLeaderPrefix));
      expect(spoken, contains(leftover));
      expect(spoken.toLowerCase(), contains('needs a professional'));
      expect(spoken.toLowerCase(), contains('fire or smoke'));
    },
  );

  testWidgets(
    'mid-session hazard Yes: Symptom is burning/smoke; leftover leader is labeled',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 23));
      await openDryerSession(tester, deps, 'Handoff Follow-up House');

      await selectObservation(tester, 'hazard-observation');
      expect(find.textContaining('repeated stopping'), findsNothing);
      await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('outcome-save-button')));
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
      final preview = tester.widget<SelectableText>(
        find.byKey(const Key('pro-handoff-preview')),
      );
      final body = preview.data ?? '';
      expect(body, contains('Symptom: $hazardSymptomLabel'));
      expect(body, isNot(contains('Symptom: —')));
      expect(body.toLowerCase(), contains('needs a professional'));
      expect(body.toLowerCase(), contains('fire or smoke'));
      expect(body, contains('not why we stopped'));

      final spoken = tester.widget<SelectableText>(
        find.byKey(const Key('pro-handoff-spoken')),
      );
      final spokenBody = spoken.data ?? '';
      expect(spokenBody, contains('Symptom: $hazardSymptomLabel'));
      expect(
        spokenBody.toLowerCase(),
        isNot(contains('symptom: not recorded')),
      );

      final outcome = deps.recentSessionOutcomes().single.outcome;
      expect(outcome.startSymptom, hazardSymptomLabel);
      expect(outcome.immediateCause.toLowerCase(), contains('fire or smoke'));
      final leftover = outcome.rankingLeaderLabel?.toLowerCase() ?? '';
      if (leftover.isNotEmpty) {
        expect(outcome.summary.toLowerCase(), isNot(contains(leftover)));
        expect(body, contains(leftoverLeaderPrefix));
        expect(body, contains(outcome.rankingLeaderLabel!));
      }
    },
  );
}

Evidence _hazardYes() {
  return _evidence(
    templateId: 'hazard-observation',
    observation: 'Do you observe a burning smell or smoke?',
    answer: 'Yes',
  );
}

Evidence _evidence({
  String? templateId,
  required String observation,
  required String answer,
}) {
  return Evidence(
    id: 'e-${templateId ?? 'free'}-$answer',
    sessionId: 's-followup',
    applianceId: 'a-1',
    type: EvidenceType.structuredAnswer,
    observation: observation,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 29, 23),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

SessionOutcome _supplyLeaderOutcome({String? startSymptom}) {
  return SessionOutcome(
    sessionId: 's-followup',
    resolutionStatus: SessionResolutionStatus.partiallyResolved,
    closeKind: SessionCloseKind.calledProfessional,
    immediateCause: 'Loose or faulty electric supply connection',
    contributingFactors: const [],
    preventiveActions: const [],
    verified: false,
    schemaVersion: '1.0',
    rankingLeaderFailureModeId: 'electric-supply-connection-fault',
    rankingLeaderLabel: 'Loose or faulty electric supply connection',
    startSymptom: startSymptom,
  );
}
