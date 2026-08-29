import 'dart:async';

import 'package:flutter/material.dart';

import '../helpers/groq_phrasing.dart';
import '../helpers/pro_handoff.dart';
import '../helpers/repair_log_share.dart';
import '../helpers/user_facing_error.dart';
import '../models/appliance.dart';
import '../models/session_outcome.dart';
import 'app_dependencies.dart';
import 'brand_mark.dart';
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
        title: const Row(
          children: [
            BrandMark(size: 28),
            SizedBox(width: 10),
            Flexible(child: Wordmark()),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ButlerPageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BookSectionLabel('For the technician'),
                const SizedBox(height: 8),
                Text(
                  UserFacingCopy.proHandoffLead,
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
                _ProHandoffSpokenCard(
                  dependencies: dependencies,
                  appliance: appliance,
                  outcome: outcome,
                ),
                const SizedBox(height: 16),
                PaperCard(
                  child: SelectableText(
                    handoff,
                    key: const Key('pro-handoff-preview'),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryCta(
                  key: const Key('pro-handoff-share'),
                  label: 'Share',
                  semanticLabel: 'Share',
                  icon: Icons.ios_share_outlined,
                  onPressed: () => _share(context),
                ),
                const SizedBox(height: 8),
                PrimaryCta(
                  key: const Key('pro-handoff-copy'),
                  label: 'Copy',
                  semanticLabel: 'Copy',
                  style: PrimaryCtaStyle.outlined,
                  icon: Icons.copy_outlined,
                  onPressed: () => _copy(context),
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

class _ProHandoffSpokenCard extends StatefulWidget {
  const _ProHandoffSpokenCard({
    required this.dependencies,
    required this.appliance,
    required this.outcome,
  });

  final AppDependencies dependencies;
  final Appliance appliance;
  final SessionOutcome outcome;

  @override
  State<_ProHandoffSpokenCard> createState() => _ProHandoffSpokenCardState();
}

class _ProHandoffSpokenCardState extends State<_ProHandoffSpokenCard> {
  late String _paragraph;

  @override
  void initState() {
    super.initState();
    _paragraph = formatProHandoffSpokenForSession(
      evidence: widget.dependencies.repairSessionRepository
          .evidenceForSession(widget.outcome.sessionId),
      applianceName: widget.appliance.name,
      outcome: widget.outcome,
    );
    if (widget.dependencies.groqPhrasing.shouldCallNetwork) {
      unawaited(_swap());
    }
  }

  Future<void> _swap() async {
    final packaged = _paragraph;
    final accepted = await widget.dependencies.groqPhrasing.phrase(
      GroqPhrasingRequest(
        hook: GroqPhrasingHook.proHandoff,
        family: widget.appliance.category,
        energy: groqEnergyTokenFromAppliance(widget.appliance),
        state: 'guidance',
        comfort: groqComfortToken(
          widget.dependencies.repairComfort.levelFor(
            widget.appliance.category,
          ),
        ),
        evidenceNeeded: 'pro-handoff',
        options: const [],
        lastObs: '',
        whyEngine: packaged,
        safety: 'none',
        packagedTitle: kProHandoffSpokenHeading,
        packagedWhyOneLine: packaged,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _paragraph = accepted.whyOneLine;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kProHandoffSpokenHeading, style: text.titleSmall),
          const SizedBox(height: 8),
          SelectableText(
            _paragraph,
            key: const Key('pro-handoff-spoken'),
          ),
        ],
      ),
    );
  }
}
