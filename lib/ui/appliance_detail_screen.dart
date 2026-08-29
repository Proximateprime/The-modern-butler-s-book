import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../helpers/dryer_energy_source.dart';
import '../helpers/add_appliance_scan_copy.dart';
import '../helpers/degraded_mode.dart';
import '../helpers/package_maintenance_schedule.dart';
import '../helpers/repair_history_display.dart';
import '../helpers/user_facing_error.dart';
import '../helpers/warranty_hint.dart';
import '../models/appliance.dart';
import '../models/session_outcome.dart';
import 'add_appliance_screen.dart';
import 'app_dependencies.dart';
import 'error_banner.dart';
import 'evidence_photo_thumb.dart';
import 'maintenance_list.dart';
import 'package_install_screen.dart';
import 'pattern_hint_card.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';
import 'repair_log_export_button.dart';
import 'safety_disclaimer_screen.dart';
import 'session_screen.dart';
import 'stale_session_prompt.dart';
import 'warranty_hint_card.dart';

/// Identity, start/continue repair, and household-memory history for one dryer.
class ApplianceDetailScreen extends StatefulWidget {
  const ApplianceDetailScreen({
    required this.dependencies,
    required this.appliance,
    super.key,
  });

  final AppDependencies dependencies;
  final Appliance appliance;

  @override
  State<ApplianceDetailScreen> createState() => _ApplianceDetailScreenState();
}

