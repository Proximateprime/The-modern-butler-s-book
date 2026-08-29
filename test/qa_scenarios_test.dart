import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/package_release_validator.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';

void main() {
  final root = findRepoRoot();
  final repo = KnowledgePackageRepository();
  const ranking = RankingService();

  group('docs/qa/scenarios corpus', () {
    test('dryer no-heat has at least 8 executable scenarios', () {
      final scenarios = _loadScenarios('$root/docs/qa/scenarios/dryer_no_heat.json');
      expect(scenarios, hasLength(greaterThanOrEqualTo(8)));
      for (final scenario in scenarios) {
        _assertScenario(repo: repo, ranking: ranking, scenario: scenario);
      }
    });

    test('washer won\'t drain has at least 6 executable scenarios', () {
      final scenarios = _loadScenarios(
        '$root/docs/qa/scenarios/washer_wont_drain.json',
      );
      expect(scenarios, hasLength(greaterThanOrEqualTo(6)));
      for (final scenario in scenarios) {
        _assertScenario(repo: repo, ranking: ranking, scenario: scenario);
      }
    });
  });
}

List<Map<String, dynamic>> _loadScenarios(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  expect(decoded, isA<List>());
  return [
    for (final item in decoded as List)
      Map<String, dynamic>.from(item as Map),
  ];
}

void _assertScenario({
  required KnowledgePackageRepository repo,
  required RankingService ranking,
  required Map<String, dynamic> scenario,
}) {
  final id = scenario['id'] as String;
  final packageId = scenario['packageId'] as String;
  final expectedVersion = scenario['packageVersion'] as String?;
  final package = repo.loadById(packageId);
  expect(package, isNotNull, reason: '$id missing package $packageId');
  if (expectedVersion != null) {
    expect(package!.version, expectedVersion, reason: id);
  }

  final evidence = <Evidence>[
    for (final row in scenario['evidence'] as List)
      _evidence(Map<String, dynamic>.from(row as Map)),
  ];
  final snapshot = ranking.evaluate(package: package!, evidence: evidence);
  final expectMap = Map<String, dynamic>.from(scenario['expect'] as Map);
  final wantStop = expectMap['safetyStop'] as bool? ?? false;
  final stop = evaluateSafetyStop(
    evidence: evidence,
    primaryFailureModeId: snapshot.recommendPrimaryFailureModeId ??
        snapshot.orderedFailureModes.first.id,
  );
  if (wantStop) {
    expect(stop, isNotNull, reason: '$id expected a safety stop');
  } else {
    expect(stop, isNull, reason: '$id unexpected safety stop: ${stop?.reason}');
  }

  for (final modeId in expectMap['supported'] as List? ?? const []) {
    expect(
      snapshot.standings[modeId as String]?.isSupported,
      isTrue,
      reason: '$id expected $modeId supported '
          '(net=${snapshot.standings[modeId]?.net})',
    );
  }
  for (final modeId in expectMap['notSupported'] as List? ?? const []) {
    expect(
      snapshot.standings[modeId as String]?.isSupported ?? false,
      isFalse,
      reason: '$id expected $modeId not supported '
          '(net=${snapshot.standings[modeId]?.net})',
    );
  }
  for (final pair in expectMap['netGreater'] as List? ?? const []) {
    final higher = pair[0] as String;
    final lower = pair[1] as String;
    expect(
      snapshot.standings[higher]!.net,
      greaterThan(snapshot.standings[lower]!.net),
      reason: '$id expected $higher net > $lower '
          '(${snapshot.standings[higher]!.net} vs ${snapshot.standings[lower]!.net})',
    );
  }
  for (final pair in expectMap['netGreaterOrEqual'] as List? ?? const []) {
    final higher = pair[0] as String;
    final lower = pair[1] as String;
    expect(
      snapshot.standings[higher]!.net,
      greaterThanOrEqualTo(snapshot.standings[lower]!.net),
      reason: '$id expected $higher net >= $lower',
    );
  }
  final leaderIn = expectMap['leaderIn'] as List?;
  if (leaderIn != null && leaderIn.isNotEmpty) {
    final allowed = leaderIn.cast<String>();
    final leader = snapshot.clearLeaderFailureModeId ??
        snapshot.recommendPrimaryFailureModeId ??
        snapshot.orderedFailureModes.first.id;
    expect(
      allowed,
      contains(leader),
      reason: '$id leader $leader not in $allowed '
          '(top=${snapshot.orderedFailureModes.take(3).map((m) => m.id).toList()})',
    );
  }

  for (final modeId in expectMap['scanGuidanceModeIds'] as List? ?? const []) {
    final path = closePathForFailureMode(modeId as String);
    expect(path, isNotNull, reason: '$id missing close path for $modeId');
    final lines = [
      path!.verificationAsk,
      path.verificationWhy,
      ...path.safeGuidanceSteps,
      ...path.expertOkSteps,
    ];
    for (final line in lines) {
      for (final piece in line.split(RegExp(r'[\n.]'))) {
        final trimmed = piece.trim();
        if (trimmed.isEmpty) continue;
        expect(
          lineLooksLikeUnsafeInstruction(trimmed),
          isFalse,
          reason: '$id forbidden guidance on $modeId: "$trimmed"',
        );
      }
    }
  }
}

Evidence _evidence(Map<String, dynamic> row) {
  final templateId = row['templateId'] as String;
  final answer = row['answer'] as String;
  return Evidence(
    id: 'qa-$templateId-${answer.hashCode}',
    sessionId: 'qa-session',
    applianceId: 'qa-appliance',
    type: EvidenceType.structuredAnswer,
    observation: templateId,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 22),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}
