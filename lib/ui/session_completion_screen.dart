import 'package:flutter/material.dart';

import '../helpers/maintenance_reminder_copy.dart';
import '../helpers/parts_cost.dart';
import '../helpers/session_timeline.dart';
import '../helpers/user_facing_error.dart';
import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../models/appliance.dart';
import '../models/repair_comfort_profile.dart';
import '../models/session_outcome.dart';
import '../services/ranking_service.dart';
import 'app_dependencies.dart';
import 'how_we_got_here_tile.dart';
import 'parts_cost_card.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';

/// Post-Fixed wrap-up: conclusion, what you did, and short prevention.
///
/// Household memory is already written. This screen does not rank or diagnose.
class SessionCompletionScreen extends StatefulWidget {
  const SessionCompletionScreen({
    required this.dependencies,
    required this.appliance,
    required this.outcome,
    super.key,
  });

  final AppDependencies dependencies;
  final Appliance appliance;
  final SessionOutcome outcome;

  @override
  State<SessionCompletionScreen> createState() =>
      _SessionCompletionScreenState();
}

class _SessionCompletionScreenState extends State<SessionCompletionScreen> {
  bool _showReminder = false;
  bool _reminderSaved = false;
  bool _comfortAskHidden = false;
  bool _comfortShortened = false;
  late DateTime _remindOn;
  final TextEditingController _reminderNote = TextEditingController();

  @override
  void initState() {
    super.initState();
    final recorded = widget.outcome.recordedAt ?? DateTime.now().toUtc();
    _reminderNote.text = _preferredMaintenanceNote();
    final interval = inferMaintenanceIntervalDays(_reminderNote.text);
    _remindOn = recorded.add(
      Duration(days: interval ?? typicalCalendarMaintenanceDays),
    );
    _reminderSaved = widget.dependencies
        .maintenanceRemindersForAppliance(widget.appliance.id)
        .any((item) => item.sessionId == widget.outcome.sessionId);
  }

  @override
  void dispose() {
    _reminderNote.dispose();
    super.dispose();
  }

  String get _concluded {
    final leader = widget.outcome.rankingLeaderLabel?.trim();
    if (leader != null && leader.isNotEmpty) {
      return leader;
    }
    final root = widget.outcome.rootCause?.trim();
    if (root != null && root.isNotEmpty) {
      return root;
    }
    return widget.outcome.immediateCause;
  }

  String get _whatYouDid {
    final cause = widget.outcome.immediateCause.trim();
    final leader = widget.outcome.rankingLeaderLabel?.trim();
    if (leader != null &&
        leader.isNotEmpty &&
        cause.toLowerCase() == leader.toLowerCase()) {
      return 'You completed the beginner-safe checks for this repair.';
    }
    if (cause.isNotEmpty) {
      return cause;
    }
    return 'You completed the beginner-safe checks for this repair.';
  }

  List<String> get _prevention {
    return [
      for (final item in widget.outcome.preventiveActions)
        if (item.trim().isNotEmpty) item.trim(),
    ].take(3).toList();
  }

  /// Calendar reminder copy from this path's prevention — not a dryer default.
  String _preferredMaintenanceNote() {
    return preferredCalendarMaintenanceNote(_prevention);
  }

  int? get _calendarIntervalDays =>
      inferMaintenanceIntervalDays(_preferredMaintenanceNote());

