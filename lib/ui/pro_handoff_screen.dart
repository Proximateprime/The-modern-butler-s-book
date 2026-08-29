import 'package:flutter/material.dart';

import '../helpers/pro_handoff.dart';
import '../helpers/repair_log_share.dart';
import '../helpers/user_facing_error.dart';
import '../models/appliance.dart';
import '../models/session_outcome.dart';
import 'app_dependencies.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';

/// After “Needs a professional”: preview, share, and copy a technician handoff.
class ProHandoffScreen extends StatelessWidget {
  const ProHandoffScreen({
    required this.dependencies,
    required this.appliance,
    required this.outcome,
    super.key,
  });

  final AppDependencies dependencies;
  final Appliance appliance;
  final SessionOutcome outcome;

  String get _text {
    return formatProHandoffForSession(
      evidence: dependencies.repairSessionRepository.evidenceForSession(
        outcome.sessionId,
      ),
      package: dependencies.packageForSession(outcome.sessionId),
      applianceName: appliance.name,
      appliance: appliance,
      outcome: outcome,
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      await shareRepairLogText(_text, subject: 'Technician handoff');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    try {
      await copyRepairLogText(_text);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied. Paste this for a technician.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final handoff = _text;
    return Scaffold(
      key: const Key('pro-handoff-screen'),
      appBar: AppBar(
        title: const Text('Technician handoff'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ButlerPageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share this with a technician',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  appliance.name,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                PaperCard(
                  child: SelectableText(
                    handoff,
                    key: const Key('pro-handoff-preview'),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('pro-handoff-share'),
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('pro-handoff-copy'),
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
                const SizedBox(height: 24),
                PrimaryCta(
                  key: const Key('completion-save-home'),
                  label: 'Save & go home',
                  semanticLabel: 'Save and go home',
                  style: PrimaryCtaStyle.tonal,
                  onPressed: () => _goHome(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
