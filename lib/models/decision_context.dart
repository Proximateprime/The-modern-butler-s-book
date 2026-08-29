import '../helpers/package_authoring_index.dart';
import 'evidence.dart';
import 'hypothesis.dart';
import 'knowledge_package.dart';
import 'knowledge_package_ref.dart';
import 'repair_session.dart';
import 'tool.dart';

/// Immutable shared snapshot of the current Repair Session context.
///
/// This object contains data only. It performs no diagnosis, confidence
/// calculation, safety decision, or question selection.
///
/// Session glue passes this one snapshot into ranking display, readiness, and
/// outcome so those surfaces do not invent parallel session state.
class DecisionContext {
  DecisionContext._({
    required this.session,
    required List<Evidence> evidence,
    required List<Hypothesis> currentHypotheses,
    required this.safetyLevel,
    required this.userComfortLevel,
    required List<Tool> availableTools,
    required this.packageRef,
    this.package,
    this.authoringIndex,
  })  : evidence = List.unmodifiable(evidence),
        evidenceIds = List.unmodifiable(evidence.map((item) => item.id)),
        currentHypotheses = List.unmodifiable(currentHypotheses),
        availableTools = List.unmodifiable(availableTools);

  final RepairSession session;
  final List<Evidence> evidence;
  final List<String> evidenceIds;
  final List<Hypothesis> currentHypotheses;
  final String safetyLevel;
  final String userComfortLevel;
  final List<Tool> availableTools;
  final KnowledgePackageRef packageRef;

  /// Resolved package body when the session ref loads. Null if missing.
  final KnowledgePackage? package;

  /// Runtime authoring index for the resolved package. Null if missing.
  final PackageAuthoringIndex? authoringIndex;

  String get sessionId => session.id;
  RepairSessionState get currentState => session.currentState;
  String get schemaVersion => session.schemaVersion;

  /// Confirmed Primary, if the user has accepted one. Not a ranking leader.
  Hypothesis? get primaryHypothesis {
    for (final hypothesis in currentHypotheses) {
      if (hypothesis.status == HypothesisStatus.confirmed) {
        return hypothesis;
      }
    }
    return null;
  }

  String? get primaryFailureModeId => primaryHypothesis?.failureModeId;

  /// Rebuilds this snapshot with a computed safety level.
  DecisionContext withSafetyLevel(String safetyLevel) {
    return DecisionContext._(
      session: session,
      evidence: evidence,
      currentHypotheses: currentHypotheses,
      safetyLevel: safetyLevel,
      userComfortLevel: userComfortLevel,
      availableTools: availableTools,
      packageRef: packageRef,
      package: package,
      authoringIndex: authoringIndex,
    );
  }

  /// Attaches a loaded package without changing session evidence or hypotheses.
  DecisionContext withResolvedKnowledge({
    KnowledgePackage? package,
    PackageAuthoringIndex? authoringIndex,
  }) {
    return DecisionContext._(
      session: session,
      evidence: evidence,
      currentHypotheses: currentHypotheses,
      safetyLevel: safetyLevel,
      userComfortLevel: userComfortLevel,
      availableTools: availableTools,
      packageRef: packageRef,
      package: package,
      authoringIndex: authoringIndex,
    );
  }

  /// Builds a pure data snapshot from existing session-domain records.
  factory DecisionContext.fromSession({
    required RepairSession session,
    required List<Evidence> evidence,
    List<Hypothesis> currentHypotheses = const [],
    String safetyLevel = 'unknown',
    String userComfortLevel = 'unknown',
    List<Tool> availableTools = const [],
    required KnowledgePackageRef packageRef,
    KnowledgePackage? package,
    PackageAuthoringIndex? authoringIndex,
  }) {
    for (final item in evidence) {
      if (item.sessionId != session.id) {
        throw StateError(
          'Evidence "${item.id}" does not belong to session "${session.id}".',
        );
      }
    }

    for (final hypothesis in currentHypotheses) {
      if (hypothesis.sessionId != session.id) {
        throw StateError(
          'Hypothesis "${hypothesis.id}" does not belong to session '
          '"${session.id}".',
        );
      }
    }

    if (packageRef.id != session.packageId ||
        packageRef.version != session.packageVersion) {
      throw StateError(
        'Knowledge package reference does not match session "${session.id}".',
      );
    }

    return DecisionContext._(
      session: session,
      evidence: evidence,
      currentHypotheses: currentHypotheses,
      safetyLevel: safetyLevel,
      userComfortLevel: userComfortLevel,
      availableTools: availableTools,
      packageRef: packageRef,
      package: package,
      authoringIndex: authoringIndex,
    );
  }
}
