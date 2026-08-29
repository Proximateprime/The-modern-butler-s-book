import 'package:flutter/material.dart';

import '../helpers/dryer_close_path.dart';
import '../helpers/impact_tracker.dart';
import '../helpers/maintenance_reminder_copy.dart';
import '../helpers/parts_cost.dart';
import '../helpers/root_cause_memory.dart';
import '../helpers/user_facing_error.dart';
import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../models/appliance.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import 'app_dependencies.dart';
import 'parts_cost_card.dart';
import 'primary_cta.dart';
import 'pro_handoff_screen.dart';
import 'product_chrome.dart';
import 'session_completion_screen.dart';

/// Records a household-memory outcome after Safe Guidance / verify.
class SessionOutcomeScreen extends StatefulWidget {
  const SessionOutcomeScreen({
    required this.dependencies,
    required this.appliance,
    required this.sessionId,
    required this.eligibility,
    this.rankingLeaderLabel,
    this.rankingLeaderFailureModeId,
    this.initialCloseKind,
    super.key,
  });

  final AppDependencies dependencies;
  final Appliance appliance;
  final String sessionId;
  final CloseResolveEligibility eligibility;
  final String? rankingLeaderLabel;
  final String? rankingLeaderFailureModeId;
  final SessionCloseKind? initialCloseKind;

  @override
  State<SessionOutcomeScreen> createState() => _SessionOutcomeScreenState();
}

class _SessionOutcomeScreenState extends State<SessionOutcomeScreen> {
  SessionCloseKind? _kind;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _immediateController = TextEditingController();
  final TextEditingController _rootController = TextEditingController();
  final TextEditingController _contributingController = TextEditingController();
  final TextEditingController _preventionController = TextEditingController();
  final TextEditingController _diyCostController = TextEditingController();
  bool _seededFixedFields = false;
  bool _rootNotSure = false;
  bool _updateMaintenance = false;
  late RootCauseMemorySeed _seed;
  final Set<String> _selectedFactors = {};
  final Set<String> _selectedPrevention = {};

  @override
  void initState() {
    super.initState();
    _seed = rootCauseMemorySeed(
      failureModeId: widget.rankingLeaderFailureModeId,
      rankingLeaderLabel: widget.rankingLeaderLabel,
    );
    _kind = widget.initialCloseKind;
    if (_kind == SessionCloseKind.fixed) {
      _seedFixedFields();
    }
  }

  void _seedFixedFields() {
    if (_seededFixedFields) {
      return;
    }
    _seededFixedFields = true;
    if (_immediateController.text.trim().isEmpty) {
      _immediateController.text = _seed.immediateCause;
    }
    if (_rootController.text.trim().isEmpty) {
      _rootController.text = _seed.rootCause;
    }
    _selectedFactors
      ..clear()
      ..addAll(_seed.contributingFactors);
    _selectedPrevention
      ..clear()
      ..addAll(_seed.preventiveActions);
    _rootNotSure = false;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _immediateController.dispose();
    _rootController.dispose();
    _contributingController.dispose();
    _preventionController.dispose();
    _diyCostController.dispose();
    super.dispose();
  }

  bool get _allowFixed =>
      widget.eligibility == CloseResolveEligibility.allowResolved;

  SessionObjective? get _sessionObjective =>
      widget.dependencies.repairSessionRepository
          .getSession(widget.sessionId)
          ?.sessionObjective;

  String get _saveBlurb {
    return switch (_sessionObjective) {
      SessionObjective.prepareToCallAPro =>
        'Save this repair, then share a technician handoff.',
      SessionObjective.decideRepairVsReplace =>
        'Use the estimates below, then save what you decided.',
      SessionObjective.figureOutWhatsWrong =>
        'Save what you figured out to household memory.',
      SessionObjective.fixIt => 'Save this repair to household memory.',
      null => 'Save this repair to household memory.',
    };
  }

