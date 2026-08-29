import 'package:flutter/material.dart';

import '../helpers/pro_handoff.dart';
import '../helpers/repair_log_export.dart';
import '../helpers/repair_log_share.dart';
import '../helpers/user_facing_error.dart';
import '../models/appliance.dart';
import '../models/session_outcome.dart';
import 'app_dependencies.dart';

List<String> _completedGuidanceStepIdsFor(
  AppDependencies dependencies,
  String sessionId,
) {
  final sessionIds = dependencies.repairSessionRepository
          .getSession(sessionId)
          ?.completedGuidanceStepIds ??
      const <String>[];
  if (sessionIds.isNotEmpty) {
    return sessionIds;
  }
  return dependencies.uiResumeForSession(sessionId)?.completedGuidanceStepIds ??
      const <String>[];
}

/// Share a closed repair as local plain text. No cloud.
class RepairLogExportButton extends StatelessWidget {
  const RepairLogExportButton({
    required this.sessionId,
    required this.applianceName,
    required this.date,
    required this.outcome,
    this.dependencies,
    this.appliance,
    super.key,
  });

  final String sessionId;
  final String applianceName;
  final DateTime? date;
  final SessionOutcome outcome;
  final AppDependencies? dependencies;
  final Appliance? appliance;

  Future<void> _share(BuildContext context) async {
    try {
      final deps = dependencies;
      if (outcome.closeKind == SessionCloseKind.calledProfessional &&
          deps != null) {
        await shareRepairLogText(
          formatProHandoffForSession(
            evidence: deps.repairSessionRepository.evidenceForSession(
              outcome.sessionId,
            ),
            package: deps.packageForSession(outcome.sessionId),
            applianceName: applianceName,
            appliance: appliance,
            outcome: outcome,
            date: date,
            completedGuidanceStepIds: _completedGuidanceStepIdsFor(
              deps,
              outcome.sessionId,
            ),
          ),
          subject: 'Technician handoff',
        );
        return;
      }
      await shareRepairLogExport(
        applianceName: applianceName,
        date: date,
        outcome: outcome,
        premiumFormatting:
            deps?.entitlement.allowsPremiumExportFormatting ?? false,
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

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key('export-repair-$sessionId'),
      tooltip: outcome.closeKind == SessionCloseKind.calledProfessional
          ? 'Share technician handoff'
          : 'Export / Share',
      onPressed: () => _share(context),
      icon: const Icon(Icons.ios_share_outlined),
    );
  }
}
