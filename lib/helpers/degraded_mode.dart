import 'package:flutter/foundation.dart';

import 'user_facing_error.dart';

/// Household-facing degraded states. Never diagnosed; never a stack trace.
enum DegradedModeKind {
  packageMissing,
  offline,
  cameraDenied,
  micDenied,
  corruptSnapshot,
  resumeFailed,
}

Key degradedBannerKey(DegradedModeKind kind) {
  return switch (kind) {
    DegradedModeKind.packageMissing => const Key('error-banner-package'),
    DegradedModeKind.offline => const Key('error-banner-offline'),
    DegradedModeKind.cameraDenied => const Key('error-banner-camera'),
    DegradedModeKind.micDenied => const Key('error-banner-microphone'),
    DegradedModeKind.corruptSnapshot => const Key('error-banner-snapshot'),
    DegradedModeKind.resumeFailed => const Key('error-banner-resume'),
  };
}

String degradedModeMessage(DegradedModeKind kind) {
  return switch (kind) {
    DegradedModeKind.packageMissing => UserFacingCopy.packageUnavailable,
    DegradedModeKind.offline => UserFacingCopy.offlineGuidesStillWork,
    DegradedModeKind.cameraDenied => UserFacingCopy.photoPermissionDenied,
    DegradedModeKind.micDenied => UserFacingCopy.voicePermissionDenied,
    DegradedModeKind.corruptSnapshot => UserFacingCopy.corruptSnapshot,
    DegradedModeKind.resumeFailed => UserFacingCopy.resumeFailed,
  };
}

Key degradedContinueKey(DegradedModeKind kind) {
  return Key('degraded-${kind.name}-continue-manually');
}

Key degradedStartFreshKey(DegradedModeKind kind) {
  return Key('degraded-${kind.name}-start-fresh');
}

Key degradedOkKey(DegradedModeKind kind) {
  return Key('degraded-${kind.name}-ok');
}