  void _save() {
    final kind = _kind;
    if (kind == null) {
      return;
    }
    try {
      final contributing = kind == SessionCloseKind.fixed
          ? confirmedMemoryItems(
              selected: _selectedFactors.toList(),
              extraLines: _contributingController.text,
            )
          : null;
      final prevention = kind == SessionCloseKind.fixed
          ? confirmedMemoryItems(
              selected: _selectedPrevention.toList(),
              extraLines: _preventionController.text,
            )
          : null;
      final recorded = widget.dependencies.endSession(
        sessionId: widget.sessionId,
        closeKind: kind,
        userNote: _noteController.text,
        whatFixedIt: kind == SessionCloseKind.fixed
            ? _immediateController.text
            : null,
        immediateCause: kind == SessionCloseKind.fixed
            ? _immediateController.text
            : null,
        rootCause: kind == SessionCloseKind.fixed
            ? (confirmedRootCause(
                    notSure: _rootNotSure,
                    suggested: _seed.rootCause,
                    custom: _rootController.text,
                  ) ??
                  '')
            : null,
        contributingFactors: contributing,
        preventionNote: kind == SessionCloseKind.fixed
            ? joinMemoryLines(prevention ?? const [])
            : null,
        preventiveActions: prevention,
        diyCostUsd: kind == SessionCloseKind.fixed
            ? parseDiyCostUsd(_diyCostController.text)
            : null,
      );
      if (kind == SessionCloseKind.fixed && _updateMaintenance) {
        _saveMaintenanceIfRequested(prevention ?? recorded.preventiveActions);
      }
      if (!mounted) {
        return;
      }
      if (kind == SessionCloseKind.fixed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<bool>(
            builder:
                (context) => SessionCompletionScreen(
                  dependencies: widget.dependencies,
                  appliance: widget.appliance,
                  outcome: recorded,
                ),
          ),
        );
        return;
      }
      if (kind == SessionCloseKind.calledProfessional) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<bool>(
            builder:
                (context) => ProHandoffScreen(
                  dependencies: widget.dependencies,
                  appliance: widget.appliance,
                  outcome: recorded,
                ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(error))),
        );
      }
    }
  }

  void _saveMaintenanceIfRequested(List<String> prevention) {
    final note = preferredCalendarMaintenanceNote(prevention);
    if (note.isEmpty) {
      return;
    }
    final interval = inferMaintenanceIntervalDays(note);
    widget.dependencies.addMaintenanceReminder(
      applianceId: widget.appliance.id,
      note: note,
      remindOn: widget.dependencies.now.add(
        Duration(days: interval ?? typicalCalendarMaintenanceDays),
      ),
      sessionId: widget.sessionId,
      intervalDays: interval,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final outcomeParts = partsEstimatesForSelectedPath(
      parts: FailureModeAuthoringRegistry.partsEstimatesFor(
        widget.rankingLeaderFailureModeId,
      ),
      failureModeId: widget.rankingLeaderFailureModeId,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record outcome'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ButlerPageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.appliance.name,
                  style: text.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _saveBlurb,
                  style: text.bodyMedium,
                ),
                if (outcomeParts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  PartsCostCard(
                    parts: outcomeParts,
                    onIllRepair:
                        _allowFixed &&
                                showIllRepairOnPartsCard(_sessionObjective)
                            ? () => setState(() {
                              _kind = SessionCloseKind.fixed;
                              _seedFixedFields();
                            })
                            : null,
                    onCallPro:
                        showCallProOnPartsCard(_sessionObjective)
                            ? () => setState(
                              () =>
                                  _kind = SessionCloseKind.calledProfessional,
                            )
                            : null,
                  ),
                ],
                const SizedBox(height: 20),
                const BookSectionLabel('What happened'),
                const SizedBox(height: 12),
                if (_allowFixed)
                  _OutcomeChoice(
                    key: const Key('outcome-resolved'),
                    selected: _kind == SessionCloseKind.fixed,
                    label: 'Fixed — problem resolved',
                    semanticLabel: PrimaryCtaSemantics.fixed,
                    onTap: () => setState(() {
                      _kind = SessionCloseKind.fixed;
                      _seedFixedFields();
                    }),
                  ),
                _OutcomeChoice(
                  key: const Key('outcome-unresolved'),
                  selected: _kind == SessionCloseKind.notFixed,
                  label: 'Not fixed — still happening',
                  onTap: () => setState(() => _kind = SessionCloseKind.notFixed),
                ),
                _OutcomeChoice(
                  key: const Key('outcome-stopped'),
                  selected: _kind == SessionCloseKind.stopped,
                  label: 'Stopped for now',
                  onTap: () => setState(() => _kind = SessionCloseKind.stopped),
                ),
                _OutcomeChoice(
                  key: const Key('outcome-needs-professional'),
                  selected: _kind == SessionCloseKind.calledProfessional,
                  label: 'Calling a professional',
                  onTap: () =>
                      setState(() => _kind = SessionCloseKind.calledProfessional),
                ),
                if (_kind == SessionCloseKind.fixed) ...[
                  const SizedBox(height: 24),
                  const BookSectionLabel('What failed'),
                  const SizedBox(height: 8),
                  Text(
                    'Guide suggestions are from this repair path. Confirm, '
                    'edit, or skip them — the app does not invent a root cause.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('outcome-what-fixed-field'),
                    controller: _immediateController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Immediate cause — what failed',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilterChip(
                    key: const Key('outcome-root-unknown'),
                    label: const Text('Root cause not sure'),
                    selected: _rootNotSure,
                    onSelected: (selected) {
                      setState(() {
                        _rootNotSure = selected;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('outcome-root-cause-field'),
                    controller: _rootController,
                    enabled: !_rootNotSure,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Root cause — why it failed (if known)',
                      helperText:
                          'Leave the guide wording, edit it, or mark not sure.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Contributing factors',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _MemoryChipWrap(
                    prefix: 'outcome-factor-chip',
                    items: _seed.contributingFactors,
                    selected: _selectedFactors,
                    onToggle: (item, selected) {
                      setState(() {
                        if (selected) {
                          _selectedFactors.add(item);
                        } else {
                          _selectedFactors.remove(item);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('outcome-contributing-field'),
                    controller: _contributingController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add another factor (optional, one per line)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prevention',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _MemoryChipWrap(
                    prefix: 'outcome-prevention-chip',
                    items: _seed.preventiveActions,
                    selected: _selectedPrevention,
                    onToggle: (item, selected) {
                      setState(() {
                        if (selected) {
                          _selectedPrevention.add(item);
                        } else {
                          _selectedPrevention.remove(item);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('outcome-prevention-field'),
                    controller: _preventionController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add another prevention step (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    key: const Key('outcome-update-maintenance'),
                    contentPadding: EdgeInsets.zero,
                    value: _updateMaintenance,
                    onChanged: (value) {
                      setState(() {
                        _updateMaintenance = value ?? false;
                      });
                    },
                    title: const Text('Update maintenance schedule'),
                    subtitle: const Text(
                      'Optional. Saves a local next-due reminder from prevention.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('outcome-diy-cost-field'),
                    controller: _diyCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: UserFacingCopy.impactDiyCostLabel,
                      helperText: UserFacingCopy.impactEstimatesLabel,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  key: const Key('outcome-note-field'),
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Short note (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryCta(
                  key: const Key('outcome-save-button'),
                  label: 'Save to household memory',
                  semanticLabel: 'Save to household memory',
                  onPressed: _kind == null ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeChoice extends StatelessWidget {
  const _OutcomeChoice({
    super.key,
    required this.selected,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticLabel ?? label,
        excludeSemantics: semanticLabel != null,
        child: PaperCard(
          emphasized: selected,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryChipWrap extends StatelessWidget {
  const _MemoryChipWrap({
    required this.prefix,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final String prefix;
  final List<String> items;
  final Set<String> selected;
  final void Function(String item, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          FilterChip(
            key: Key('$prefix-$i'),
            label: Text(items[i]),
            selected: selected.contains(items[i]),
            onSelected: (value) => onToggle(items[i], value),
          ),
      ],
    );
  }
}
