import 'package:flutter/material.dart';

import '../helpers/maintenance_reminder_copy.dart';
import '../helpers/user_facing_error.dart';
import '../models/maintenance_reminder.dart';
import 'app_dependencies.dart';
import 'product_chrome.dart';

class _ReminderDraft {
  const _ReminderDraft({required this.title, required this.due});

  final String title;
  final DateTime due;
}

/// Local add-reminder sheet. No push.
Future<bool> promptAndSaveMaintenanceReminder({
  required BuildContext context,
  required AppDependencies dependencies,
  required String applianceId,
  String? sessionId,
}) async {
  final draft = await showDialog<_ReminderDraft>(
    context: context,
    builder:
        (dialogContext) => _AddMaintenanceReminderDialog(
          initialDue: DateTime.now().toUtc().add(const Duration(days: 30)),
        ),
  );
  if (draft == null || draft.title.isEmpty) {
    return false;
  }
  try {
    dependencies.addMaintenanceReminder(
      applianceId: applianceId,
      note: draft.title,
      remindOn: draft.due,
      sessionId: sessionId,
    );
    return true;
  } on StateError catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
    return false;
  }
}

class _AddMaintenanceReminderDialog extends StatefulWidget {
  const _AddMaintenanceReminderDialog({required this.initialDue});

  final DateTime initialDue;

  @override
  State<_AddMaintenanceReminderDialog> createState() =>
      _AddMaintenanceReminderDialogState();
}

class _AddMaintenanceReminderDialogState
    extends State<_AddMaintenanceReminderDialog> {
  late DateTime _due;
  final TextEditingController _title = TextEditingController();

  @override
  void initState() {
    super.initState();
    _due = widget.initialDue;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      return;
    }
    Navigator.of(context).pop(_ReminderDraft(title: title, due: _due));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('add-reminder-title-field'),
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
          TextButton(
            key: const Key('add-reminder-date-button'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _due.toLocal(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (picked != null && mounted) {
                setState(() {
                  _due = DateTime.utc(picked.year, picked.month, picked.day);
                });
              }
            },
            child: Text('Due ${formatMaintenanceDate(_due)}'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('add-reminder-save-button'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Next 1–3 undone reminders. In-app only.
class UpcomingMaintenanceSection extends StatelessWidget {
  const UpcomingMaintenanceSection({
    required this.items,
    required this.applianceName,
    required this.onSetDone,
    required this.now,
    this.onSnooze,
    this.emptyMessage,
    super.key,
  });

  final List<MaintenanceReminder> items;
  final String Function(String applianceId) applianceName;
  final void Function(MaintenanceReminder item, bool done) onSetDone;
  final void Function(MaintenanceReminder item)? onSnooze;
  final DateTime now;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      if (emptyMessage == null) {
        return const SizedBox.shrink();
      }
      return PaperCard(
        child: EmptyHint(
          key: const Key('upcoming-maintenance-empty'),
          message: emptyMessage!,
        ),
      );
    }

    return PaperCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        key: const Key('upcoming-maintenance-list'),
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _MaintenanceReminderTile(
              item: items[i],
              now: now,
              tileKey: Key('upcoming-reminder-${items[i].id}'),
              applianceName: applianceName(items[i].applianceId),
              onSetDone: onSetDone,
              onSnooze: onSnooze,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full appliance reminder list with done/undone.
class ApplianceMaintenanceList extends StatelessWidget {
  const ApplianceMaintenanceList({
    required this.items,
    required this.onSetDone,
    required this.now,
    this.onSnooze,
    super.key,
  });

  final List<MaintenanceReminder> items;
  final void Function(MaintenanceReminder item, bool done) onSetDone;
  final void Function(MaintenanceReminder item)? onSnooze;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return PaperCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        key: const Key('appliance-maintenance-list'),
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _MaintenanceReminderTile(
              item: items[i],
              now: now,
              tileKey: Key('maintenance-reminder-${items[i].id}'),
              onSetDone: onSetDone,
              onSnooze: onSnooze,
            ),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceReminderTile extends StatelessWidget {
  const _MaintenanceReminderTile({
    required this.item,
    required this.now,
    required this.tileKey,
    required this.onSetDone,
    this.applianceName,
    this.onSnooze,
  });

  final MaintenanceReminder item;
  final DateTime now;
  final Key tileKey;
  final String? applianceName;
  final void Function(MaintenanceReminder item, bool done) onSetDone;
  final void Function(MaintenanceReminder item)? onSnooze;

  @override
  Widget build(BuildContext context) {
    final copy = maintenanceReminderCopy(
      item: item,
      now: now,
      applianceName: applianceName,
    );
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: tileKey,
              onTap: () => onSetDone(item, !item.done),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Checkbox(
                      value: item.done,
                      onChanged: (value) => onSetDone(item, value ?? !item.done),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copy.subtitle,
                          key: Key('maintenance-reminder-copy-${item.id}'),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onSnooze != null && !item.done) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: Key('maintenance-snooze-${item.id}'),
                  onPressed: () => onSnooze!(item),
                  child: const Text('Remind me in 30 days'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
