import 'dryer_close_path.dart';
import 'thermal_reset_scope.dart';

/// Early warning shown before numbered Safe Guidance when DIY cannot finish.
const String proScopeWarningTitle = 'A full fix likely needs a pro';

const String proScopeWarningBody =
    'You can still do the safe checks below. They help confirm the issue and '
    'give a technician better information. If we’re right, you won’t be able '
    'to finish the repair yourself at home.';

/// Shown at the conclusion, before the decision / parts / tools steps.
const String proScopeNoticeBody =
    'The safe checks below are still worth doing — they confirm the problem '
    'and give a technician better information. Plan on a technician for the '
    'repair itself.';

const String proScopeDoSafeChecksLabel = 'Do safe checks';

const String proScopeEndSessionLabel = 'End session';

const String proRecommendedTitle = 'Pro recommended';

const String proHandoffUnderstandLabel = 'I understand — end session';

const String proHandoffCouldNotLabel = "I couldn't";

/// Terminal “call a pro” copy — not a numbered DIY repair step.
bool isProHandoffGuidanceStep(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('not a completed repair')) {
    return true;
  }
  if (lower.contains('new fuse alone')) {
    return true;
  }
  if (lower.contains('stop here and call')) {
    return true;
  }
  if (lower.contains('qualified technician')) {
    return true;
  }
  if (lower.contains('escalate to a')) {
    return true;
  }
  if (lower.contains('high-voltage dryer supply work is not a beginner')) {
    return true;
  }
  if (lower.contains('call a professional') &&
      !lower.contains('optional')) {
    return true;
  }
  if (lower.contains('call a technician') &&
      !lower.contains('otherwise') &&
      !lower.contains('optional')) {
    return true;
  }
  return false;
}

/// Package marks this path as unable to finish as beginner DIY at home.
///
/// Heater-circuit leaders are an id set — not the
/// [isProHandoffGuidanceStep] substring. Resettable thermal cutoff stays DIY.
bool closePathDiyCannotComplete(FailureModeClosePath path) {
  if (isResettableThermalPath(path.failureModeId) &&
      path.allowResolvedWhenConfirmed) {
    return false;
  }
  if (isHeaterCircuitDiyCannotCompleteLeader(path.failureModeId)) {
    return true;
  }
  if (!path.allowResolvedWhenConfirmed) {
    return true;
  }
  return path.safeGuidanceSteps.any(isProHandoffGuidanceStep);
}

/// Numbered Safe Guidance only — handoff copy is an outcome, not a step.
List<String> safeCheckGuidanceSteps(List<String> steps) {
  return [
    for (final step in steps)
      if (!isProHandoffGuidanceStep(step)) step,
  ];
}

/// Plain-language reason from the path, not generic filler.
String proHandoffWhy(FailureModeClosePath path) {
  switch (path.failureModeId) {
    case 'thermal-fuse-open':
      return 'The remaining work is electrical: a technician needs to test '
          'and replace the thermal fuse with the dryer fully unplugged. '
          'Confirming no warmth is not a completed home repair. A new fuse '
          'without fixing restricted airflow can open again.';
    case 'heating-element-failed':
      return 'The remaining work is heater-circuit service. Beginner steps '
          'stop at settings, the wall plug, and airflow. Live probing and '
          'element replacement are not DIY.';
    case 'electric-supply-connection-fault':
      return 'High-voltage dryer supply work is not a beginner DIY task. '
          'After checking that the plug is seated, remaining work needs a '
          'qualified technician.';
    case 'motor-failure':
      return 'The remaining work is motor service. This guide will not open '
          'motor wiring or test live windings.';
    default:
      final why = path.verificationWhy.trim();
      if (why.isNotEmpty) {
        return why;
      }
      return 'This path cannot be finished as a home DIY repair. A qualified '
          'technician needs to complete the remaining work.';
  }
}

/// Short bullets a household can read to a technician.
List<String> proHandoffTellTechnician(FailureModeClosePath path) {
  switch (path.failureModeId) {
    case 'thermal-fuse-open':
      return [
        'Dryer tumbles with no warmth after a heat cycle.',
        'Airflow was checked at the lint filter, vent hood, and visible hose.',
        'Do not jumper the thermal fuse. Fix airflow before replacing a fuse.',
      ];
    case 'heating-element-failed':
      return [
        'Heat cycle was selected and the drum turns, but clothes stay cold.',
        'Wall plug was checked from the outside only — no live metering.',
        'Heater terminals were not probed. Element service is requested.',
      ];
    case 'electric-supply-connection-fault':
      return [
        'Plug was checked from the outside. Cord and receptacle were not opened.',
        'No live voltage was measured.',
      ];
    case 'motor-failure':
      return [
        'Door and drum jam were checked. Humming or no-turn remains.',
        'Motor wiring was not opened or tested live.',
      ];
    default:
      return [
        'Share the observations listed above.',
        'Beginner-safe checks were done; remaining work is out of home DIY scope.',
      ];
  }
}
