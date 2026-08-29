import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import 'app_dependencies.dart';
import 'product_chrome.dart';

/// Returns false if the user dismissed without acknowledging.
Future<bool> ensureSafetyDisclaimerAcknowledged({
  required BuildContext context,
  required AppDependencies dependencies,
}) async {
  if (dependencies.disclaimerAcknowledged) {
    return true;
  }
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder:
          (context) => SafetyDisclaimerScreen(
            onAcknowledged: dependencies.acknowledgeDisclaimer,
          ),
    ),
  );
  return result == true && dependencies.disclaimerAcknowledged;
}

/// Short legal/safety notice. Does not replace in-session hard-stops.
class SafetyDisclaimerScreen extends StatelessWidget {
  const SafetyDisclaimerScreen({
    this.onAcknowledged,
    this.readOnly = false,
    super.key,
  });

  final Future<void> Function()? onAcknowledged;
  final bool readOnly;

  Future<void> _acknowledge(BuildContext context) async {
    await onAcknowledged?.call();
    if (!context.mounted) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('safety-disclaimer-screen'),
      appBar: AppBar(
        title: const Text(UserFacingCopy.safetyDisclaimerTitle),
        automaticallyImplyLeading: readOnly,
      ),
      body: ButlerPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  UserFacingCopy.safetyDisclaimerBody,
                  key: const Key('safety-disclaimer-body'),
                  style: text.bodyLarge?.copyWith(height: 1.45),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (readOnly)
              FilledButton(
                key: const Key('safety-disclaimer-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              )
            else
              FilledButton(
                key: const Key('safety-disclaimer-acknowledge'),
                onPressed: () => _acknowledge(context),
                child: const Text(UserFacingCopy.safetyDisclaimerAcknowledge),
              ),
          ],
        ),
      ),
    );
  }
}
