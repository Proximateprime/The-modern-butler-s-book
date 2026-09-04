import '../models/knowledge_package.dart';
import 'dryer_close_path.dart';

/// How much of a loaded knowledge package we may trust at runtime.
///
/// Diagnosis only happens on [usable]. Thin packages may still ask authored
/// observation templates. Missing/corrupt never invent failure modes.
enum PackageUsabilityKind {
  usable,
  missing,
  thin,
  corrupt,
}

PackageUsabilityKind assessKnowledgePackage(KnowledgePackage? package) {
  if (package == null) {
    return PackageUsabilityKind.missing;
  }
  if (package.id.trim().isEmpty || package.category.trim().isEmpty) {
    return PackageUsabilityKind.corrupt;
  }
  if (package.failureModes.isEmpty || package.evidenceTemplates.isEmpty) {
    return PackageUsabilityKind.thin;
  }
  return PackageUsabilityKind.usable;
}

/// True when ranking may name a failure mode or close-path part swap.
bool packageCanDiagnose(KnowledgePackage? package) {
  return assessKnowledgePackage(package) == PackageUsabilityKind.usable;
}

bool packageFailureModeExists(KnowledgePackage? package, String? failureModeId) {
  final id = failureModeId?.trim() ?? '';
  if (package == null || id.isEmpty) {
    return false;
  }
  for (final mode in package.failureModes) {
    if (mode.id == id) {
      return true;
    }
  }
  return false;
}

/// Close-path lookup that refuses hardcoded dryer maps when the FM is absent.
FailureModeClosePath? closePathIfAuthoredInPackage({
  required KnowledgePackage? package,
  required String? failureModeId,
}) {
  if (!packageFailureModeExists(package, failureModeId)) {
    return null;
  }
  return closePathForFailureMode(failureModeId!);
}
