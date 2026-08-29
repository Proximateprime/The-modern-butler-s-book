/// User-accessible reset / auto-reset thermal protection — not a panel fuse swap.
const String accessibleThermalResetModeId = 'accessible-thermal-reset';

const String motorOverheatProtectorModeId = 'motor-overheat-protector-open';

/// Modes where a household can try cooldown / a visible reset, then fix airflow.
const Set<String> resettableThermalModeIds = {
  accessibleThermalResetModeId,
  motorOverheatProtectorModeId,
};

bool isResettableThermalPath(String? failureModeId) {
  final id = failureModeId?.trim() ?? '';
  return resettableThermalModeIds.contains(id);
}
