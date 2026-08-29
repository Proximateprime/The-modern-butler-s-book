import '../models/appliance.dart';
import '../models/session_outcome.dart';
import 'repair_history_display.dart';
import 'repair_log_share.dart';

const String inventoryExportShareSubject = 'Household inventory';

/// One appliance block in the on-device inventory report.
class InventoryExportRow {
  const InventoryExportRow({
    required this.appliance,
    this.lastRepairLine,
    this.lastRepairRootCause,
    this.lastRepairContributing = const [],
  });

  final Appliance appliance;
  final String? lastRepairLine;
  final String? lastRepairRootCause;
  final List<String> lastRepairContributing;
}

/// Readable household inventory. Built locally. No cloud.
String formatHouseholdInventoryExport({
  required String householdName,
  required DateTime generatedAt,
  required List<InventoryExportRow> rows,
  bool premiumFormatting = false,
  List<String> memberNames = const [],
}) {
  final lines = <String>[
    'The Modern Butler’s Book — Household inventory',
    'Household: ${_orDash(householdName)}',
    'Generated: ${_formatDate(generatedAt)}',
    'On this device. Not uploaded.',
    '',
  ];
  if (premiumFormatting) {
    final people = memberNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (people.isNotEmpty) {
      lines.insert(3, 'People: ${people.join(', ')}');
    }
  }
  if (rows.isEmpty) {
    lines.add('No appliances recorded.');
    return lines.join('\n');
  }
  for (var i = 0; i < rows.length; i++) {
    if (i > 0) {
      lines.add('');
    }
    lines.addAll(_applianceLines(rows[i], premiumFormatting: premiumFormatting));
  }
  return lines.join('\n');
}

List<String> _applianceLines(
  InventoryExportRow row, {
  required bool premiumFormatting,
}) {
  final appliance = row.appliance;
  final lastRepair = row.lastRepairLine?.trim();
  return [
    appliance.name.trim().isEmpty ? 'Unnamed appliance' : appliance.name.trim(),
    'Category: ${_categoryLabel(appliance.category)}',
    'Manufacturer: ${_orDash(appliance.manufacturer)}',
    'Model: ${_orDash(appliance.modelNumber)}',
    'Serial: ${_orDash(appliance.serialNumber)}',
    'Location: ${_orDash(appliance.location)}',
    'Notes: —',
    if (!applianceIsListed(appliance.status))
      'Status: ${_statusLabel(appliance.status)}',
    if (lastRepair != null && lastRepair.isNotEmpty)
      'Last repair: $lastRepair',
    if (premiumFormatting) ..._premiumLastRepairLines(row),
  ];
}

List<String> _premiumLastRepairLines(InventoryExportRow row) {
  final lines = <String>[];
  final root = row.lastRepairRootCause?.trim();
  if (root != null && root.isNotEmpty) {
    lines.add('Root cause: $root');
  }
  final also = row.lastRepairContributing
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  for (final item in also) {
    lines.add('Also: $item');
  }
  return lines;
}

String inventoryLastRepairLine({
  required DateTime completedAt,
  required SessionOutcome outcome,
  WasherLoadStyle? washerLoadStyle,
}) {
  final headline = repairHistoryHeadline(
    outcome,
    washerLoadStyle: washerLoadStyle,
  );
  final kind = sessionCloseKindLabel(outcome.closeKind);
  return '${_formatDate(completedAt)} · $headline · $kind';
}

Future<void> shareHouseholdInventoryExport(String text) {
  return shareRepairLogText(text, subject: inventoryExportShareSubject);
}

String _categoryLabel(String category) {
  final trimmed = category.trim();
  if (trimmed.isEmpty) {
    return '—';
  }
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}

String _statusLabel(ApplianceStatus status) {
  return switch (status) {
    ApplianceStatus.active => 'Active',
    ApplianceStatus.retired => 'Retired',
    ApplianceStatus.archived => 'Archived',
  };
}

String _orDash(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '—';
  }
  return trimmed;
}

String _formatDate(DateTime time) {
  final local = time.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
