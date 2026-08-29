import '../helpers/close_path_phase.dart';

/// Ephemeral session UI fields that must survive leaving SessionScreen.
///
/// Deterministic only — no ranking or LLM. Evidence/primary live in the
/// repositories; this only remembers which question/verification panel was
/// open, problem-starter confirmation, and guidance step completion for
/// Continue repair.
class SessionUiResumeState {
  const SessionUiResumeState({
    this.pendingObservationTemplateId,
    this.pendingCloseVerificationFailureModeId,
    this.revisingObservationTemplateId,
    this.starterConfirmed = false,
    this.starterSymptomIds = const [],
    this.readinessHaveByToolId = const {},
    this.readinessContinueWithCaution = false,
    this.opportunisticSkippedAll = false,
    this.opportunisticAcceptedLabels = const [],
    this.skipToBestGuess = false,
    this.closePathPhase = ClosePathPhase.conclusion,
    this.choseRepair = false,
    this.guidanceStepIndex = 0,
    this.completedGuidanceStepIds = const [],
    this.proScopeAcknowledged = false,
    this.inspectReviewOnly = false,
    this.easierPathsExhausted = const [],
    this.starterLimitedGuidance = false,
  });

  final String? pendingObservationTemplateId;
  final String? pendingCloseVerificationFailureModeId;
  final String? revisingObservationTemplateId;
  final bool starterConfirmed;
  final List<String> starterSymptomIds;
  final Map<String, bool> readinessHaveByToolId;
  final bool readinessContinueWithCaution;
  final bool opportunisticSkippedAll;
  final List<String> opportunisticAcceptedLabels;
  final bool skipToBestGuess;
  final ClosePathPhase closePathPhase;
  final bool choseRepair;
  final int guidanceStepIndex;
  final List<String> completedGuidanceStepIds;
  final bool proScopeAcknowledged;
  final bool inspectReviewOnly;
  final List<String> easierPathsExhausted;
  final bool starterLimitedGuidance;

  bool get isEmpty =>
      pendingObservationTemplateId == null &&
      pendingCloseVerificationFailureModeId == null &&
      revisingObservationTemplateId == null &&
      !starterConfirmed &&
      starterSymptomIds.isEmpty &&
      readinessHaveByToolId.isEmpty &&
      !readinessContinueWithCaution &&
      !opportunisticSkippedAll &&
      opportunisticAcceptedLabels.isEmpty &&
      !skipToBestGuess &&
      closePathPhase == ClosePathPhase.conclusion &&
      !choseRepair &&
      guidanceStepIndex == 0 &&
      completedGuidanceStepIds.isEmpty &&
      !proScopeAcknowledged &&
      !inspectReviewOnly &&
      easierPathsExhausted.isEmpty &&
      !starterLimitedGuidance;

