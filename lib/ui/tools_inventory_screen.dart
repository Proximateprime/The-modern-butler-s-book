import 'package:flutter/material.dart';

import '../helpers/household_tools.dart';
import '../helpers/user_facing_error.dart';
import 'app_dependencies.dart';
import 'product_chrome.dart';

/// Household-owned tools. Add and remove only — no ranking.
class ToolsInventoryScreen extends StatefulWidget {
  const ToolsInventoryScreen({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<ToolsInventoryScreen> createState() => _ToolsInventoryScreenState();
}

class _ToolsInventoryScreenState extends State<ToolsInventoryScreen> {
  final TextEditingController _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  List<String> get _owned =>
      widget.dependencies.currentHousehold?.ownedToolIds ?? const [];

  Future<void> _add(String toolId) async {
    setState(() {
      widget.dependencies.rememberOwnedTool(toolId);
    });
    await widget.dependencies.flushPersist();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _remove(String toolId) async {
    setState(() {
      widget.dependencies.forgetOwnedTool(toolId);
    });
    await widget.dependencies.flushPersist();
    if (mounted) {
      setState(() {});
    }
  }

  void _addCustom() {
    final id = toolIdFromInventoryLabel(_custom.text);
    if (id == null) {
      return;
    }
    _add(id);
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final household = widget.dependencies.currentHousehold;
    final owned = _owned;
    final availableCatalog =
        catalogHouseholdTools
            .where((tool) => !owned.contains(tool.id))
            .toList();

    return Scaffold(
      key: const Key('tools-inventory-screen'),
      appBar: AppBar(title: const Text('Tools')),
      body: ButlerPageBody(
        child: ListView(
          children: [
            Text(
              household == null
                  ? UserFacingCopy.toolsNeedHousehold
                  : 'Tools you own. Repair checklists use this list when a '
                      'needed tool is already here.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            const BookSectionLabel('Owned'),
            const SizedBox(height: 12),
            if (household == null || owned.isEmpty)
              PaperCard(
                child: EmptyHint(
                  key: const Key('tools-inventory-empty'),
                  message:
                      household == null
                          ? UserFacingCopy.emptyToolsNoHousehold
                          : UserFacingCopy.emptyTools,
                ),
              )
            else
              PaperCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < owned.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        key: Key('tools-owned-${owned[i]}'),
                        title: Text(householdToolLabel(owned[i])),
                        trailing: IconButton(
                          key: Key('tools-remove-${owned[i]}'),
                          tooltip: 'Remove',
                          onPressed: () => _remove(owned[i]),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (household != null) ...[
              const SizedBox(height: 28),
              const BookSectionLabel('Add a tool'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tool in availableCatalog)
                    OutlinedButton(
                      key: Key('tools-add-${tool.id}'),
                      onPressed: () => _add(tool.id),
                      child: Text(tool.label),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('tools-custom-name-field'),
                controller: _custom,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Something else',
                  hintText: 'e.g. hex key',
                ),
                onSubmitted: (_) => _addCustom(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('tools-add-custom-button'),
                onPressed: _addCustom,
                child: const Text('Add'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
