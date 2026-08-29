import 'package:flutter/material.dart';

import '../helpers/degraded_mode.dart';
import '../helpers/inventory_export.dart';
import '../helpers/repair_history_display.dart';
import '../helpers/repair_history_search.dart';
import '../helpers/user_facing_error.dart';
import '../models/appliance.dart';
import '../models/session_outcome.dart';
import 'add_appliance_screen.dart';
import 'app_dependencies.dart';
import 'appliance_detail_screen.dart';
import 'brand_mark.dart';
import 'error_banner.dart';
import 'household_impact_card.dart';
import 'maintenance_list.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';
import 'profiles_picker.dart';
import 'repair_log_export_button.dart';
import 'safety_disclaimer_screen.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'stale_session_prompt.dart';
import 'tools_inventory_screen.dart';

/// Household home — appliances and recent repairs, product shell.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.dependencies,
    this.themeMode,
    this.onToggleTheme,
    this.onAppearanceChanged,
    super.key,
  });

  final AppDependencies dependencies;
  final ThemeMode? themeMode;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onAppearanceChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _historyQuery = TextEditingController();
  SessionCloseKind? _historyOutcome;
  String? _historyApplianceId;

  @override
  void dispose() {
    _historyQuery.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    final name = await promptHouseholdName(context: context);
    if (name != null && mounted) {
      setState(() {
        widget.dependencies.createHousehold(name);
      });
    }
  }

  void _loadSampleHome() {
    setState(() {
      widget.dependencies.loadSampleHome();
    });
  }

  Future<void> _openProfiles() async {
    await showProfilesPicker(
      context: context,
      dependencies: widget.dependencies,
      onChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addDryer() => _openAddAppliance('dryer');

  Future<void> _addWasher() => _openAddAppliance('washer');

  Future<void> _addFridge() => _openAddAppliance('fridge');

  Future<void> _addDishwasher() => _openAddAppliance('dishwasher');

  Future<void> _openAddAppliance(String category) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => AddApplianceScreen(
              dependencies: widget.dependencies,
              category: category,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              dependencies: widget.dependencies,
              onAppearanceChanged: widget.onAppearanceChanged,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openTools() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => ToolsInventoryScreen(
              dependencies: widget.dependencies,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _exportInventory() async {
    try {
      final text = widget.dependencies.currentHouseholdInventoryExportText();
      await shareHouseholdInventoryExport(text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('export-inventory-snackbar'),
          content: Text(UserFacingCopy.exportInventoryReady),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  Future<void> _archiveAppliance(Appliance appliance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              'Retire ${appliance.category}?',
            ),
            content: Text(
              'Retire "${appliance.name}"? Past sessions stay in Recent '
              'Activity, but this ${appliance.category} will no longer appear '
              'in your list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: Key('confirm-archive-${appliance.id}'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Retire'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      widget.dependencies.archiveAppliance(appliance);
      setState(() {});
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _openAppliance(Appliance appliance) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => ApplianceDetailScreen(
              dependencies: widget.dependencies,
              appliance: appliance,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openRecentOutcome(RecentSessionOutcome item) async {
    final appliance = item.appliance;
    if (appliance != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder:
              (context) => SessionScreen(
                dependencies: widget.dependencies,
                appliance: appliance,
                sessionId: item.session.id,
              ),
        ),
      );
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(item.applianceName),
            content: Text(
              'Status: ${sessionCloseKindLabel(item.outcome.closeKind)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _continueRepair(Appliance appliance) async {
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
        appliance: appliance,
      );
      if (sessionId == null || !mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder:
              (context) => SessionScreen(
                dependencies: widget.dependencies,
                appliance: appliance,
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

  @override
  Widget build(BuildContext context) {
    final household = widget.dependencies.currentHousehold;
    final currentMember = widget.dependencies.currentMember;
    final appliances = widget.dependencies.appliancesForCurrentHousehold();
    final recentOutcomes = widget.dependencies.recentSessionOutcomes(
      limit: 100,
    );
    final filteredHistory = filterRepairHistory(
      items: recentOutcomes,
      query: _historyQuery.text,
      closeKind: _historyOutcome,
      applianceId: _historyApplianceId,
    );
    final historyAppliances = <String, String>{};
    for (final item in recentOutcomes) {
      historyAppliances[item.session.applianceId] = item.applianceName;
    }
    final upcoming = widget.dependencies.upcomingMaintenanceReminders(limit: 3);
    final dueReminders = widget.dependencies.dueMaintenanceReminders();
    final impact = widget.dependencies.householdImpact();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandMark(size: 28),
            SizedBox(width: 10),
            Flexible(child: Wordmark()),
          ],
        ),
        actions: [
          if (!widget.dependencies.isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  'Offline',
                  key: Key('home-offline-indicator'),
                ),
              ),
            ),
          if (household != null)
            IconButton(
              key: const Key('profiles-button'),
              tooltip: 'Profiles',
              onPressed: _openProfiles,
              icon: const Icon(Icons.people_outline),
            ),
          if (household != null)
            IconButton(
              key: const Key('tools-inventory-button'),
              tooltip: 'Tools',
              onPressed: _openTools,
              icon: const Icon(Icons.handyman_outlined),
            ),
          IconButton(
            key: const Key('home-settings-button'),
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          if (widget.onToggleTheme != null)
            IconButton(
              key: const Key('theme-toggle-button'),
              tooltip:
                  widget.themeMode == ThemeMode.dark
                      ? 'Use paper theme'
                      : 'Use dark theme',
              onPressed: widget.onToggleTheme,
              icon: Icon(
                widget.themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ButlerPageBody(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          Text(
            household?.name ?? 'Your household',
            key: const Key('household-name'),
            style: text.headlineSmall,
          ),
          if (currentMember != null) ...[
            const SizedBox(height: 4),
            Text(
              'Using as ${currentMember.displayName}',
              key: const Key('current-member-label'),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            household == null
                ? UserFacingCopy.emptyHomeNoHousehold
                : appliances.isEmpty
                ? UserFacingCopy.emptyHomeNoDryer
                : UserFacingCopy.emptyHomeHasAppliances,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (dueReminders.isNotEmpty) ...[
            const SizedBox(height: 16),
            PaperCard(
              child: Column(
                key: const Key('home-maintenance-due-banner'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dueReminders.length == 1
                        ? 'Maintenance is due'
                        : '${dueReminders.length} maintenance items are due',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A local reminder is stored on this device. '
                    '${widget.dependencies.maintenanceNotifier.notificationsAllowed ? 'A notification was scheduled when it came due.' : 'If notifications are off, this banner is the reminder.'}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (widget.dependencies.snapshotCorrupt) ...[
            DegradedModeBanner(
              kind: DegradedModeKind.corruptSnapshot,
              onStartFresh: () async {
                await widget.dependencies.discardCorruptSnapshot();
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (!widget.dependencies.isOnline) ...[
            const DegradedModeBanner(
              kind: DegradedModeKind.offline,
            ),
            const SizedBox(height: 16),
          ],
          if (household == null) ...[
            PrimaryCta(
              key: const Key('create-household-button'),
              label: UserFacingCopy.createHouseholdAction,
              semanticLabel: UserFacingCopy.createHouseholdAction,
              onPressed: _createHousehold,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('load-sample-home-button'),
              onPressed: _loadSampleHome,
              child: const Text('Load sample home'),
            ),
          ] else if (appliances.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('add-dryer-button'),
                  onPressed: _addDryer,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Dryer'),
                ),
                OutlinedButton.icon(
                  key: const Key('add-washer-button'),
                  onPressed: _addWasher,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Washer'),
                ),
                OutlinedButton.icon(
                  key: const Key('add-fridge-button'),
                  onPressed: _addFridge,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Fridge'),
                ),
                OutlinedButton.icon(
                  key: const Key('add-dishwasher-button'),
                  onPressed: _addDishwasher,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Dishwasher'),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 32),
          const BookSectionLabel('Appliances'),
          if (household != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('export-inventory-button'),
                onPressed: _exportInventory,
                icon: const Icon(Icons.ios_share_outlined, size: 18),
                label: const Text(UserFacingCopy.exportInventoryTitle),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              UserFacingCopy.exportInventoryPrivacy,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          if (appliances.isEmpty)
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmptyHint(
                    key: const Key('empty-home-appliances'),
                    message: UserFacingCopy.noDryersYet,
                  ),
                  if (household != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('add-dryer-button'),
                      onPressed: _addDryer,
                      child: const Text('Add Dryer'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('add-washer-button'),
                      onPressed: _addWasher,
                      child: const Text('Add Washer'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('add-fridge-button'),
                      onPressed: _addFridge,
                      child: const Text('Add Fridge'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('add-dishwasher-button'),
                      onPressed: _addDishwasher,
                      child: const Text('Add Dishwasher'),
                    ),
                  ],
                ],
              ),
            )
          else
            for (var i = 0; i < appliances.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ApplianceCard(
                appliance: appliances[i],
                inProgress: widget.dependencies.hasInProgressSession(
                  appliances[i],
                ),
                onOpen: () => _openAppliance(appliances[i]),
                onContinue: () => _continueRepair(appliances[i]),
                onArchive: () => _archiveAppliance(appliances[i]),
              ),
            ],
          if (impact.repairsLogged > 0) ...[
            const SizedBox(height: 32),
            HouseholdImpactCard(impact: impact),
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 32),
            const BookSectionLabel(
              'Upcoming maintenance',
              key: Key('upcoming-maintenance-title'),
            ),
            const SizedBox(height: 12),
            UpcomingMaintenanceSection(
              items: upcoming,
              now: widget.dependencies.now,
              applianceName: (id) {
                return widget.dependencies.applianceRepository.getById(id)?.name ??
                    'Appliance';
              },
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
          ],
          const SizedBox(height: 32),
          const BookSectionLabel(
            'Repair history',
            key: Key('recent-activity-title'),
          ),
          const SizedBox(height: 12),
          if (recentOutcomes.isEmpty)
            PaperCard(
              child: EmptyHint(
                key: const Key('recent-activity-empty'),
                message: UserFacingCopy.noRepairsYet,
              ),
            )
          else ...[
            ExpansionTile(
              key: const Key('memory-search-tile'),
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Search and filter',
                style: text.titleSmall,
              ),
              children: [
                TextField(
                  key: const Key('memory-search-field'),
                  controller: _historyQuery,
                  decoration: const InputDecoration(
                    labelText: 'Search repairs',
                    hintText: 'Appliance, outcome, or note',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Wrap(
                  key: const Key('memory-filter-outcomes'),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      key: const Key('memory-filter-outcome-all'),
                      label: const Text('All outcomes'),
                      selected: _historyOutcome == null,
                      onSelected: (_) => setState(() => _historyOutcome = null),
                    ),
                    for (final kind in SessionCloseKind.values)
                      FilterChip(
                        key: Key('memory-filter-outcome-${kind.name}'),
                        label: Text(sessionCloseKindLabel(kind)),
                        selected: _historyOutcome == kind,
                        onSelected:
                            (_) => setState(() => _historyOutcome = kind),
                      ),
                  ],
                ),
                if (historyAppliances.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    key: const Key('memory-filter-appliances'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        key: const Key('memory-filter-appliance-all'),
                        label: const Text('All appliances'),
                        selected: _historyApplianceId == null,
                        onSelected:
                            (_) => setState(() => _historyApplianceId = null),
                      ),
                      for (final entry in historyAppliances.entries)
                        FilterChip(
                          key: Key('memory-filter-appliance-${entry.key}'),
                          label: Text(entry.value),
                          selected: _historyApplianceId == entry.key,
                          onSelected:
                              (_) => setState(
                                () => _historyApplianceId = entry.key,
                              ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredHistory.isEmpty)
              PaperCard(
                child: EmptyHint(
                  key: const Key('recent-activity-no-matches'),
                  message: UserFacingCopy.noMatchingRepairs,
                ),
              )
            else
              PaperCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  key: const Key('recent-activity-list'),
                  children: [
                    for (var i = 0; i < filteredHistory.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        key: Key(
                          'recent-outcome-${filteredHistory[i].outcome.sessionId}',
                        ),
                        isThreeLine: true,
                        title: Text(
                          filteredHistory[i].applianceName,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sessionCloseKindLabel(
                                filteredHistory[i].outcome.closeKind,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _recentHistoryMeta(filteredHistory[i]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: RepairLogExportButton(
                          sessionId: filteredHistory[i].outcome.sessionId,
                          applianceName: filteredHistory[i].applianceName,
                          date: filteredHistory[i].completedAt,
                          outcome: filteredHistory[i].outcome,
                          dependencies: widget.dependencies,
                          appliance: filteredHistory[i].appliance,
                        ),
                        onTap: () => _openRecentOutcome(filteredHistory[i]),
                      ),
                    ],
                  ],
                ),
              ),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _recentHistoryMeta(RecentSessionOutcome item) {
    final by = repairHistoryMemberLine(
      widget.dependencies.displayNameForUserId(item.session.createdByUserId),
    );
    final kind = sessionCloseKindLabel(item.outcome.closeKind);
    final summary = item.outcome.summary.trim();
    var detail = summary;
    final prefix = '$kind — ';
    if (summary.startsWith(prefix)) {
      detail = summary.substring(prefix.length).trim();
    } else if (summary == kind) {
      detail = '';
    }
    final parts = <String>[
      formatRepairHistoryDate(item.completedAt),
      if (detail.isNotEmpty) detail,
      if (by != null) by,
    ];
    return parts.join(' · ');
  }
}

class _ApplianceCard extends StatelessWidget {
  const _ApplianceCard({
    required this.appliance,
    required this.inProgress,
    required this.onOpen,
    required this.onContinue,
    required this.onArchive,
  });

  final Appliance appliance;
  final bool inProgress;
  final VoidCallback onOpen;
  final VoidCallback onContinue;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: Key('appliance-${appliance.id}'),
            onTap: onOpen,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(appliance.name, style: text.titleLarge),
                    ),
                    IconButton(
                      key: Key('archive-appliance-${appliance.id}'),
                      tooltip: 'Retire ${appliance.category}',
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: onArchive,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  inProgress
                      ? 'Continue in-progress session • ${appliance.location}'
                      : 'Open ${appliance.category} • ${appliance.location}',
                  style: text.bodySmall,
                ),
                if (appliance.modelNumber.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Model ${appliance.modelNumber.trim()}',
                    key: Key('appliance-home-model-${appliance.id}'),
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (inProgress) ...[
            const SizedBox(height: 12),
            PrimaryCta(
              key: Key('continue-repair-${appliance.id}'),
              label: 'Continue repair',
              semanticLabel: PrimaryCtaSemantics.continueAction,
              onPressed: onContinue,
            ),
          ],
        ],
      ),
    );
  }
}
