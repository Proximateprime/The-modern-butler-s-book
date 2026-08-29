import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

/// P0: no-heat fuse/vent evidence must not present heating-element guidance.
void main() {
  test('dryer_no_heat_fuse_vent_guidance_matches_leader', () {
    clearImportedClosePaths();
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final evidence = [
      _e('heat-observed', 'No warmth'),
      _e('cycle-heat-setting', 'Yes, heat cycle'),
      _e('recent-overheat', 'Yes, very hot or shut off from heat'),
      _e('exterior-airflow', 'Weak'),
      _e('clothes-feel-after-cycle', 'Cold and still damp'),
    ];

    final result = const DiagnosticReasoning().evaluate(
      package: package,
      evidence: evidence,
    );

    expect(result.closePath, isNotNull);
    expect(result.closePath!.failureModeId, 'thermal-fuse-open');
    expect(
      result.closePath!.failureModeId,
      isNot('heating-element-failed'),
    );

    final guidance = result.closePath!.safeGuidanceSteps.join(' ').toLowerCase();
    expect(guidance, contains('thermal fuse'));
    expect(guidance, isNot(contains('heating-element service')));
    expect(
      result.closePath!.verificationAsk.toLowerCase(),
      contains('still no warmth'),
    );

    final elementPath = closePathForFailureMode('heating-element-failed')!;
    expect(
      result.closePath!.safeGuidanceSteps,
      isNot(equals(elementPath.safeGuidanceSteps)),
    );
  });
}

Evidence _e(String templateId, String answer) {
  return Evidence(
    id: 'e-$templateId',
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: templateId,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 17),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}
