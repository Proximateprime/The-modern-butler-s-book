import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import 'app_dependencies.dart';

/// Local household profiles — switch home or who is using it. No cloud sign-in.
Future<void> showProfilesPicker({
  required BuildContext context,
  required AppDependencies dependencies,
  required VoidCallback onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return _ProfilesSheet(
        dependencies: dependencies,
        onChanged: onChanged,
      );
    },
  );
}

Future<String?> promptHouseholdName({
  required BuildContext context,
  String title = 'Create Household',
  String confirmLabel = 'Create',
  String fieldLabel = 'Household name',
  Key fieldKey = const Key('household-name-field'),
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => HouseholdNameDialog(
      title: title,
      confirmLabel: confirmLabel,
      fieldLabel: fieldLabel,
      fieldKey: fieldKey,
    ),
  );
}

class HouseholdNameDialog extends StatefulWidget {
  const HouseholdNameDialog({
    this.title = 'Create Household',
    this.confirmLabel = 'Create',
    this.fieldLabel = 'Household name',
    this.fieldKey = const Key('household-name-field'),
    super.key,
  });

  final String title;
  final String confirmLabel;
  final String fieldLabel;
  final Key fieldKey;

  @override
  State<HouseholdNameDialog> createState() => _HouseholdNameDialogState();
}

class _HouseholdNameDialogState extends State<HouseholdNameDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      Navigator.of(context).pop(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.fieldLabel),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-household-button'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _ProfilesSheet extends StatefulWidget {
  const _ProfilesSheet({
    required this.dependencies,
    required this.onChanged,
  });

  final AppDependencies dependencies;
  final VoidCallback onChanged;

  @override
  State<_ProfilesSheet> createState() => _ProfilesSheetState();
}

class _ProfilesSheetState extends State<_ProfilesSheet> {
  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    final households = dependencies.listHouseholds();
    final members = dependencies.listHouseholdMembers();
    final currentHouseholdId = dependencies.currentHousehold?.id;
    final currentMemberId = dependencies.currentMember?.id;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profiles',
              key: const Key('profiles-sheet-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'People in this house share appliances, tools, and the House Book. '
              'Homes stay separate. Stored on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (currentHouseholdId != null) ...[
              const SizedBox(height: 12),
              Text(
                'Who is using this house',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final member in members)
                RadioListTile<String>(
                  key: Key('member-choice-${member.id}'),
                  value: member.id,
                  groupValue: currentMemberId,
                  title: Text(member.displayName),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    dependencies.switchMember(value);
                    widget.onChanged();
                    Navigator.of(context).pop();
                  },
                ),
              OutlinedButton.icon(
                key: const Key('add-member-button'),
                onPressed: () => _addMember(context),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add person'),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Homes on this device',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final household in households)
              RadioListTile<String>(
                key: Key('profile-choice-${household.id}'),
                value: household.id,
                groupValue: currentHouseholdId,
                title: Text(household.name),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  dependencies.switchHousehold(value);
                  widget.onChanged();
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('add-profile-button'),
              onPressed: () => _addProfile(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add home'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMember(BuildContext context) async {
    final name = await promptHouseholdName(
      context: context,
      title: 'Add person',
      confirmLabel: 'Add',
      fieldLabel: 'Name',
      fieldKey: const Key('member-name-field'),
    );
    if (name == null || !context.mounted) {
      return;
    }
    try {
      widget.dependencies.addHouseholdMember(name);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
      return;
    }
    widget.onChanged();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addProfile(BuildContext context) async {
    final name = await promptHouseholdName(
      context: context,
      title: 'Add home',
      confirmLabel: 'Add',
    );
    if (name == null || !context.mounted) {
      return;
    }
    try {
      widget.dependencies.createHousehold(name);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
      return;
    }
    widget.onChanged();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