class _ApplianceDetailScreenState extends State<ApplianceDetailScreen> {
  Future<void> _ensureGuideInstalled() async {
    final installed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => PackageInstallScreen(
              dependencies: widget.dependencies,
              category: widget.appliance.category,
            ),
      ),
    );
    if (installed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _startOrResumeRepair() async {
    if (!widget.dependencies.hasInstalledPackageFor(widget.appliance.category)) {
      await _ensureGuideInstalled();
      if (!mounted ||
          !widget.dependencies.hasInstalledPackageFor(
            widget.appliance.category,
          )) {
        return;
      }
    }
    final allowed = await ensureSafetyDisclaimerAcknowledged(
      context: context,
      dependencies: widget.dependencies,
    );
    if (!allowed || !mounted) {
      return;
    }
    try {
      final sessionId = await startOrResumeAfterStalePrompt(
        context: context,
        dependencies: widget.dependencies,
        appliance: widget.appliance,
      );
      if (sessionId == null || !mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder:
              (context) => SessionScreen(
                dependencies: widget.dependencies,
                appliance: widget.appliance,
                sessionId: sessionId,
              ),
        ),
      );
      if (mounted) {
        setState(() {});
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _openHistoryItem(RecentSessionOutcome item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => SessionScreen(
              dependencies: widget.dependencies,
              appliance: widget.appliance,
              sessionId: item.session.id,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editIdentity() async {
    final appliance =
        widget.dependencies.applianceRepository.getById(widget.appliance.id) ??
        widget.appliance;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => AddApplianceScreen(
              dependencies: widget.dependencies,
              category: appliance.category,
              existing: appliance,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addReminder() async {
    final saved = await promptAndSaveMaintenanceReminder(
      context: context,
      dependencies: widget.dependencies,
      applianceId: widget.appliance.id,
    );
    if (saved && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appliance =
        widget.dependencies.applianceRepository.getById(widget.appliance.id) ??
        widget.appliance;
    final inProgress = widget.dependencies.hasInProgressSession(appliance);
    final history = widget.dependencies.repairHistoryForAppliance(appliance.id);
    final reminders = widget.dependencies.maintenanceRemindersForAppliance(
      appliance.id,
    );
    final patternHint = widget.dependencies.patternHintForAppliance(
      appliance.id,
    );
    final packages = widget.dependencies.knowledgePackageRepository
        .loadByCategory(appliance.category);
    final manufacturerSchedule = manufacturerMaintenanceSchedule(
      packages.isEmpty ? null : packages.first,
    );
    final communityNotices = communityMaintenanceNotices(
      packages.isEmpty ? null : packages.first,
    );
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final model = appliance.modelNumber.trim();
    final brand = appliance.manufacturer.trim();
    final serial = appliance.serialNumber?.trim() ?? '';
    final ratingPhoto = appliance.ratingLabelPhotoPath?.trim() ?? '';
    final ageYears = appliance.estimatedAgeYears;

    return Scaffold(
      key: Key('appliance-detail-${appliance.id}'),
      appBar: AppBar(
        title: const Text('Appliance'),
        actions: [
          IconButton(
            key: const Key('appliance-edit-identity'),
            tooltip: 'Edit appliance',
            onPressed: _editIdentity,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ButlerPageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  appliance.name,
                  key: const Key('appliance-detail-name'),
                  style: text.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${appliance.category}',
                  key: const Key('appliance-detail-category'),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Brand: $brand',
                    key: const Key('appliance-detail-brand'),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (model.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Model: $model',
                    key: const Key('appliance-detail-model'),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (serial.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Serial: $serial',
                    key: const Key('appliance-detail-serial'),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (appliance.category == 'dryer') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Energy: ${applianceEnergySourceLabel(appliance.energySource)}',
                    key: const Key('appliance-detail-energy'),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (ageYears != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Approx. age: $ageYears years',
                    key: const Key('appliance-detail-age'),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (ratingPhoto.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      EvidencePhotoThumb(
                        key: const Key('appliance-detail-rating-photo'),
                        path: ratingPhoto,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          UserFacingCopy.addApplianceRatingPhotoStaysLocal,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (shouldShowWarrantyHint(appliance)) ...[
                  const SizedBox(height: 16),
                  WarrantyHintCard(appliance: appliance),
                ],
                const SizedBox(height: 8),
                Text(
                  inProgress
                      ? 'Continue in-progress session • ${appliance.location}'
                      : appliance.location,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 20),
                if (addApplianceShowsScanAction(
                  isWeb: kIsWeb,
                  ocrAvailable:
                      widget.dependencies.ratingPlateOcr.isAvailable,
                  barcodeAvailable:
                      widget.dependencies.barcodeScanner.isAvailable,
                  cameraOff: widget.dependencies.simulateMediaDenied,
                ))
                  OutlinedButton.icon(
                    key: const Key('appliance-detail-scan-rating-plate'),
                    onPressed: _editIdentity,
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: const Text('Scan rating plate'),
                  ),
                const SizedBox(height: 12),
                if (!widget.dependencies.hasInstalledPackageFor(
                  appliance.category,
                )) ...[
                  const DegradedModeBanner(
                    kind: DegradedModeKind.packageMissing,
                    messageKey: Key('appliance-missing-package'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('appliance-install-package'),
                    onPressed: _ensureGuideInstalled,
                    child: const Text(
                      UserFacingCopy.packageInstallButton,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                KeyedSubtree(
                  key: const Key('appliance-detail-start-repair'),
                  child: PrimaryCta(
                    key: inProgress
                        ? Key('continue-repair-${appliance.id}')
                        : Key('appliance-start-${appliance.id}'),
                    label: inProgress ? 'Continue repair' : 'Start repair',
                    semanticLabel: inProgress
                        ? PrimaryCtaSemantics.continueAction
                        : PrimaryCtaSemantics.start,
                    onPressed: _startOrResumeRepair,
                  ),
                ),
                if (patternHint != null) ...[
                  const SizedBox(height: 16),
                  PatternHintCard(
                    hint: patternHint,
                    onDismiss: () {
                      setState(() {
                        widget.dependencies.dismissPatternHint(
                          applianceId: appliance.id,
                          familyId: patternHint.familyId,
                        );
                      });
                    },
                  ),
                ],
                if (manufacturerSchedule.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PaperCard(
                    child: Column(
                      key: const Key('manufacturer-maintenance-section'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manufacturer schedule',
                          style: text.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        for (final line in manufacturerSchedule) Text('• $line'),
                      ],
                    ),
                  ),
                ],
                if (communityNotices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PaperCard(
                    child: Column(
                      key: const Key('community-maintenance-section'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What others noticed',
                          style: text.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        for (final line in communityNotices) Text('• $line'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const BookSectionLabel('Maintenance'),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('appliance-add-reminder'),
                  onPressed: _addReminder,
                  child: const Text('Add reminder'),
                ),
                const SizedBox(height: 12),
                ApplianceMaintenanceList(
                  items: reminders,
                  now: widget.dependencies.now,
                  onSetDone: (item, done) {
                    setState(() {
                      widget.dependencies.setMaintenanceReminderDone(
                        item.id,
                        done: done,
                      );
                    });
                  },
                  onSnooze: (item) {
                    setState(() {
                      widget.dependencies.snoozeMaintenanceReminder(item.id);
                    });
                  },
                ),
                const SizedBox(height: 32),
                const BookSectionLabel('Repair history'),
                const SizedBox(height: 12),
                // Empty copy only when this appliance has no completed outcomes.
                if (history.isEmpty)
                  PaperCard(
                    child: EmptyHint(
                      key: Key('appliance-history-empty-${appliance.id}'),
                      message: UserFacingCopy.noRepairsYet,
                    ),
                  )
                else
                  PaperCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      key: Key('appliance-history-${appliance.id}'),
                      children: [
                        for (var i = 0; i < history.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _repairHistoryTile(history[i], appliance),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _repairHistoryTile(RecentSessionOutcome item, Appliance appliance) {
    final outcome = item.outcome;
    final cause = repairHistoryCauseLine(
      outcome,
      washerLoadStyle: appliance.washerLoadStyle,
    );
    final extras = repairHistoryExtraLines(outcome);
    final by = repairHistoryMemberLine(
      widget.dependencies.displayNameForUserId(item.session.createdByUserId),
    );
    final when =
        '${formatRepairHistoryDate(item.completedAt)} · '
        '${sessionCloseKindLabel(outcome.closeKind)}'
        '${by == null ? '' : ' · $by'}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: Key('repair-history-${outcome.sessionId}'),
          isThreeLine: false,
          title: Text(
            repairHistoryHeadline(
              outcome,
              washerLoadStyle: appliance.washerLoadStyle,
            ),
            key: Key('repair-history-headline-${outcome.sessionId}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            when,
            key: Key('repair-history-when-${outcome.sessionId}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: RepairLogExportButton(
            sessionId: outcome.sessionId,
            applianceName: item.applianceName,
            date: item.completedAt,
            outcome: outcome,
            dependencies: widget.dependencies,
            appliance: appliance,
          ),
          onTap: () => _openHistoryItem(item),
        ),
        if (cause != null || extras.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cause != null)
                  Text(
                    cause,
                    key: Key('repair-history-cause-${outcome.sessionId}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                for (var i = 0; i < extras.length; i++)
                  Text(
                    extras[i],
                    key: Key('repair-history-extra-$i-${outcome.sessionId}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

String formatRepairHistoryDate(DateTime time) {
  final local = time.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
