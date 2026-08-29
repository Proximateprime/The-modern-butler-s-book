import 'package:flutter/material.dart';

import '../app_info.dart';
import '../helpers/degraded_mode.dart';
import '../helpers/household_entitlement.dart';
import '../helpers/knowledge_package_catalog.dart';
import '../helpers/local_backup.dart';
import '../helpers/local_backup_io.dart';
import '../helpers/user_facing_error.dart';
import '../models/repair_comfort_profile.dart';
import 'about_screen.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';
import 'error_banner.dart';
import 'package_manager_screen.dart';
import 'permissions_help.dart';
import 'product_chrome.dart';
import 'profiles_picker.dart';
import 'safety_disclaimer_screen.dart';
import 'tools_inventory_screen.dart';

/// Appearance, session reset, privacy, version, and tools — no diagnostic behavior.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.dependencies,
    this.onAppearanceChanged,
    super.key,
  });

  final AppDependencies dependencies;
  final VoidCallback? onAppearanceChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _expertAdultConfirmed;

  @override
  void initState() {
    super.initState();
    _expertAdultConfirmed = widget.dependencies.expertMode;
  }

  Future<void> _selectTheme(AppThemeChoice choice) async {
    await widget.dependencies.applyThemeChoice(choice);
    widget.onAppearanceChanged?.call();
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

  Future<void> _openPackageManager() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => PackageManagerScreen(
              dependencies: widget.dependencies,
            ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmClearOpenSession() async {
    if (widget.dependencies.openSessionCount == 0) {
      setState(() {
        widget.dependencies.clearOpenSessions();
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('settings-clear-session-empty-snackbar'),
          content: Text('No repair is in progress'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Clear open session?'),
            content: const Text(
              'This abandons the in-progress repair without writing a '
              'repair memory. You can start again from the appliance.',
            ),
            actions: [
              TextButton(
                key: const Key('settings-clear-session-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('settings-clear-session-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Clear session'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      widget.dependencies.clearOpenSessions();
    });
  }

  Future<void> _exportBackup() async {
    try {
      final json = widget.dependencies.exportHouseholdBackupJson();
      await exportHouseholdBackupFile(json);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('settings-backup-exported-snackbar'),
          content: Text(UserFacingCopy.backupExported),
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

  Future<void> _importBackup() async {
    String? raw;
    try {
      raw = await pickHouseholdBackupFile();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
      return;
    }
    if (!mounted || raw == null) {
      return;
    }
    try {
      decodeHouseholdBackup(raw);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('settings-backup-invalid-snackbar'),
          content: Text(userFacingErrorMessage(error)),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text(UserFacingCopy.backupImportTitle),
            content: const Text(UserFacingCopy.backupImportConfirm),
            actions: [
              TextButton(
                key: const Key('settings-backup-import-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('settings-backup-import-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Replace'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      widget.dependencies.restoreHouseholdBackupFromJson(raw);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
      return;
    }
    setState(() {});
    widget.onAppearanceChanged?.call();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: Key('settings-backup-imported-snackbar'),
        content: Text(UserFacingCopy.backupImported),
      ),
    );
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder:
            (context) => AboutScreen(dependencies: widget.dependencies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final choice = widget.dependencies.themeChoice;
    final openCount = widget.dependencies.openSessionCount;
    final online = widget.dependencies.isOnline;

    return Scaffold(
      key: const Key('settings-screen'),
      appBar: AppBar(title: const Text('Settings')),
      body: ButlerPageBody(
        child: ListView(
          children: [
            const BookSectionLabel('Appearance'),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final option in AppThemeChoice.values)
                  RadioListTile<AppThemeChoice>(
                    key: Key('settings-theme-${option.name}'),
                    value: option,
                    groupValue: choice,
                    title: Text(option.label),
                    onChanged: (value) {
                      if (value != null) {
                        _selectTheme(value);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const BookSectionLabel(UserFacingCopy.expertModeTitle),
            const SizedBox(height: 8),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    UserFacingCopy.expertModeWarning,
                    key: const Key('settings-expert-warning'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const Key('settings-expert-adult-confirm'),
                    contentPadding: EdgeInsets.zero,
                    value: _expertAdultConfirmed,
                    title: const Text(UserFacingCopy.expertModeAdultConfirm),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      final checked = value ?? false;
                      setState(() {
                        _expertAdultConfirmed = checked;
                        if (!checked) {
                          widget.dependencies.setExpertMode(
                            enabled: false,
                            adultConfirmed: false,
                          );
                        }
                      });
                    },
                  ),
                  SwitchListTile(
                    key: const Key('settings-expert-mode'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(UserFacingCopy.expertModeSwitchTitle),
                    subtitle: const Text(
                      'Requires the adult confirmation checkbox.',
                    ),
                    value: widget.dependencies.expertMode,
                    onChanged: (enabled) {
                      if (enabled && !_expertAdultConfirmed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            key: Key('settings-expert-need-adult-snackbar'),
                            content: Text(UserFacingCopy.expertModeNeedAdult),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        if (!enabled) {
                          _expertAdultConfirmed = false;
                        }
                        widget.dependencies.setExpertMode(
                          enabled: enabled,
                          adultConfirmed: _expertAdultConfirmed,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const BookSectionLabel(UserFacingCopy.comfortSettingsTitle),
            const SizedBox(height: 8),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    UserFacingCopy.comfortSettingsExplainer,
                    key: const Key('settings-comfort-explainer'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  for (final spec in BundledKnowledgePackageCatalog.all) ...[
                    Text(
                      spec.displayName,
                      style: text.titleSmall,
                    ),
                    for (final level in RepairComfortLevel.values)
                      RadioListTile<RepairComfortLevel>(
                        key: Key(
                          'settings-comfort-${spec.category}-${level.name}',
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: level,
                        groupValue: widget.dependencies.repairComfort.levelFor(
                          spec.category,
                        ),
                        title: Text(level.label),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            widget.dependencies.setRepairComfortLevel(
                              spec.category,
                              value,
                            );
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                  SwitchListTile(
                    key: const Key('settings-learn-preferences'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(UserFacingCopy.comfortLearnTitle),
                    subtitle: const Text(UserFacingCopy.comfortLearnSubtitle),
                    value: widget.dependencies.repairComfort.learnPreferences,
                    onChanged: (value) {
                      setState(() {
                        widget.dependencies.setLearnPreferences(value);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('Household'),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('settings-profiles-item'),
              leading: const Icon(Icons.people_outline),
              title: const Text('Profiles'),
              subtitle: Text(
                widget.dependencies.currentHousehold?.name ??
                    'Add a household on this device',
              ),
              onTap: () async {
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
              },
            ),
            ListTile(
              key: const Key('settings-tools-item'),
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('Tools'),
              subtitle: const Text('What you own at home'),
              onTap: _openTools,
            ),
            ListTile(
              key: const Key('settings-package-manager'),
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Guides'),
              subtitle: const Text('Package manager — versions on this device'),
              onTap: _openPackageManager,
            ),
            ListTile(
              key: const Key('settings-clear-session-button'),
              leading: const Icon(Icons.stop_circle_outlined),
              title: const Text('Clear open session'),
              subtitle: Text(
                openCount == 0
                    ? 'No repair is in progress'
                    : openCount == 1
                    ? 'Abandon the in-progress repair'
                    : 'Abandon $openCount in-progress repairs',
              ),
              onTap: _confirmClearOpenSession,
            ),
            if (householdProToggleVisible) ...[
              SwitchListTile(
                key: const Key('settings-household-pro'),
                title: const Text(UserFacingCopy.householdProTitle),
                subtitle: const Text(UserFacingCopy.householdProSubtitle),
                value: widget.dependencies.householdProEnabled,
                onChanged: (value) {
                  setState(() {
                    widget.dependencies.setHouseholdProEnabled(value);
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Text(
                  UserFacingCopy.householdProNeverPaywallSafety,
                  key: const Key('settings-household-pro-safety'),
                  style: text.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const BookSectionLabel('Backup'),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('settings-backup-export'),
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text(UserFacingCopy.backupExportTitle),
              subtitle: const Text(
                'Appliances, memory, tools, and reminders — one local file',
              ),
              onTap: _exportBackup,
            ),
            ListTile(
              key: const Key('settings-backup-import'),
              leading: const Icon(Icons.file_download_outlined),
              title: const Text(UserFacingCopy.backupImportTitle),
              subtitle: const Text('Replace data on this device from a backup'),
              onTap: _importBackup,
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('Demo'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                'Practice content and test switches. The sample home is a '
                'separate household — it never mixes with your own.',
                key: const Key('settings-demo-explainer'),
                style: text.bodySmall?.copyWith(height: 1.4),
              ),
            ),
            SwitchListTile(
              key: const Key('settings-sample-open-session'),
              title: const Text('Include sample open session'),
              subtitle: const Text(
                'Shows Continue repair after loading the sample home',
              ),
              value: widget.dependencies.includeSampleOpenSession,
              onChanged: (value) {
                setState(() {
                  widget.dependencies.includeSampleOpenSession = value;
                });
              },
            ),
            SwitchListTile(
              key: const Key('settings-simulate-media-denied'),
              title: const Text('Simulate camera & microphone denied'),
              subtitle: const Text(
                'Hide scan, photo, and voice. Type the model and tap chips.',
              ),
              value: widget.dependencies.simulateMediaDenied,
              onChanged: (value) {
                setState(() {
                  widget.dependencies.simulateMediaDenied = value;
                });
              },
            ),
            SwitchListTile(
              key: const Key('settings-simulate-offline'),
              title: const Text(UserFacingCopy.simulateOfflineTitle),
              subtitle: const Text(UserFacingCopy.simulateOfflineSubtitle),
              value: widget.dependencies.simulateOffline,
              onChanged: (value) {
                setState(() {
                  widget.dependencies.simulateOffline = value;
                });
                widget.onAppearanceChanged?.call();
              },
            ),
            ListTile(
              key: const Key('settings-load-sample-home'),
              leading: const Icon(Icons.home_outlined),
              title: const Text('Load sample home'),
              subtitle: const Text(
                'Whirlpool WED5000DW dryer and WTW5000DW washer — local only',
              ),
              onTap: () {
                setState(() {
                  widget.dependencies.loadSampleHome();
                });
                widget.onAppearanceChanged?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    key: Key('settings-sample-home-snackbar'),
                    content: Text('Sample home loaded'),
                  ),
                );
              },
            ),
            ListTile(
              key: const Key('settings-reset-sample-data'),
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset sample data'),
              subtitle: const Text(
                'Restore the canned sample home. Safe if it was never loaded.',
              ),
              onTap: () {
                setState(() {
                  widget.dependencies.resetSampleData();
                });
                widget.onAppearanceChanged?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    key: Key('settings-reset-sample-snackbar'),
                    content: Text(
                      'Sample data reset',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('Privacy'),
            const SizedBox(height: 8),
            if (!online)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: DegradedModeBanner(
                  kind: DegradedModeKind.offline,
                  bannerKey: Key('settings-offline-banner'),
                ),
              ),
            PaperCard(
              child: Column(
                key: const Key('settings-privacy-card'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    UserFacingCopy.privacyLocalFirst,
                    key: const Key('settings-privacy-local-first'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UserFacingCopy.privacyWhatIsStored,
                    key: const Key('settings-privacy-stored'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UserFacingCopy.privacyNoSkillProfiling,
                    key: const Key('settings-privacy-skill'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const BookSectionLabel('Camera and microphone'),
            const SizedBox(height: 8),
            const PermissionsHelpCard(
              key: Key('settings-permissions-help'),
            ),
            ListTile(
              key: const Key('settings-safety-disclaimer'),
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Safety disclaimer'),
              subtitle: const Text('Re-read the notice you acknowledged'),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder:
                        (context) => const SafetyDisclaimerScreen(readOnly: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('About'),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('settings-version-badge'),
              leading: const Icon(Icons.info_outline),
              title: Text('App $kAppVersionLabel'),
              subtitle: const Text(
                'Feature freeze $kFeatureFreezeDate — bugfixes only',
              ),
              onTap: _openAbout,
            ),
            const SizedBox(height: 8),
            Text(
              'Appearance, guides, and session reset only. Ranking is unchanged.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
