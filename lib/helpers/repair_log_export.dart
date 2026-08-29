import '../models/session_outcome.dart';
import 'repair_log_share.dart';

/// Local-only repair log. No ranking, no cloud.
String formatRepairLogExport({
  required String applianceName,
  required DateTime? date,
  required SessionOutcome outcome,
  bool premiumFormatting = false,
}) {
  final prevention = outcome.preventiveActions
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final contributing = outcome.contributingFactors
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final root = outcome.rootCause?.trim();
  final lines = <String>[
    'The Modern Butler’s Book — Repair log',
    '',
    'Date: ${_formatDate(date)}',
    'Appliance: ${_orDash(applianceName)}',
    'Symptom: ${_orDash(outcome.startSymptom)}',
    'Outcome: ${sessionCloseKindLabel(outcome.closeKind)}',
    'Leader: ${_orDash(outcome.rankingLeaderLabel)}',
    if (premiumFormatting && root != null && root.isNotEmpty)
      'Root cause: $root',
    if (premiumFormatting)
      for (final item in contributing) 'Also: $item',
    if (prevention.isEmpty)
      'Prevention: —'
    else ...[
      'Prevention:',
      for (final item in prevention) '• $item',
    ],
    'Note: ${_orDash(outcome.userNote)}',
  ];
  return lines.join('\n');
}

Future<void> shareRepairLogExport({
  required String applianceName,
  required DateTime? date,
  required SessionOutcome outcome,
  bool premiumFormatting = false,
}) {
  return shareRepairLogText(
    formatRepairLogExport(
      applianceName: applianceName,
      date: date,
      outcome: outcome,
      premiumFormatting: premiumFormatting,
    ),
  );
}

String _orDash(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '—';
  }
  return trimmed;
}

String _formatDate(DateTime? time) {
  if (time == null) {
    return '—';
  }
  final local = time.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
