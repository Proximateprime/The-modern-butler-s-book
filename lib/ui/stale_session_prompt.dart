import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import '../models/appliance.dart';
import 'app_dependencies.dart';
import 'primary_cta.dart';

enum StaleSessionChoice { continueSession, startFresh }

/// Warns when an open session is older than [staleOpenSessionHours].
Future<StaleSessionChoice?> promptStaleSessionIfNeeded({
  required BuildContext context,
  required AppDependencies dependencies,
  required Appliance appliance,
}) async {
  if (!dependencies.isOpenSessionStale(appliance)) {
    return StaleSessionChoice.continueSession;
  }
  return showDialog<StaleSessionChoice>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          key: const Key('stale-session-dialog'),
          title: const Text(UserFacingCopy.staleSessionTitle),
          content: Text(UserFacingCopy.staleSessionBody),
          actions: [
            PrimaryCta(
              key: const Key('stale-session-continue'),
              style: PrimaryCtaStyle.text,
              label: UserFacingCopy.staleSessionContinue,
              semanticLabel: PrimaryCtaSemantics.continueAction,
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(StaleSessionChoice.continueSession),
            ),
            PrimaryCta(
              key: const Key('stale-session-start-fresh'),
              label: UserFacingCopy.staleSessionStartFresh,
              semanticLabel: PrimaryCtaSemantics.start,
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(StaleSessionChoice.startFresh),
            ),
          ],
        ),
  );
}

Future<String?> startOrResumeAfterStalePrompt({
  required BuildContext context,
  required AppDependencies dependencies,
  required Appliance appliance,
}) async {
  final choice = await promptStaleSessionIfNeeded(
    context: context,
    dependencies: dependencies,
    appliance: appliance,
  );
  if (choice == null) {
    return null;
  }
  if (choice == StaleSessionChoice.startFresh) {
    dependencies.abandonOpenSession(appliance);
  }
  return dependencies.startOrResumeSession(appliance);
}
