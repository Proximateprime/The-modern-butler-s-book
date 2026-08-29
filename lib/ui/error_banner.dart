import 'package:flutter/material.dart';

import '../helpers/degraded_mode.dart';
import '../helpers/user_facing_error.dart';
import 'product_chrome.dart';

/// Calm, human-readable error. Never a stack trace.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    required this.message,
    this.bannerKey,
    this.messageKey,
    this.showActions = false,
    this.continueKey,
    this.startFreshKey,
    this.okKey,
    this.onContinueManually,
    this.onStartFresh,
    this.onOk,
    super.key,
  });

  factory ErrorBanner.degraded({
    required DegradedModeKind kind,
    Key? bannerKey,
    Key? messageKey,
    VoidCallback? onContinueManually,
    VoidCallback? onStartFresh,
    VoidCallback? onOk,
    Key? key,
  }) {
    return ErrorBanner(
      key: key,
      bannerKey: bannerKey ?? degradedBannerKey(kind),
      messageKey: messageKey,
      message: degradedModeMessage(kind),
      showActions: true,
      continueKey: degradedContinueKey(kind),
      startFreshKey: degradedStartFreshKey(kind),
      okKey: degradedOkKey(kind),
      onContinueManually: onContinueManually,
      onStartFresh: onStartFresh,
      onOk: onOk,
    );
  }

  final String message;
  final Key? bannerKey;
  final Key? messageKey;
  final bool showActions;
  final Key? continueKey;
  final Key? startFreshKey;
  final Key? okKey;
  final VoidCallback? onContinueManually;
  final VoidCallback? onStartFresh;
  final VoidCallback? onOk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PaperCard(
      key: bannerKey ?? const Key('error-banner'),
      tint: scheme.errorContainer.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  key: messageKey,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  key: continueKey ?? const Key('degraded-continue-manually'),
                  onPressed: onContinueManually ?? onOk,
                  child: const Text(UserFacingCopy.continueManually),
                ),
                TextButton(
                  key: startFreshKey ?? const Key('degraded-start-fresh'),
                  onPressed: onStartFresh ?? onOk ?? onContinueManually,
                  child: const Text(UserFacingCopy.startFresh),
                ),
                TextButton(
                  key: okKey ?? const Key('degraded-ok'),
                  onPressed: onOk ?? onContinueManually,
                  child: const Text(UserFacingCopy.ok),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Degraded-mode banner that can be dismissed with Continue / Start fresh / OK.
class DegradedModeBanner extends StatefulWidget {
  const DegradedModeBanner({
    required this.kind,
    this.messageKey,
    this.bannerKey,
    this.onContinueManually,
    this.onStartFresh,
    this.onOk,
    super.key,
  });

  final DegradedModeKind kind;
  final Key? messageKey;
  final Key? bannerKey;
  final VoidCallback? onContinueManually;
  final VoidCallback? onStartFresh;
  final VoidCallback? onOk;

  @override
  State<DegradedModeBanner> createState() => _DegradedModeBannerState();
}

class _DegradedModeBannerState extends State<DegradedModeBanner> {
  bool _hidden = false;

  void _dismiss(VoidCallback? extra) {
    extra?.call();
    if (mounted) {
      setState(() => _hidden = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) {
      return const SizedBox.shrink();
    }
    return ErrorBanner.degraded(
      kind: widget.kind,
      bannerKey: widget.bannerKey,
      messageKey: widget.messageKey,
      onContinueManually: () => _dismiss(widget.onContinueManually),
      onStartFresh: () => _dismiss(widget.onStartFresh),
      onOk: () => _dismiss(widget.onOk),
    );
  }
}
