import 'dryer_close_path.dart';
import 'pro_scope.dart';
import 'thermal_reset_scope.dart';

/// High-stakes DIY where a mistake can brick the machine or create a hazard.
///
/// Diagnosis and optional guidance still proceed. The user decides whether to
/// continue. Gas, sealed-system, and beginner live-electrical stay blocked.
const Set<String> diyBrickRiskModeIds = {
  'broken-drive-belt',
  'worn-drum-rollers',
  'idler-pulley-wear',
  'front-drum-bearing-wear',
  'rear-drum-bearing-wear',
  'blower-wheel-obstruction',
};

const String brickRiskWarningTitle = 'Easy to damage if this goes wrong';

const String brickRiskWarningBody =
    'A mistake on this job can permanently damage the appliance or create a '
    'hazard. A professional is recommended. You can still do the safe checks '
    'and optional steps below. You decide whether to continue or stop.';

const String brickRiskContinueLabel = 'Continue with extra care';

const String brickRiskCallProLabel = 'Call a pro instead';

bool closePathHasBrickRisk(FailureModeClosePath path) {
  if (diyBrickRiskModeIds.contains(path.failureModeId)) {
    return true;
  }
  final notes = path.verificationWhy.toLowerCase();
  return notes.contains('brick') || notes.contains('permanently damage');
}

/// Brick-risk warning is for high-stakes DIY — not a substitute for pro-only.
bool shouldShowBrickRiskWarning(FailureModeClosePath path) {
  if (closePathDiyCannotComplete(path) &&
      !isResettableThermalPath(path.failureModeId)) {
    return false;
  }
  return closePathHasBrickRisk(path);
}