  Widget _howWeGotHere() {
    String? why;
    try {
      final decisionContext = widget.dependencies.buildDecisionContext(
        widget.outcome.sessionId,
      );
      final observations = sessionTimelineObservations(decisionContext.evidence);
      if (decisionContext.package != null) {
        final snapshot = const RankingService().evaluateContext(decisionContext);
        why = leaderWhyFromStandings(
          orderedIds:
              snapshot.orderedFailureModes.map((mode) => mode.id).toList(),
          orderedLabels:
              snapshot.orderedFailureModes.map((mode) => mode.label).toList(),
          standings: snapshot.standings,
          preferredLabel: widget.outcome.rankingLeaderLabel,
        );
      }
      return HowWeGotHereTile(
        observations: observations,
        leaderWhy: why,
      );
    } on StateError {
      final evidence = widget.dependencies.repairSessionRepository
          .evidenceForSession(widget.outcome.sessionId);
      return HowWeGotHereTile(
        observations: sessionTimelineObservations(evidence),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _remindOn.toLocal(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) {
      setState(() {
        _remindOn = DateTime.utc(picked.year, picked.month, picked.day);
      });
    }
  }

  void _saveReminder() {
    final note = _reminderNote.text.trim();
    if (note.isEmpty) {
      return;
    }
    try {
      widget.dependencies.addMaintenanceReminder(
        applianceId: widget.appliance.id,
        note: note,
        remindOn: _remindOn,
        sessionId: widget.outcome.sessionId,
        intervalDays: inferMaintenanceIntervalDays(note),
      );
      setState(() {
        _reminderSaved = true;
        _showReminder = false;
      });
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final outcomeParts = partsEstimatesForSelectedPath(
      parts: FailureModeAuthoringRegistry.partsEstimatesFor(
        widget.outcome.rankingLeaderFailureModeId,
      ),
      failureModeId: widget.outcome.rankingLeaderFailureModeId,
    );
    return Scaffold(
      key: const Key('completion-done-screen'),
      appBar: AppBar(
        title: const Text('Done'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ButlerPageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Repair complete', style: text.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  widget.appliance.name,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const BookSectionLabel('What we concluded'),
                const SizedBox(height: 8),
                PaperCard(
                  child: Text(
                    _concluded,
                    key: const Key('completion-concluded'),
                  ),
                ),
                const SizedBox(height: 20),
                _howWeGotHere(),
                const SizedBox(height: 20),
                const BookSectionLabel('What you did'),
                const SizedBox(height: 8),
                PaperCard(
                  child: Text(
                    _whatYouDid,
                    key: const Key('completion-what-you-did'),
                  ),
                ),
                if (outcomeParts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  PartsCostCard(
                    parts: outcomeParts,
                  ),
                ],
                if (_prevention.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const BookSectionLabel('Prevention'),
                  const SizedBox(height: 8),
                  PaperCard(
                    child: Column(
                      key: const Key('completion-prevention'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _prevention.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          Text('• ${_prevention[i]}'),
                        ],
                        if (_calendarIntervalDays != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Typical interval: about every $_calendarIntervalDays days. '
                            'Next due ${_formatDate(_remindOn)} unless you pick another date.',
                            key: const Key('completion-maintenance-due'),
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (!_comfortAskHidden &&
                    widget.dependencies.repairComfort.shouldAskToShorten(
                      widget.appliance.category,
                    )) ...[
                  const SizedBox(height: 24),
                  PaperCard(
                    child: Column(
                      key: const Key('comfort-shorten-prompt'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          UserFacingCopy.comfortShortenAskTitle,
                          style: text.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          UserFacingCopy.comfortShortenAskBody,
                          style: text.bodyMedium?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('comfort-shorten-yes'),
                          onPressed: () {
                            widget.dependencies.setRepairComfortLevel(
                              widget.appliance.category,
                              RepairComfortLevel.shorter,
                            );
                            setState(() {
                              _comfortAskHidden = true;
                              _comfortShortened = true;
                            });
                          },
                          child: const Text(UserFacingCopy.comfortShortenYes),
                        ),
                        TextButton(
                          key: const Key('comfort-shorten-no'),
                          onPressed: () {
                            setState(() {
                              _comfortAskHidden = true;
                            });
                          },
                          child: const Text(UserFacingCopy.comfortShortenNo),
                        ),
                      ],
                    ),
                  ),
                ] else if (_comfortShortened) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Shorter steps saved for this appliance type. Change anytime in Settings.',
                    key: const Key('comfort-shorten-saved'),
                    style: text.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                if (_reminderSaved)
                  Text(
                    'Reminder saved on this device. Next due ${_formatDate(_remindOn)}. '
                    'No notification will be sent.',
                    key: const Key('completion-reminder-saved'),
                    style: text.bodySmall,
                  )
                else if (!_showReminder)
                  OutlinedButton(
                    key: const Key('completion-add-reminder'),
                    onPressed: () => setState(() => _showReminder = true),
                    child: const Text('Add maintenance reminder'),
                  )
                else ...[
                  TextField(
                    key: const Key('reminder-note-field'),
                    controller: _reminderNote,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('reminder-date-button'),
                    onPressed: _pickDate,
                    child: Text(
                      'Remind on ${_formatDate(_remindOn)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    key: const Key('reminder-save-button'),
                    onPressed: _saveReminder,
                    child: const Text('Save reminder locally'),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryCta(
                  key: const Key('completion-save-home'),
                  label: 'Save & go home',
                  semanticLabel: 'Save and go home',
                  onPressed: _goHome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime time) {
  final local = time.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