  SessionUiResumeState copyWith({
    String? pendingObservationTemplateId,
    String? pendingCloseVerificationFailureModeId,
    String? revisingObservationTemplateId,
    bool? starterConfirmed,
    List<String>? starterSymptomIds,
    Map<String, bool>? readinessHaveByToolId,
    bool? readinessContinueWithCaution,
    bool? opportunisticSkippedAll,
    List<String>? opportunisticAcceptedLabels,
    bool? skipToBestGuess,
    ClosePathPhase? closePathPhase,
    bool? choseRepair,
    int? guidanceStepIndex,
    List<String>? completedGuidanceStepIds,
    bool? proScopeAcknowledged,
    bool? inspectReviewOnly,
    List<String>? easierPathsExhausted,
    bool? starterLimitedGuidance,
    bool clearPendingObservation = false,
    bool clearPendingCloseVerification = false,
    bool clearRevisingObservation = false,
  }) {
    return SessionUiResumeState(
      pendingObservationTemplateId:
          clearPendingObservation
              ? null
              : (pendingObservationTemplateId ??
                  this.pendingObservationTemplateId),
      pendingCloseVerificationFailureModeId:
          clearPendingCloseVerification
              ? null
              : (pendingCloseVerificationFailureModeId ??
                  this.pendingCloseVerificationFailureModeId),
      revisingObservationTemplateId:
          clearRevisingObservation
              ? null
              : (revisingObservationTemplateId ??
                  this.revisingObservationTemplateId),
      starterConfirmed: starterConfirmed ?? this.starterConfirmed,
      starterSymptomIds: starterSymptomIds ?? this.starterSymptomIds,
      readinessHaveByToolId:
          readinessHaveByToolId ?? this.readinessHaveByToolId,
      readinessContinueWithCaution:
          readinessContinueWithCaution ?? this.readinessContinueWithCaution,
      opportunisticSkippedAll:
          opportunisticSkippedAll ?? this.opportunisticSkippedAll,
      opportunisticAcceptedLabels:
          opportunisticAcceptedLabels ?? this.opportunisticAcceptedLabels,
      skipToBestGuess: skipToBestGuess ?? this.skipToBestGuess,
      closePathPhase: closePathPhase ?? this.closePathPhase,
      choseRepair: choseRepair ?? this.choseRepair,
      guidanceStepIndex: guidanceStepIndex ?? this.guidanceStepIndex,
      completedGuidanceStepIds:
          completedGuidanceStepIds ?? this.completedGuidanceStepIds,
      proScopeAcknowledged:
          proScopeAcknowledged ?? this.proScopeAcknowledged,
      inspectReviewOnly: inspectReviewOnly ?? this.inspectReviewOnly,
      easierPathsExhausted:
          easierPathsExhausted ?? this.easierPathsExhausted,
      starterLimitedGuidance:
          starterLimitedGuidance ?? this.starterLimitedGuidance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pendingObservationTemplateId != null)
        'pendingObservationTemplateId': pendingObservationTemplateId,
      if (pendingCloseVerificationFailureModeId != null)
        'pendingCloseVerificationFailureModeId':
            pendingCloseVerificationFailureModeId,
      if (revisingObservationTemplateId != null)
        'revisingObservationTemplateId': revisingObservationTemplateId,
      'starterConfirmed': starterConfirmed,
      'starterSymptomIds': starterSymptomIds,
      if (readinessHaveByToolId.isNotEmpty)
        'readinessHaveByToolId': readinessHaveByToolId,
      'readinessContinueWithCaution': readinessContinueWithCaution,
      'opportunisticSkippedAll': opportunisticSkippedAll,
      'opportunisticAcceptedLabels': opportunisticAcceptedLabels,
      'skipToBestGuess': skipToBestGuess,
      'closePathPhase': closePathPhase.name,
      'choseRepair': choseRepair,
      'guidanceStepIndex': guidanceStepIndex,
      if (completedGuidanceStepIds.isNotEmpty)
        'completedGuidanceStepIds': completedGuidanceStepIds,
      'proScopeAcknowledged': proScopeAcknowledged,
      'inspectReviewOnly': inspectReviewOnly,
      'easierPathsExhausted': easierPathsExhausted,
      'starterLimitedGuidance': starterLimitedGuidance,
    };
  }

  factory SessionUiResumeState.fromJson(Map<String, dynamic> json) {
    final rawHave = json['readinessHaveByToolId'] as Map? ?? const {};
    return SessionUiResumeState(
      pendingObservationTemplateId:
          json['pendingObservationTemplateId'] as String?,
      pendingCloseVerificationFailureModeId:
          json['pendingCloseVerificationFailureModeId'] as String?,
      revisingObservationTemplateId:
          json['revisingObservationTemplateId'] as String?,
      starterConfirmed: json['starterConfirmed'] as bool? ?? false,
      starterSymptomIds: List<String>.from(
        json['starterSymptomIds'] as List? ?? const [],
      ),
      readinessHaveByToolId: rawHave.map(
        (key, value) => MapEntry(key.toString(), value == true),
      ),
      readinessContinueWithCaution:
          json['readinessContinueWithCaution'] as bool? ?? false,
      opportunisticSkippedAll:
          json['opportunisticSkippedAll'] as bool? ?? false,
      opportunisticAcceptedLabels: List<String>.from(
        json['opportunisticAcceptedLabels'] as List? ?? const [],
      ),
      skipToBestGuess: json['skipToBestGuess'] as bool? ?? false,
      closePathPhase: closePathPhaseFromName(json['closePathPhase'] as String?),
      choseRepair: json['choseRepair'] as bool? ?? false,
      guidanceStepIndex: json['guidanceStepIndex'] as int? ?? 0,
      completedGuidanceStepIds: List<String>.from(
        json['completedGuidanceStepIds'] as List? ?? const [],
      ),
      proScopeAcknowledged: json['proScopeAcknowledged'] as bool? ?? false,
      inspectReviewOnly: json['inspectReviewOnly'] as bool? ?? false,
      easierPathsExhausted: List<String>.from(
        json['easierPathsExhausted'] as List? ?? const [],
      ),
      starterLimitedGuidance:
          json['starterLimitedGuidance'] as bool? ?? false,
    );
  }
}
