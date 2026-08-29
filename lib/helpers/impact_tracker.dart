import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../models/session_outcome.dart';
import 'parts_cost.dart';

/// Household-facing impact totals. Money figures are estimates only.
class HouseholdImpact {
  const HouseholdImpact({
    required this.repairsLogged,
    required this.appliancesKeptInService,
    this.estimatedSavingsUsd,
  });

  final int repairsLogged;
  final int appliancesKeptInService;

  /// Sum of (pro stub − DIY) across Fixed repairs when a number exists.
  final double? estimatedSavingsUsd;

  bool get isEmpty => repairsLogged == 0;
}

class ImpactRepairInput {
  const ImpactRepairInput({
    required this.applianceId,
    required this.closeKind,
    this.diyCostUsd,
    this.rankingLeaderFailureModeId,
  });

  final String applianceId;
  final SessionCloseKind closeKind;
  final double? diyCostUsd;
  final String? rankingLeaderFailureModeId;
}

HouseholdImpact computeHouseholdImpact(Iterable<ImpactRepairInput> repairs) {
  final fixed = repairs
      .where((item) => item.closeKind == SessionCloseKind.fixed)
      .toList(growable: false);
  if (fixed.isEmpty) {
    return const HouseholdImpact(
      repairsLogged: 0,
      appliancesKeptInService: 0,
    );
  }

  var savings = 0.0;
  var hasSavings = false;
  for (final item in fixed) {
    final saved = estimatedSavingsUsdFor(item);
    if (saved == null) {
      continue;
    }
    savings += saved;
    hasSavings = true;
  }

  return HouseholdImpact(
    repairsLogged: fixed.length,
    appliancesKeptInService: fixed.map((item) => item.applianceId).toSet().length,
    estimatedSavingsUsd: hasSavings ? savings : null,
  );
}

double? estimatedSavingsUsdFor(ImpactRepairInput repair) {
  if (repair.diyCostUsd == null) {
    return null;
  }
  final parts = partsEstimatesForSelectedPath(
    parts: FailureModeAuthoringRegistry.partsEstimatesFor(
      repair.rankingLeaderFailureModeId,
    ),
    failureModeId: repair.rankingLeaderFailureModeId,
  );
  final pro = sumEstimateMidpoints(
    parts.map((part) => part.proEstimate),
  );
  if (pro == null) {
    return null;
  }
  final diy = repair.diyCostUsd ??
      sumEstimateMidpoints(parts.map((part) => part.diyEstimate));
  if (diy == null) {
    return null;
  }
  final saved = pro - diy;
  return saved > 0 ? saved : 0;
}

double? sumEstimateMidpoints(Iterable<String> rawValues) {
  var sum = 0.0;
  var any = false;
  for (final raw in rawValues) {
    final mid = midpointUsd(raw);
    if (mid == null) {
      continue;
    }
    sum += mid;
    any = true;
  }
  return any ? sum : null;
}

/// Midpoint of the first and last dollar amounts in a stub like `$80–150`.
double? midpointUsd(String raw) {
  final matches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(raw);
  if (matches.isEmpty) {
    return null;
  }
  final values = [
    for (final match in matches) double.parse(match.group(1)!),
  ];
  if (values.length == 1) {
    return values.first;
  }
  return (values.first + values.last) / 2;
}

double? parseDiyCostUsd(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(trimmed.replaceAll(',', ''));
  if (match == null) {
    return null;
  }
  final value = double.tryParse(match.group(1)!);
  if (value == null || value < 0) {
    return null;
  }
  return value;
}

String formatImpactUsd(double amount) {
  return '\$${amount.round()}';
}
