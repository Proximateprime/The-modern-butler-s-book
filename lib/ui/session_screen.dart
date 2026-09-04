import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../helpers/blocking_reason.dart';
import '../helpers/clue_copy.dart';
import '../helpers/close_path_phase.dart';
import '../helpers/confidence_display.dart';
import '../helpers/dryer_energy_source.dart';
import '../helpers/dryer_problem_starter.dart';
import '../helpers/dryer_close_path.dart';
import '../helpers/easy_airflow_checks.dart';
import '../helpers/easy_check_already_checked.dart';
import '../helpers/washer_easy_checks.dart';
import '../helpers/washer_latch_copy.dart';
import '../helpers/dishwasher_easy_checks.dart';
import '../helpers/fridge_easy_checks.dart';
import '../helpers/degraded_mode.dart';
import '../helpers/package_usability.dart';
import '../helpers/expert_mode.dart';
import '../helpers/evidence_prompt_match.dart';
import '../helpers/free_observation_intake.dart';
import '../helpers/suggest_next_observation.dart';
import '../helpers/unmatched_starter.dart';
import '../helpers/guidance_display.dart';
import '../helpers/inspect_steps.dart';
import '../helpers/inspect_review.dart';
import '../helpers/easier_first.dart';
import '../helpers/repair_stakes.dart';
import '../models/enrichment_note.dart';
import '../helpers/investigation_stop.dart';
import '../helpers/resume_open_observation.dart';
import '../helpers/repair_readiness.dart';
import '../helpers/tool_honesty.dart';
import '../helpers/package_resolve.dart';
import '../helpers/pro_scope.dart';
import '../helpers/opportunistic_maintenance.dart';
import '../helpers/parts_cost.dart';
import '../helpers/root_cause_memory.dart';
import '../helpers/session_timeline.dart';
import '../helpers/safety_stop.dart';
import '../helpers/user_facing_error.dart';
import '../helpers/visual_guide.dart';
import '../helpers/voice_answer.dart';
import '../helpers/warranty_hint.dart';
import '../helpers/why_ask_this.dart';
import '../helpers/groq_phrasing.dart';
import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../models/appliance.dart';
import '../models/decision_context.dart';
import '../models/evidence.dart';
import '../models/hypothesis.dart';
import '../models/knowledge_package.dart';
import '../models/repair_comfort_profile.dart';
import '../models/repair_session.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import '../models/session_ui_resume_state.dart';
import '../services/diagnostic_reasoning.dart';
import '../services/evidence_photo_picker.dart';
import '../services/safety_decision_service.dart';
import '../services/voice_answer.dart';
import 'app_dependencies.dart';
import 'error_banner.dart';
import 'evidence_photo_thumb.dart';
import 'guide_loading.dart';
import 'how_we_got_here_tile.dart';
import 'household_how_to_text.dart';
import 'inspect_step_card.dart';
import 'parts_cost_card.dart';
import 'prior_root_cause_hint.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';
import 'repair_log_export_button.dart';
import 'session_outcome_screen.dart';
import 'package_manager_screen.dart';
import 'warranty_hint_card.dart';
import 'why_ask_this_tile.dart';

/// Household repair session — observations, safety, and guidance for one appliance.
class SessionScreen extends StatefulWidget {
  const SessionScreen({
    required this.dependencies,
    required this.appliance,
    required this.sessionId,
    super.key,
  });

  final AppDependencies dependencies;
  final Appliance appliance;
  final String sessionId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with WidgetsBindingObserver {
  EvidenceTemplate? _pendingAnswerPrompt;
  String? _revisingTemplateId;
  String? _pendingPhotoPath;
  FailureModeClosePath? _pendingCloseVerification;
  bool _starterConfirmed = false;
  bool _photoPermissionDenied = false;
  bool _voicePermissionDenied = false;

  bool get _photoCaptureOff =>
      _photoPermissionDenied || widget.dependencies.simulateMediaDenied;

  bool get _voiceCaptureOff =>
      _voicePermissionDenied || widget.dependencies.simulateMediaDenied;
  bool _resumeFailed = false;
  bool _guideInstalling = false;
  List<String> _starterSymptomIds = const [];
  final Set<String> _starterSelectedIds = {};
  final Set<String> _starterMatcherDismissedIds = {};
  bool _starterNeedsClarification = false;
  bool _starterLimitedGuidance = false;
  bool _inspectReviewOnly = false;
  final Set<String> _easierPathsExhausted = {};
  Map<String, bool> _readinessHaveByToolId = {};
  bool _readinessContinueWithCaution = false;
  bool _opportunisticSkippedAll = false;
  bool _skipToBestGuess = false;
  ClosePathPhase _closePathPhase = ClosePathPhase.conclusion;
  bool _choseRepair = false;
  int _guidanceStepIndex = 0;
  final List<String> _completedGuidanceStepIds = [];
  bool _proScopeAcknowledged = false;
  bool _guidanceCouldNot = false;
  final Set<String> _opportunisticAcceptedLabels = {};
  bool _voiceListening = false;
  bool _voiceHazardConfirm = false;
  GroqPhrasingAccepted? _phrasing;
  String? _phrasingScreenKey;
  final ValueNotifier<GroqPhrasingAccepted?> _phrasingNotifier =
      ValueNotifier<GroqPhrasingAccepted?>(null);
  bool _showResumeKnew = false;
  String? _resumeKnewLine;
  String? _prefetchedNextTemplateId;
  /// Last interview template painted on the answer panel. Persist this id so
  /// Continue repair does not recompute ranking’s next question on restore.
  String? _lastShownOpenInterviewTemplateId;
  List<FreeObservationSuggestion> _freeObservationSuggestions = const [];
  final TextEditingController _starterFreeTextController =
      TextEditingController();
  final TextEditingController _freeObservationController =
      TextEditingController();
  final DiagnosticReasoning _reasoning = const DiagnosticReasoning();
  final SafetyDecisionService _safety = const SafetyDecisionService();
  final ClosePathPolicyService _closePathPolicy =
      const ClosePathPolicyService();

  void _flushUiForBackground() => _persistUiResume();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.dependencies.setBeforeBackgroundFlush(_flushUiForBackground);
    widget.dependencies.noteEnteredRepairSession(widget.sessionId);
    _restoreUiResume();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeAdvanceToolsAfterRestore();
      _persistUiResume();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(widget.dependencies.persistForBackground());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.dependencies.clearBeforeBackgroundFlush(_flushUiForBackground);
    _persistUiResume();
    unawaited(widget.dependencies.flushPersist());
    _starterFreeTextController.dispose();
    _freeObservationController.dispose();
    _phrasingNotifier.dispose();
    super.dispose();
  }

  /// Restores Continue repair landing. Cases: docs/qa/RESUME_CASES.md.
  void _restoreUiResume() {
    try {
      final decisionContext =
          widget.dependencies.buildDecisionContext(widget.sessionId);
      final package = decisionContext.package;
      final resume = widget.dependencies.uiResumeForSession(widget.sessionId);

      _starterConfirmed = widget.appliance.category != 'dryer' ||
          resume?.starterConfirmed == true ||
          decisionContext.evidence.isNotEmpty;
      _starterSymptomIds = List<String>.from(
        resume?.starterSymptomIds ?? const [],
      );

      EvidenceTemplate? pendingPrompt;
      final pendingTemplateId = resume?.pendingObservationTemplateId;
      var pendingTemplateMissing = false;
      final storedOpenStillOpen = interviewTemplateIsStillOpen(
        templateId: pendingTemplateId,
        templates: package?.evidenceTemplates ?? const [],
        recordedEvidence: decisionContext.evidence,
      );
      if (pendingTemplateId != null && package != null) {
        pendingPrompt = _templateById(
          package.evidenceTemplates,
          pendingTemplateId,
        );
        if (pendingPrompt == null) {
          pendingTemplateMissing = true;
        } else if (!storedOpenStillOpen) {
          // Do not re-ask a completed chip after Continue repair.
          pendingPrompt = null;
        }
      }

      FailureModeClosePath? pendingClose;
      final pendingCloseId = resume?.pendingCloseVerificationFailureModeId;
      if (pendingCloseId != null) {
        pendingClose = closePathIfAuthoredInPackage(
          package: package,
          failureModeId: pendingCloseId,
        );
      }

      if (package != null) {
        final investigationStopped = shouldStopInvestigation(
          templates: package.evidenceTemplates,
          recordedEvidence: decisionContext.evidence,
          primaryFailureModeId: decisionContext.primaryFailureModeId,
        );
        if (investigationStopped) {
          final reasoning = _evaluateReasoning(decisionContext);
          final boundPath = _closePathBoundToConfirmedPrimary(
            rankingPath: reasoning?.closePath,
            primaryFailureModeId: decisionContext.primaryFailureModeId,
          );
          final resumePhase =
              resume?.closePathPhase ?? ClosePathPhase.conclusion;
          if (boundPath != null && resumePhase == ClosePathPhase.verification) {
            final alreadyVerified = _closePathPolicy.findVerificationEvidence(
                  evidence: decisionContext.evidence,
                  failureModeId: boundPath.failureModeId,
                ) !=
                null;
            if (!alreadyVerified) {
              pendingClose = boundPath;
            } else {
              pendingClose = null;
            }
          } else {
            pendingClose = null;
          }
        }
      }

      if (pendingClose != null) {
        pendingPrompt = null;
      }

      if (package != null &&
          pendingClose == null &&
          pendingPrompt == null &&
          !_starterLimitedGuidance &&
          dryerNeedsFuelQuestionBeforeHeatComponents(
            energySource: widget.appliance.energySource,
            recordedEvidence: decisionContext.evidence,
            templates: package.evidenceTemplates,
            starterMatchedSymptomIds: _starterSymptomIds.toSet(),
          )) {
        pendingPrompt = gasDryerTypeTemplate(package.evidenceTemplates);
      }

      _pendingAnswerPrompt = pendingPrompt;
      _revisingTemplateId = resume?.revisingObservationTemplateId;
      _pendingCloseVerification = pendingClose;
      _readinessHaveByToolId = Map<String, bool>.from(
        resume?.readinessHaveByToolId ?? const {},
      );
      _readinessContinueWithCaution =
          resume?.readinessContinueWithCaution ?? false;
      _opportunisticSkippedAll = resume?.opportunisticSkippedAll ?? false;
      _skipToBestGuess = resume?.skipToBestGuess ?? false;
      final storedPhase = resume?.closePathPhase ?? ClosePathPhase.conclusion;
      _choseRepair = resume?.choseRepair == true ||
          closePathImpliesRepairChosen(storedPhase);
      _closePathPhase = storedPhase;
      final storedSession = widget.dependencies.repairSessionRepository
          .getSession(widget.sessionId);
      final sessionIds = storedSession?.completedGuidanceStepIds ?? const [];
      final resumeIds = resume?.completedGuidanceStepIds ?? const [];
      final sessionIndex = storedSession?.guidanceStepIndex ?? 0;
      final resumeIndex = resume?.guidanceStepIndex ?? 0;
      _completedGuidanceStepIds
        ..clear()
        ..addAll({...sessionIds, ...resumeIds});
      _guidanceStepIndex =
          sessionIndex > resumeIndex ? sessionIndex : resumeIndex;
      _proScopeAcknowledged = resume?.proScopeAcknowledged == true ||
          _completedGuidanceStepIds.isNotEmpty;
      _inspectReviewOnly = resume?.inspectReviewOnly == true;
      _easierPathsExhausted
        ..clear()
        ..addAll(resume?.easierPathsExhausted ?? const []);
      _starterLimitedGuidance = resume?.starterLimitedGuidance == true;
      if (resume != null && !resume.isEmpty) {
        _showResumeKnew = true;
        _resumeKnewLine = packagedResumeKnewLine(
          state: resume,
          evidence: decisionContext.evidence,
        );
      }
      _opportunisticAcceptedLabels
        ..clear()
        ..addAll(resume?.opportunisticAcceptedLabels ?? const []);
      final boundForResume = _closePathBoundToConfirmedPrimary(
        rankingPath: _evaluateReasoning(decisionContext)?.closePath,
        primaryFailureModeId: decisionContext.primaryFailureModeId,
      );
      var toolsReady = false;
      if (boundForResume != null) {
        final items = _readinessItemsFor(boundForResume.failureModeId);
        final have = _haveByToolId(items);
        toolsReady = toolsChecklistReadyForGuidance(
          items: items,
          haveByToolId: have,
          continueWithCaution: _readinessContinueWithCaution,
        );
      }
      _closePathPhase = resumeClosePathPhase(
        stored: storedPhase,
        completedIds: _completedGuidanceStepIds,
        choseRepair: _choseRepair,
        toolsChecklistComplete: toolsReady,
        hasIncompleteInspect: boundForResume != null &&
            hasIncompleteInspectStep(
              steps: _inspectStepsFor(boundForResume),
              recordedEvidence: decisionContext.evidence,
            ),
        inspectReviewOnly: _inspectReviewOnly,
      );
      if (_closePathPhase == ClosePathPhase.guidance &&
          boundForResume != null) {
        _snapGuidanceResume(boundForResume);
      }
      final landedClosePath = boundForResume != null;
      if (package != null && pendingTemplateMissing && !landedClosePath) {
        _resumeFailed = true;
      }
      final revisingId = resume?.revisingObservationTemplateId;
      if (package != null &&
          revisingId != null &&
          _templateById(package.evidenceTemplates, revisingId) == null) {
        _revisingTemplateId = null;
        if (!landedClosePath) {
          _resumeFailed = true;
        }
      }
      if (package != null &&
          _pendingCloseVerification == null &&
          _pendingAnswerPrompt == null &&
          pendingTemplateId == null &&
          !_starterLimitedGuidance &&
          _closePathPhase == ClosePathPhase.conclusion &&
          !_choseRepair) {
        final nextId = _resumeOpenInterviewTemplateId();
        if (nextId != null) {
          _pendingAnswerPrompt = _templateById(
            package.evidenceTemplates,
            nextId,
          );
        }
      }
      if (pendingTemplateId != null &&
          (storedOpenStillOpen || package == null)) {
        _lastShownOpenInterviewTemplateId = pendingTemplateId;
        if (storedOpenStillOpen &&
            _pendingAnswerPrompt == null &&
            package != null) {
          _pendingAnswerPrompt = _templateById(
            package.evidenceTemplates,
            pendingTemplateId,
          );
        }
      }
      _persistUiResume();
      unawaited(widget.dependencies.flushPersist());
    } catch (_) {
      _resumeFailed = true;
      _recoverResumeAfterError();
    }
  }

  /// Keeps Continue repair on a real screen if restore throws. Does not rank.
  void _recoverResumeAfterError() {
    try {
      final session = widget.dependencies.repairSessionRepository.getSession(
        widget.sessionId,
      );
      if (session == null) {
        return;
      }
      final resume = widget.dependencies.uiResumeForSession(widget.sessionId);
      final sessionIds = session.completedGuidanceStepIds;
      final resumeIds = resume?.completedGuidanceStepIds ?? const [];
      _completedGuidanceStepIds
        ..clear()
        ..addAll({...sessionIds, ...resumeIds});
      final sessionIndex = session.guidanceStepIndex;
      final resumeIndex = resume?.guidanceStepIndex ?? 0;
      _guidanceStepIndex =
          sessionIndex > resumeIndex ? sessionIndex : resumeIndex;
      if (resume != null) {
        _readinessHaveByToolId = Map<String, bool>.from(
          resume.readinessHaveByToolId,
        );
        _readinessContinueWithCaution = resume.readinessContinueWithCaution;
        _choseRepair = resume.choseRepair ||
            closePathImpliesRepairChosen(resume.closePathPhase);
        _closePathPhase = resumeClosePathPhase(
          stored: resume.closePathPhase,
          completedIds: _completedGuidanceStepIds,
          choseRepair: _choseRepair,
          toolsChecklistComplete: resume.readinessHaveByToolId.isNotEmpty,
          inspectReviewOnly: resume.inspectReviewOnly,
        );
        _skipToBestGuess = resume.skipToBestGuess;
        _opportunisticSkippedAll = resume.opportunisticSkippedAll;
        _inspectReviewOnly = resume.inspectReviewOnly;
        _easierPathsExhausted
          ..clear()
          ..addAll(resume.easierPathsExhausted);
        _starterLimitedGuidance = resume.starterLimitedGuidance;
        _proScopeAcknowledged =
            resume.proScopeAcknowledged || _completedGuidanceStepIds.isNotEmpty;
      } else if (_completedGuidanceStepIds.isNotEmpty) {
        _closePathPhase = ClosePathPhase.guidance;
      }
      final evidence = widget.dependencies.repairSessionRepository
          .evidenceForSession(widget.sessionId);
      _starterConfirmed = widget.appliance.category != 'dryer' ||
          resume?.starterConfirmed == true ||
          evidence.isNotEmpty;
    } catch (_) {}
  }

  FailureModeClosePath? _boundClosePathForCurrentSession() {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return null;
    }
    final decisionContext =
        widget.dependencies.buildDecisionContext(session.id);
    return _closePathBoundToConfirmedPrimary(
      rankingPath: _evaluateReasoning(decisionContext)?.closePath,
      primaryFailureModeId: decisionContext.primaryFailureModeId,
    );
  }

  void _maybeAdvanceToolsAfterRestore() {
    try {
      if (_closePathPhase == ClosePathPhase.inspect) {
        return;
      }
      final closePath = _boundClosePathForCurrentSession();
      if (closePath == null) {
        return;
      }
      if (_closePathPhase == ClosePathPhase.guidance) {
        setState(() => _snapGuidanceResume(closePath));
        _persistUiResume();
        return;
      }
      if (_closePathPhase != ClosePathPhase.tools) {
        return;
      }
      _maybeAdvanceFromTools(closePath);
    } catch (_) {
      if (mounted) {
        setState(() => _resumeFailed = true);
      }
    }
  }

  /// Interview template the household is on, including ranking’s next question
  /// when the answer panel is showing suggested-next without a tapped chip.
  ///
  /// On-screen open id wins over ranking next so Continue repair cannot swap
  /// lint-filter (or any tapped chip) for motor-humming after a cold reload.
  String? _resumeOpenInterviewTemplateId() {
    try {
      final decisionContext =
          widget.dependencies.buildDecisionContext(widget.sessionId);
      final package = decisionContext.package;
      final templates = package?.evidenceTemplates ?? const [];
      final recorded = decisionContext.evidence;
      final onScreenId =
          _pendingAnswerPrompt?.id ?? _lastShownOpenInterviewTemplateId;
      final onScreenStillOpen = interviewTemplateIsStillOpen(
        templateId: onScreenId,
        templates: templates,
        recordedEvidence: recorded,
      );
      String? rankingNextId;
      if (_pendingCloseVerification == null &&
          !_choseRepair &&
          _closePathPhase == ClosePathPhase.conclusion &&
          package != null &&
          !shouldStopInvestigation(
            templates: templates,
            recordedEvidence: recorded,
            primaryFailureModeId: decisionContext.primaryFailureModeId,
          )) {
        rankingNextId =
            _evaluateReasoning(decisionContext)?.suggestedNextTemplateId;
        final rankingTemplate = _templateById(templates, rankingNextId);
        if (rankingTemplate == null ||
            isTemplateRecorded(
              template: rankingTemplate,
              recordedEvidence: recorded,
            )) {
          rankingNextId = null;
        }
      }
      return preferOnScreenOpenObservationId(
        onScreenTemplateId: onScreenId,
        rankingSuggestedNextTemplateId: rankingNextId,
        onScreenStillOpen: onScreenStillOpen,
      );
    } catch (_) {
      final onScreenId =
          _pendingAnswerPrompt?.id ?? _lastShownOpenInterviewTemplateId;
      return onScreenId;
    }
  }

  void _persistUiResume() {
    widget.dependencies.saveSessionUiResume(
      widget.sessionId,
      SessionUiResumeState(
        pendingObservationTemplateId: _resumeOpenInterviewTemplateId(),
        pendingCloseVerificationFailureModeId:
            _pendingCloseVerification?.failureModeId,
        revisingObservationTemplateId: _revisingTemplateId,
        starterConfirmed: _starterConfirmed,
        starterSymptomIds: _starterSymptomIds,
        readinessHaveByToolId: Map<String, bool>.from(_readinessHaveByToolId),
        readinessContinueWithCaution: _readinessContinueWithCaution,
        opportunisticSkippedAll: _opportunisticSkippedAll,
        opportunisticAcceptedLabels: _opportunisticAcceptedLabels.toList(),
        skipToBestGuess: _skipToBestGuess,
        closePathPhase: _closePathPhase,
        choseRepair: _choseRepair,
        guidanceStepIndex: _guidanceStepIndex,
        completedGuidanceStepIds: List<String>.from(_completedGuidanceStepIds),
        proScopeAcknowledged: _proScopeAcknowledged,
        inspectReviewOnly: _inspectReviewOnly,
        easierPathsExhausted: _easierPathsExhausted.toList(),
        starterLimitedGuidance: _starterLimitedGuidance,
      ),
    );
  }

  void _snapGuidanceResume(FailureModeClosePath closePath) {
    final steps = _gatedGuidanceSteps(closePath);
    final index = firstIncompleteGuidanceIndex(
      steps: steps,
      completedIds: _completedGuidanceStepIds,
    );
    _guidanceStepIndex = index;
    _guidanceCouldNot = false;
    if (steps.isNotEmpty && index < steps.length) {
      _closePathPhase = ClosePathPhase.guidance;
      return;
    }
    if (closePathDiyCannotComplete(closePath)) {
      _closePathPhase = ClosePathPhase.guidance;
      return;
    }
    if (_completedGuidanceStepIds.isEmpty) {
      final items = _readinessItemsFor(closePath.failureModeId);
      final have = _haveByToolId(items);
      if (!toolsChecklistReadyForGuidance(
        items: items,
        haveByToolId: have,
        continueWithCaution: _readinessContinueWithCaution,
      )) {
        _closePathPhase = ClosePathPhase.tools;
        _guidanceStepIndex = 0;
        return;
      }
    }
    _closePathPhase = ClosePathPhase.verification;
    _pendingCloseVerification = closePath;
    _pendingAnswerPrompt = null;
  }

  void _goClosePathPhase(
    ClosePathPhase phase, {
    FailureModeClosePath? closePath,
    bool inspectReviewOnly = false,
  }) {
    if (phase == ClosePathPhase.inspect && inspectReviewOnly) {
      setState(() {
        _inspectReviewOnly = true;
        _closePathPhase = ClosePathPhase.inspect;
        _guidanceCouldNot = false;
      });
      _persistUiResume();
      return;
    }
    if (phase != ClosePathPhase.inspect) {
      _inspectReviewOnly = false;
    }
    final resolved = closePathPhaseHonoringInspect(
      requested: phase,
      hasIncompleteInspect: closePath != null &&
          !_inspectReviewOnly &&
          _hasIncompleteInspect(closePath),
    );
    setState(() {
      _closePathPhase = resolved;
      _guidanceCouldNot = false;
      if (resolved != ClosePathPhase.verification) {
        _pendingCloseVerification = null;
      }
    });
    _persistUiResume();
    if (resolved == ClosePathPhase.guidance && closePath != null) {
      final steps = _gatedGuidanceSteps(closePath);
      final index = firstIncompleteGuidanceIndex(
        steps: steps,
        completedIds: _completedGuidanceStepIds,
      );
      setState(() {
        _guidanceStepIndex = index;
        if (steps.isEmpty) {
          _closePathPhase = ClosePathPhase.verification;
          _pendingCloseVerification = closePath;
        }
      });
      _persistUiResume();
    }
  }

  List<RepairReadinessItem> _readinessItemsFor(String failureModeId) {
    return readinessItemsFromToolsRequired(
      FailureModeAuthoringRegistry.toolsRequiredFor(failureModeId),
    );
  }

  List<PartCostEstimate> _partsEstimatesFor(String? failureModeId) {
    return partsEstimatesForSelectedPath(
      parts: FailureModeAuthoringRegistry.partsEstimatesFor(failureModeId),
      failureModeId: failureModeId,
    );
  }

  Map<String, bool> _haveByToolId(List<RepairReadinessItem> items) {
    final haveByToolId = Map<String, bool>.from(_readinessHaveByToolId);
    final owned =
        widget.dependencies.currentHousehold?.ownedToolIds ?? const <String>[];
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    DecisionContext? decisionContext;
    if (session != null) {
      decisionContext = widget.dependencies.buildDecisionContext(session.id);
    }
    for (final item in items) {
      if (owned.contains(item.id) ||
          (decisionContext != null &&
              decisionOwnsTool(decisionContext, item.id))) {
        haveByToolId.putIfAbsent(item.id, () => true);
      }
    }
    return haveByToolId;
  }

  List<Evidence> _sessionEvidence() {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return const [];
    }
    return widget.dependencies.buildDecisionContext(session.id).evidence;
  }

  /// After I'll repair, keep the confirmed Primary path. Inspect chips still
  /// write ranking evidence and unlock easy-check gates on that path.
  FailureModeClosePath? _closePathBoundToConfirmedPrimary({
    required FailureModeClosePath? rankingPath,
    required String? primaryFailureModeId,
  }) {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    FailureModeClosePath? authored(FailureModeClosePath? path) {
      if (path == null) {
        return null;
      }
      return packageFailureModeExists(package, path.failureModeId)
          ? path
          : null;
    }

    if (primaryFailureModeId == null) {
      return authored(rankingPath);
    }
    if (!closePathImpliesRepairChosen(_closePathPhase) && !_choseRepair) {
      return authored(rankingPath);
    }
    return authored(
          closePathIfAuthoredInPackage(
            package: package,
            failureModeId: primaryFailureModeId,
          ),
        ) ??
        authored(rankingPath);
  }

  bool _needsEasyAirflowFirst(FailureModeClosePath closePath) {
    return closePathNeedsEasyAirflowFirst(
      closePath,
      recordedEvidence: _sessionEvidence(),
      starterMatchedSymptomIds: _starterSymptomIds.toSet(),
    );
  }

  bool _needsWasherEasyChecksFirst(FailureModeClosePath closePath) {
    return closePathNeedsWasherEasyChecksFirst(closePath);
  }

  bool _needsDishwasherEasyChecksFirst(FailureModeClosePath closePath) {
    return closePathNeedsDishwasherEasyChecksFirst(closePath);
  }

  bool _needsFridgeEasyChecksFirst(FailureModeClosePath closePath) {
    return closePathNeedsFridgeEasyChecksFirst(closePath);
  }

  String? _blockingReasonLineFor({
    required FailureModeClosePath? closePath,
    required bool safetyStop,
  }) {
    if (safetyStop) {
      return blockingReasonSafetyLine;
    }
    if (closePath == null) {
      return null;
    }
    final items = _readinessItemsFor(closePath.failureModeId);
    final have = _haveByToolId(items);
    final missing = missingRequiredTools(items: items, haveByToolId: have);
    final ordered = _orderedGuidanceSteps(closePath);
    final afterTools = guidanceStepsForToolHonesty(
      steps: ordered,
      items: items,
      haveByToolId: have,
      continueWithCaution: _readinessContinueWithCaution,
    );
    final easyAirflowActive = _needsEasyAirflowFirst(closePath);
    final washerEasyActive = _needsWasherEasyChecksFirst(closePath);
    final dishwasherEasyActive = _needsDishwasherEasyChecksFirst(closePath);
    final fridgeEasyActive = _needsFridgeEasyChecksFirst(closePath);
    final easyAirflowSatisfied = easyAirflowChecksSatisfied(
      recordedEvidence: _sessionEvidence(),
      steps: afterTools,
      completedIds: _completedGuidanceStepIds,
    );
    final washerEasySatisfied = washerEasyChecksSatisfied(
      recordedEvidence: _sessionEvidence(),
      steps: afterTools,
      completedIds: _completedGuidanceStepIds,
    );
    final dishwasherEasySatisfied = dishwasherEasyChecksSatisfied(
      recordedEvidence: _sessionEvidence(),
      steps: afterTools,
      completedIds: _completedGuidanceStepIds,
    );
    final fridgeEasySatisfied = fridgeEasyChecksSatisfied(
      recordedEvidence: _sessionEvidence(),
      steps: afterTools,
      completedIds: _completedGuidanceStepIds,
    );
    final gated = _gatedGuidanceSteps(closePath);
    String? currentStep;
    if (gated.isNotEmpty) {
      final index = firstIncompleteGuidanceIndex(
        steps: gated,
        completedIds: _completedGuidanceStepIds,
      ).clamp(0, gated.length - 1);
      currentStep = gated[index];
    }
    return blockingReasonLine(
      safetyStop: false,
      phase: _closePathPhase,
      missingRequiredTools: missing,
      toolsChecklistComplete: toolsChecklistComplete(
        items: items,
        haveByToolId: have,
      ),
      continueWithCaution: _readinessContinueWithCaution,
      easyAirflowGateActive: easyAirflowActive,
      easyAirflowSatisfied: easyAirflowSatisfied,
      washerEasyGateActive: washerEasyActive,
      washerEasySatisfied: washerEasySatisfied,
      dishwasherEasyGateActive: dishwasherEasyActive,
      dishwasherEasySatisfied: dishwasherEasySatisfied,
      fridgeEasyGateActive: fridgeEasyActive,
      fridgeEasySatisfied: fridgeEasySatisfied,
      hasIncompleteInspect: _hasIncompleteInspect(closePath),
      currentGuidanceStep: currentStep,
    );
  }

  List<String> _orderedGuidanceSteps(FailureModeClosePath closePath) {
    var steps = visibleSafeGuidanceSteps(
      closePath,
      expertMode: widget.dependencies.expertMode,
    );
    if (_needsEasyAirflowFirst(closePath)) {
      steps = orderEasyAirflowGuidanceFirst(steps);
    } else if (_needsWasherEasyChecksFirst(closePath)) {
      steps = orderWasherEasyChecksFirst(
        steps,
        failureModeId: closePath.failureModeId,
      );
    } else if (_needsDishwasherEasyChecksFirst(closePath)) {
      steps = orderDishwasherEasyChecksFirst(steps);
    } else if (_needsFridgeEasyChecksFirst(closePath)) {
      steps = orderFridgeEasyChecksFirst(steps);
    }
    return steps;
  }

  List<String> _gatedGuidanceSteps(FailureModeClosePath closePath) {
    final ordered = _orderedGuidanceSteps(closePath);
    final items = _readinessItemsFor(closePath.failureModeId);
    final have = _haveByToolId(items);
    final afterTools = guidanceStepsForToolHonesty(
      steps: ordered,
      items: items,
      haveByToolId: have,
      continueWithCaution: _readinessContinueWithCaution,
    );
    final inspectIncomplete = _hasIncompleteInspect(closePath);
    List<String> gated;
    if (_needsEasyAirflowFirst(closePath)) {
      gated = guidanceStepsForEasyAirflowGate(
        steps: afterTools,
        easyChecksSatisfied: !inspectIncomplete &&
            easyAirflowChecksSatisfied(
              recordedEvidence: _sessionEvidence(),
              steps: afterTools,
              completedIds: _completedGuidanceStepIds,
            ),
      );
    } else if (_needsWasherEasyChecksFirst(closePath)) {
      gated = guidanceStepsForWasherEasyGate(
        steps: afterTools,
        easyChecksSatisfied: !inspectIncomplete &&
            washerEasyChecksSatisfied(
              recordedEvidence: _sessionEvidence(),
              steps: afterTools,
              completedIds: _completedGuidanceStepIds,
            ),
      );
    } else if (_needsDishwasherEasyChecksFirst(closePath)) {
      gated = guidanceStepsForDishwasherEasyGate(
        steps: afterTools,
        easyChecksSatisfied: !inspectIncomplete &&
            dishwasherEasyChecksSatisfied(
              recordedEvidence: _sessionEvidence(),
              steps: afterTools,
              completedIds: _completedGuidanceStepIds,
            ),
      );
    } else if (_needsFridgeEasyChecksFirst(closePath)) {
      gated = guidanceStepsForFridgeEasyGate(
        steps: afterTools,
        easyChecksSatisfied: !inspectIncomplete &&
            fridgeEasyChecksSatisfied(
              recordedEvidence: _sessionEvidence(),
              steps: afterTools,
              completedIds: _completedGuidanceStepIds,
            ),
      );
    } else if (inspectIncomplete) {
      gated = [
        for (final step in afterTools)
          if (!isInvasiveGuidanceStep(step)) step,
      ];
    } else {
      gated = afterTools;
    }
    return safeCheckGuidanceSteps(gated);
  }

  List<InspectStep> _inspectStepsFor(FailureModeClosePath closePath) {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    return inspectStepsForClosePath(
      closePath: closePath,
      packageSteps: package?.inspectSteps ?? const [],
      applianceCategory: widget.appliance.category,
    );
  }

  bool _hasIncompleteInspect(FailureModeClosePath closePath) {
    return hasIncompleteInspectStep(
      steps: _inspectStepsFor(closePath),
      recordedEvidence: _sessionEvidence(),
    );
  }

  InspectStep? _inspectStepForTemplate(String templateId) {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    return inspectStepForEvidenceTemplate(
      templateId: templateId,
      applianceCategory: widget.appliance.category,
      packageSteps: package?.inspectSteps ?? const [],
    );
  }

  String _whyAskBody({
    EvidenceTemplate? template,
    InspectStep? inspectStep,
    required List<FailureMode> orderedFailureModes,
    required Map<String, FailureModeStanding> standings,
    required List<FailureMode> packageModes,
    bool unmatchedPath = false,
  }) {
    if (unmatchedPath || _starterLimitedGuidance) {
      return unmatchedWhyAskBody(template: template, templateId: template?.id);
    }
    final remaining = [
      for (final mode in orderedFailureModes)
        if (!(standings[mode.id]?.isWeakened ?? false)) mode,
    ];
    return whyAskThisQuestion(
      template: template,
      inspectStep: inspectStep,
      remainingModes: remaining,
      packageModes: packageModes,
    ).body;
  }

  RepairComfortLevel get _comfortLevel {
    return widget.dependencies.repairComfort.levelFor(
      widget.appliance.category,
    );
  }

  String _lastObsLine(List<Evidence> evidence) {
    if (evidence.isEmpty) {
      return '';
    }
    final last = evidence.last;
    return '${last.templateId ?? last.observation}: ${last.answer ?? ''}';
  }

  GroqPhrasingRequest _questionPhrasingRequest({
    required EvidenceTemplate template,
    required String whyEngine,
    required List<Evidence> evidence,
    bool prefetchOnly = false,
  }) {
    final options = answerChoicesFor(
      template,
      offerAlreadyChecked: widget.dependencies
          .repairHistoryForAppliance(widget.appliance.id)
          .isNotEmpty,
    );
    return GroqPhrasingRequest(
      hook: GroqPhrasingHook.questionCard,
      family: widget.appliance.category,
      energy: groqEnergyTokenFromAppliance(widget.appliance),
      state: 'evidence',
      comfort: groqComfortToken(_comfortLevel),
      evidenceNeeded: template.id,
      options: options,
      lastObs: _lastObsLine(evidence),
      whyEngine: whyEngine,
      safety: 'none',
      packagedTitle: observationPromptTitle(template),
      packagedWhyOneLine: whyEngine,
      packagedOptionLabels: {for (final id in options) id: id},
      prefetchOnly: prefetchOnly,
    );
  }

  void _ensurePhrasing(GroqPhrasingRequest request) {
    if (_phrasingScreenKey == request.screenKey && _phrasing != null) {
      return;
    }
    _phrasingScreenKey = request.screenKey;
    _phrasing = GroqPhrasingAccepted.packaged(request);
    _publishPhrasingOverlay(_phrasing);
    if (!widget.dependencies.groqPhrasing.shouldCallNetwork) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_swapPhrasing(request));
    });
  }

  Future<void> _swapPhrasing(GroqPhrasingRequest request) async {
    final accepted = await widget.dependencies.groqPhrasing.phrase(request);
    if (!mounted || _phrasingScreenKey != request.screenKey) {
      return;
    }
    setState(() {
      _phrasing = accepted;
    });
    _publishPhrasingOverlay(accepted);
  }

  void _prefetchAlreadyChosenNext({
    required String templateId,
    required List<EvidenceTemplate> templates,
    required List<Evidence> evidence,
    required List<FailureMode> orderedFailureModes,
    required Map<String, FailureModeStanding> standings,
    required List<FailureMode> packageModes,
  }) {
    if (_prefetchedNextTemplateId == templateId) {
      return;
    }
    final template = _templateById(templates, templateId);
    if (template == null) {
      return;
    }
    _prefetchedNextTemplateId = templateId;
    if (!widget.dependencies.groqPhrasing.shouldCallNetwork) {
      return;
    }
    final why = _whyAskBody(
      template: template,
      orderedFailureModes: orderedFailureModes,
      standings: standings,
      packageModes: packageModes,
    );
    unawaited(
      widget.dependencies.groqPhrasing.prefetchAlreadyChosenNext(
        _questionPhrasingRequest(
          template: template,
          whyEngine: why,
          evidence: evidence,
          prefetchOnly: true,
        ),
      ),
    );
  }

  void _publishPhrasingOverlay(GroqPhrasingAccepted? accepted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (identical(_phrasingNotifier.value, accepted)) {
        return;
      }
      _phrasingNotifier.value = accepted;
    });
  }

  GroqPhrasingAccepted? _overlayFor(String screenKey) {
    if (_phrasing != null && _phrasing!.screenKey == screenKey) {
      return _phrasing;
    }
    return null;
  }

  String? _confirmNotFixedLine({
    required FailureModeClosePath? closePath,
    required VerificationOutcome verificationOutcome,
    GroqPhrasingAccepted? overlay,
  }) {
    if (closePath == null ||
        verificationOutcome != VerificationOutcome.supported ||
        closePath.allowResolvedWhenConfirmed) {
      return null;
    }
    if (overlay != null &&
        overlay.screenKey.startsWith('confirmNotFixed|') &&
        overlay.whyOneLine.trim().isNotEmpty) {
      return overlay.whyOneLine;
    }
    return kConfirmNotFixedPackaged;
  }

  ClosePathPhase _phaseAfterInspectComplete(FailureModeClosePath closePath) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    return phaseAfterInspect(
      objective: session?.sessionObjective,
      hasTools: _readinessItemsFor(closePath.failureModeId).isNotEmpty,
      choseRepair: _choseRepair,
    );
  }

  ClosePathPhase _phaseAfterToolsReady(FailureModeClosePath closePath) {
    if (_hasIncompleteInspect(closePath)) {
      return ClosePathPhase.inspect;
    }
    if (closePathDiyCannotComplete(closePath)) {
      return ClosePathPhase.guidance;
    }
    final steps = _gatedGuidanceSteps(closePath);
    return steps.isEmpty
        ? ClosePathPhase.verification
        : ClosePathPhase.guidance;
  }

  void _maybeAdvanceFromTools(FailureModeClosePath closePath) {
    if (_closePathPhase != ClosePathPhase.tools) {
      return;
    }
    final items = _readinessItemsFor(closePath.failureModeId);
    if (items.isEmpty) {
      _goClosePathPhase(_phaseAfterToolsReady(closePath), closePath: closePath);
      return;
    }
    final have = _haveByToolId(items);
    if (!toolsChecklistReadyForGuidance(
      items: items,
      haveByToolId: have,
      continueWithCaution: _readinessContinueWithCaution,
    )) {
      return;
    }
    final next = _phaseAfterToolsReady(closePath);
    setState(() {
      _closePathPhase = next;
      _guidanceCouldNot = false;
      if (next == ClosePathPhase.guidance) {
        final steps = _gatedGuidanceSteps(closePath);
        _guidanceStepIndex = firstIncompleteGuidanceIndex(
          steps: steps,
          completedIds: _completedGuidanceStepIds,
        );
      }
      if (next == ClosePathPhase.verification) {
        _pendingCloseVerification = closePath;
      }
    });
    _persistUiResume();
  }

  void _guidanceDidThis(FailureModeClosePath closePath) {
    var steps = _gatedGuidanceSteps(closePath);
    final index = firstIncompleteGuidanceIndex(
      steps: steps,
      completedIds: _completedGuidanceStepIds,
    );
    if (steps.isEmpty || index >= steps.length) {
      _enterVerification(closePath);
      return;
    }
    final id = guidanceStepId(index, steps[index]);
    if (!_completedGuidanceStepIds.contains(id)) {
      _completedGuidanceStepIds.add(id);
    }
    // Recompute after recording this step so easy-check completion can
    // unlock invasive panel/parts steps on the next screen.
    steps = _gatedGuidanceSteps(closePath);
    final next = firstIncompleteGuidanceIndex(
      steps: steps,
      completedIds: _completedGuidanceStepIds,
    );
    setState(() {
      _guidanceCouldNot = false;
      _guidanceStepIndex = next;
      if (closePathDiyCannotComplete(closePath) &&
          (steps.isEmpty || next >= steps.length)) {
        _closePathPhase = ClosePathPhase.guidance;
      } else if (steps.isEmpty || next >= steps.length) {
        _closePathPhase = ClosePathPhase.verification;
        _pendingCloseVerification = closePath;
        _pendingAnswerPrompt = null;
      }
    });
    _persistUiResume();
  }

  void _enterVerification(FailureModeClosePath closePath) {
    if (closePathDiyCannotComplete(closePath)) {
      setState(() {
        _closePathPhase = ClosePathPhase.guidance;
        _guidanceCouldNot = false;
      });
      _persistUiResume();
      return;
    }
    setState(() {
      _closePathPhase = ClosePathPhase.verification;
      _pendingCloseVerification = closePath;
      _pendingAnswerPrompt = null;
      _guidanceCouldNot = false;
    });
    _persistUiResume();
  }

  Future<void> _endAsProfessional({
    required String? rankingLeaderLabel,
    required String? rankingLeaderFailureModeId,
  }) {
    return _endSession(
      eligibility: CloseResolveEligibility.needsProfessional,
      rankingLeaderLabel: rankingLeaderLabel,
      rankingLeaderFailureModeId: rankingLeaderFailureModeId,
      initialCloseKind: SessionCloseKind.calledProfessional,
    );
  }

  void _guidanceBack(FailureModeClosePath closePath) {
    if (_guidanceStepIndex > 0) {
      setState(() {
        _guidanceStepIndex -= 1;
        _guidanceCouldNot = false;
      });
      _persistUiResume();
      return;
    }
    final items = _readinessItemsFor(closePath.failureModeId);
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    final objective = session?.sessionObjective;
    final hasParts = closePathShowsParts(
      objective: objective,
      hasParts: _partsEstimatesFor(closePath.failureModeId).isNotEmpty,
    );
    if (items.isNotEmpty) {
      _goClosePathPhase(ClosePathPhase.tools);
      return;
    }
    if (hasParts) {
      _goClosePathPhase(ClosePathPhase.parts);
      return;
    }
    _goClosePathPhase(
      closePathShowsDecision(objective)
          ? ClosePathPhase.decision
          : ClosePathPhase.conclusion,
    );
  }

  void _clearRevisionState() {
    _revisingTemplateId = null;
  }

  void _skipToBestGuessTapped() {
    if (_currentSafetyStop() != null) {
      return;
    }
    setState(() {
      _skipToBestGuess = true;
      _pendingAnswerPrompt = null;
      _pendingPhotoPath = null;
      _lastShownOpenInterviewTemplateId = null;
      _clearRevisionState();
    });
    _persistUiResume();
  }

  void _setSessionObjective(SessionObjective objective) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null || _isTerminal(session.currentState)) {
      return;
    }
    final next = session.sessionObjective == objective ? null : objective;
    widget.dependencies.setSessionObjective(widget.sessionId, next);
    setState(() {});
  }

  void _confirmProblemStarter() {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (package == null || session == null) {
      return;
    }

    final chipIds = {
      for (final id in _starterSelectedIds)
        if (id != dryerStarterOtherDescribeId) id,
    };
    final describing =
        _starterSelectedIds.contains(dryerStarterOtherDescribeId);
    final freeText = describing ? _starterFreeTextController.text : '';
    if (chipIds.isEmpty && !describing) {
      return;
    }
    if (describing && freeText.trim().isEmpty && chipIds.isEmpty) {
      return;
    }

    var resolution = resolveDryerStarter(
      selectedSymptomIds: chipIds,
      freeText: freeText,
    );
    if (describing) {
      resolution = resolutionWithoutHeatNoiseUnlessChecked(
        resolution: resolution,
        selectedSymptomIds: chipIds,
      );
    }

    if (!resolution.hasMatch && describing && freeText.trim().isNotEmpty) {
      if (_starterNeedsClarification) {
        return;
      }
      _recordStarterEvidence(
        session: session,
        answer: freeText.trim(),
        observation: unmatchedOtherObservation,
      );
      setState(() {
        _starterConfirmed = true;
        _starterNeedsClarification = false;
        _starterLimitedGuidance = true;
        _starterSymptomIds = const [];
        _pendingCloseVerification = null;
        _pendingAnswerPrompt = nextUnmatchedUniversalTemplate(
              templates: package.evidenceTemplates,
              recordedEvidence: widget.dependencies.repairSessionRepository
                  .evidenceForSession(session.id),
            ) ??
            starterFirstTemplate(
              templates: package.evidenceTemplates,
              firstTemplateId: dryerStarterDefaultTemplateId,
            );
      });
      _persistUiResume();
      unawaited(widget.dependencies.flushPersist());
      widget.dependencies.queueEnrichmentRequest(
        EnrichmentRequest(
          key: enrichmentCacheKey(
            applianceId: session.applianceId,
            modelNumber: widget.appliance.modelNumber,
            symptomText: freeText,
          ),
          freeText: freeText.trim(),
          applianceId: session.applianceId,
          modelNumber: widget.appliance.modelNumber,
        ),
      );
      return;
    }

    if (!resolution.hasMatch) {
      setState(() {
        _starterNeedsClarification = true;
      });
      return;
    }

    final answer = buildStarterComplaintAnswer(
      resolution: resolution,
      freeText: describing ? freeText : '',
    );
    _recordStarterEvidence(session: session, answer: answer);

    final recordedAfterStarter =
        widget.dependencies.repairSessionRepository.evidenceForSession(
      session.id,
    );
    final template = resolution.isHazard
        ? null
        : starterInterviewTemplate(
            templates: package.evidenceTemplates,
            recordedEvidence: recordedAfterStarter,
            firstTemplateId: resolution.firstTemplateId,
            starterMatchedSymptomIds: resolution.matchedSymptomIds.toSet(),
            energySource: widget.appliance.energySource,
          );

    setState(() {
      _starterConfirmed = true;
      _starterNeedsClarification = false;
      _starterLimitedGuidance = resolution.unmatchedFreeText;
      _starterSymptomIds = resolution.matchedSymptomIds;
      _pendingCloseVerification = null;
      _pendingAnswerPrompt = template;
    });
    _persistUiResume();
    unawaited(widget.dependencies.flushPersist());
  }

  void _recordStarterEvidence({
    required RepairSession session,
    required String answer,
    String observation = "What's going on with the dryer?",
  }) {
    try {
      widget.dependencies.sessionCoordinator.addEvidence(
        evidence: Evidence(
          id: widget.dependencies.nextId('evidence'),
          sessionId: session.id,
          applianceId: session.applianceId,
          type: EvidenceType.textObservation,
          observation: observation,
          answer: answer,
          templateId: problemStarterComplaintTemplateId,
          collectedAt: widget.dependencies.nextTimestamp(),
          collectedInState: session.currentState,
          source: EvidenceSource.user,
          schemaVersion: session.schemaVersion,
        ),
        evidenceLinkId: widget.dependencies.nextId('evidence-link'),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _selectStarterEntry(String id) {
    setState(() {
      _starterNeedsClarification = false;
      if (_starterSelectedIds.contains(id)) {
        _starterSelectedIds.remove(id);
        _starterMatcherDismissedIds.add(id);
      } else {
        _starterSelectedIds.add(id);
        _starterMatcherDismissedIds.remove(id);
      }
      if (!_starterSelectedIds.contains(dryerStarterOtherDescribeId)) {
        _starterFreeTextController.clear();
      } else {
        _applyStarterKeywordMatcher();
      }
    });
  }

  void _applyStarterKeywordMatcher() {
    final next = applyStarterKeywordMatcher(
      selectedIds: _starterSelectedIds,
      freeText: _starterFreeTextController.text,
      dismissedIds: _starterMatcherDismissedIds,
    );
    _starterSelectedIds
      ..clear()
      ..addAll(next);
  }

  void _clarifyStarterWith(String symptomId) {
    setState(() {
      _starterSelectedIds
        ..clear()
        ..add(symptomId);
      _starterNeedsClarification = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confirmProblemStarter();
      }
    });
  }

  void _skipProblemStarter() {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    final template = package == null
        ? null
        : starterFirstTemplate(
            templates: package.evidenceTemplates,
            firstTemplateId: dryerStarterDefaultTemplateId,
          );
    setState(() {
      _starterConfirmed = true;
      _starterNeedsClarification = false;
      _starterSymptomIds = const [];
      _pendingCloseVerification = null;
      _pendingAnswerPrompt = template;
    });
    _persistUiResume();
    unawaited(widget.dependencies.flushPersist());
  }

  void _beginAnswerPrompt(EvidenceTemplate prompt) {
    if (_currentSafetyStop() != null) {
      return;
    }
    setState(() {
      _pendingCloseVerification = null;
      _pendingAnswerPrompt = prompt;
      _pendingPhotoPath = null;
      _clearRevisionState();
    });
    _persistUiResume();
    unawaited(widget.dependencies.flushPersist());
  }

  void _beginReviseEvidence({
    required Evidence evidence,
    required List<EvidenceTemplate> templates,
  }) {
    if (_currentSafetyStop() != null) {
      return;
    }
    final templateId = evidence.templateId;
    if (templateId == null || !isInterviewObservationEvidence(evidence)) {
      return;
    }
    final template = _templateById(templates, templateId);
    if (template == null) {
      return;
    }
    setState(() {
      _pendingCloseVerification = null;
      _pendingAnswerPrompt = template;
      _revisingTemplateId = templateId;
      _pendingPhotoPath = evidence.localPhotoPath;
    });
    _persistUiResume();
  }

  void _goBackOneQuestion({
    required List<Evidence> evidence,
    required List<EvidenceTemplate> templates,
  }) {
    if (_currentSafetyStop() != null) {
      return;
    }

    final observations = interviewObservationsInOrder(evidence);
    if (observations.isEmpty) {
      return;
    }

    Evidence target;
    if (_revisingTemplateId != null) {
      final index = observations.indexWhere(
        (item) => item.templateId == _revisingTemplateId,
      );
      if (index <= 0) {
        return;
      }
      target = observations[index - 1];
    } else {
      target = observations.last;
    }

    final template = _templateById(templates, target.templateId);
    if (template == null) {
      return;
    }

    setState(() {
      _pendingCloseVerification = null;
      _pendingAnswerPrompt = template;
      _revisingTemplateId = template.id;
    });
    _persistUiResume();
  }

  bool _canGoBackOneQuestion(List<Evidence> evidence) {
    final observations = interviewObservationsInOrder(evidence);
    if (observations.isEmpty) {
      return false;
    }
    if (_revisingTemplateId == null) {
      return true;
    }
    final index = observations.indexWhere(
      (item) => item.templateId == _revisingTemplateId,
    );
    return index > 0;
  }

  void _beginCloseVerification(FailureModeClosePath closePath) {
    if (_currentSafetyStop() != null) {
      return;
    }
    setState(() {
      _pendingAnswerPrompt = null;
      _pendingCloseVerification = closePath;
    });
    _persistUiResume();
  }

  Future<void> _selectAnswerChoice(
    String choice, {
    EvidenceTemplate? forPrompt,
    String? describeNote,
  }) async {
    final closePath = _pendingCloseVerification;
    if (closePath != null) {
      _recordCloseVerification(closePath: closePath, answer: choice);
      return;
    }

    final prompt = forPrompt ?? _pendingAnswerPrompt;
    if (prompt == null) {
      return;
    }

    var answer = choice;
    if (isOtherDescribeEngineId(choice)) {
      final note = describeNote ?? await _askOptionalDescribeNote();
      if (!mounted || note == null) {
        return;
      }
      final trimmed = note.trim();
      answer = recordedOtherDescribeAnswer(note);
      if (trimmed.isNotEmpty) {
        final liveSession =
            widget.dependencies.repairSessionRepository.getSession(
          widget.sessionId,
        );
        widget.dependencies.queueEnrichmentRequest(
          EnrichmentRequest(
            key: enrichmentCacheKey(
              applianceId: liveSession?.applianceId ?? widget.appliance.id,
              modelNumber: widget.appliance.modelNumber,
              symptomText: trimmed,
            ),
            freeText: trimmed,
            applianceId: liveSession?.applianceId,
            modelNumber: widget.appliance.modelNumber,
          ),
        );
      }
    }

    _recordEvidence(prompt: prompt, answer: answer);
  }

  void _saveFreeObservationNote() {
    final note = _freeObservationController.text.trim();
    if (note.isEmpty) {
      return;
    }
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null || _isTerminal(session.currentState)) {
      return;
    }
    if (_currentSafetyStop() != null) {
      return;
    }
    final package = widget.dependencies.packageForSession(widget.sessionId);
    if (package == null) {
      return;
    }
    final evidence = Evidence(
      id: widget.dependencies.nextId('evidence'),
      sessionId: session.id,
      applianceId: session.applianceId,
      type: EvidenceType.textObservation,
      observation: UserFacingCopy.freeObservationTitle,
      answer: note,
      templateId: freeObservationNoteTemplateId,
      collectedAt: widget.dependencies.nextTimestamp(),
      collectedInState: session.currentState,
      source: EvidenceSource.user,
      schemaVersion: session.schemaVersion,
    );
    try {
      widget.dependencies.sessionCoordinator.addEvidence(
        evidence: evidence,
        evidenceLinkId: widget.dependencies.nextId('evidence-link'),
      );
      final recorded =
          widget.dependencies.buildDecisionContext(session.id).evidence;
      setState(() {
        _freeObservationController.clear();
        _freeObservationSuggestions = suggestFreeObservationMarks(
          note: note,
          templates: package.evidenceTemplates,
          recordedEvidence: recorded,
          polarity: inferHeatPathPolarity(
            recordedEvidence: recorded,
            starterMatchedSymptomIds: _starterSymptomIds.toSet(),
          ),
        );
      });
      _persistUiResume();
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _markFreeObservationSuggestion(FreeObservationSuggestion suggestion) {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    if (package == null) {
      return;
    }
    final template = _templateById(
      package.evidenceTemplates,
      suggestion.templateId,
    );
    if (template == null) {
      return;
    }
    final keepCurrent = _pendingAnswerPrompt?.id != template.id;
    _recordEvidence(
      prompt: template,
      answer: suggestion.suggestedAnswer,
      keepCurrentQuestion: keepCurrent,
    );
    setState(() {
      _freeObservationSuggestions = _freeObservationSuggestions
          .where((item) => item.templateId != suggestion.templateId)
          .toList(growable: false);
    });
  }

  Future<void> _captureVoiceAnswer({
    required List<String> choices,
    required void Function(String choice) onChip,
    required void Function(String note) onDescribe,
  }) async {
    if (_voiceCaptureOff || _voiceListening || _currentSafetyStop() != null) {
      return;
    }
    setState(() {
      _voiceListening = true;
    });
    try {
      final capture = await widget.dependencies.voiceAnswer.listen();
      if (!mounted) {
        return;
      }
      if (capture.kind == VoiceAnswerKind.permissionDenied ||
          capture.kind == VoiceAnswerKind.unavailable) {
        setState(() => _voicePermissionDenied = true);
        return;
      }
      if (!capture.hasTranscript) {
        return;
      }
      if (transcriptSuggestsHazard(capture.transcript)) {
        final package = widget.dependencies.packageForSession(widget.sessionId);
        EvidenceTemplate? hazard;
        if (package != null) {
          for (final template in package.evidenceTemplates) {
            if (template.id == 'hazard-observation') {
              hazard = template;
              break;
            }
          }
        }
        if (hazard != null) {
          _recordEvidence(prompt: hazard, answer: 'Yes');
        }
        setState(() {
          _voiceHazardConfirm = true;
          _pendingAnswerPrompt = null;
        });
        _persistUiResume();
        return;
      }
      final match = matchVoiceToAnswerChoice(capture.transcript, choices);
      if (match != null) {
        onChip(match);
        return;
      }
      if (choices.any(isOtherDescribeChoice)) {
        onDescribe(capture.transcript);
      }
    } catch (_) {
      // Permission, missing engine, or STT failure: type instead.
    } finally {
      if (mounted) {
        setState(() {
          _voiceListening = false;
        });
      }
    }
  }

  void _recordCloseVerification({
    required FailureModeClosePath closePath,
    required String answer,
  }) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return;
    }
    if (_isTerminal(session.currentState)) {
      return;
    }
    if (_currentSafetyStop() != null) {
      return;
    }

    final templateId = closeVerificationTemplateId(closePath.failureModeId);
    final recorded =
        widget.dependencies.buildDecisionContext(session.id).evidence;
    final existingAnswer = answerForTemplate(
      recordedEvidence: recorded,
      templateId: templateId,
    );
    final normalizedExisting = normalizeObservationAnswer(existingAnswer);
    final normalizedNew = normalizeObservationAnswer(answer);

    if (normalizedExisting != null && normalizedExisting == normalizedNew) {
      setState(() {
        _pendingCloseVerification = null;
      });
      _persistUiResume();
      return;
    }

    final evidence = Evidence(
      id: widget.dependencies.nextId('evidence'),
      sessionId: session.id,
      applianceId: session.applianceId,
      type: EvidenceType.structuredAnswer,
      observation: closePath.verificationAsk,
      answer: answer,
      templateId: templateId,
      collectedAt: widget.dependencies.nextTimestamp(),
      collectedInState: session.currentState,
      source: EvidenceSource.user,
      schemaVersion: session.schemaVersion,
    );

    try {
      if (existingAnswer != null) {
        widget.dependencies.sessionCoordinator.reviseObservationFromTemplate(
          sessionId: session.id,
          fromTemplateId: templateId,
          replacementEvidence: evidence,
          evidenceLinkId: widget.dependencies.nextId('evidence-link'),
        );
      } else {
        widget.dependencies.sessionCoordinator.addEvidence(
          evidence: evidence,
          evidenceLinkId: widget.dependencies.nextId('evidence-link'),
        );
      }
      setState(() {
        _pendingCloseVerification = null;
        _pendingAnswerPrompt = null;
      });
      _persistUiResume();
      if (answer == 'Not confirmed') {
        _advanceToNextEasierFirstMode(exhaustedId: closePath.failureModeId);
      }
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _advanceToNextEasierFirstMode({required String exhaustedId}) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return;
    }
    DecisionContext context;
    try {
      context = widget.dependencies.buildDecisionContext(session.id);
    } on StateError {
      return;
    }
    final reasoning = _evaluateReasoning(context);
    if (reasoning == null) {
      return;
    }
    _easierPathsExhausted.add(exhaustedId);
    final nextId = easierFirstPursuitId(
      orderedFailureModes: reasoning.orderedFailureModes,
      standings: reasoning.standings,
      rankingLeaderId: reasoning.closePath?.failureModeId,
      exhaustedModeIds: _easierPathsExhausted,
    );
    if (nextId == null || nextId == exhaustedId) {
      _persistUiResume();
      return;
    }
    FailureMode? nextMode;
    for (final mode in reasoning.orderedFailureModes) {
      if (mode.id == nextId) {
        nextMode = mode;
        break;
      }
    }
    if (nextMode == null) {
      _persistUiResume();
      return;
    }
    _selectPrimaryFailureMode(nextMode);
  }

  void _submitInspectChip({
    required InspectStep step,
    required String chip,
    required FailureModeClosePath closePath,
  }) {
    final package = widget.dependencies.packageForSession(widget.sessionId);
    if (package == null) {
      return;
    }
    final template = _templateById(
      package.evidenceTemplates,
      step.evidenceTemplateId,
    );
    final answer = step.answerForChip(chip);
    if (template == null || answer == null) {
      return;
    }
    _recordEvidence(prompt: template, answer: answer);
    if (!_hasIncompleteInspect(closePath)) {
      _goClosePathPhase(
        _phaseAfterInspectComplete(closePath),
        closePath: closePath,
      );
    }
  }

  void _submitInterviewInspectChip({
    required InspectStep step,
    required EvidenceTemplate prompt,
    required String chip,
  }) {
    final answer = step.answerForChip(chip);
    if (answer == null) {
      return;
    }
    _selectAnswerChoice(answer, forPrompt: prompt);
  }

  Future<String?> _askOptionalDescribeNote() {
    if (!identical(_phrasingNotifier.value, _phrasing)) {
      _phrasingNotifier.value = _phrasing;
    }
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _OptionalDescribeNoteDialog(
        phrasing: _phrasingNotifier,
      ),
    );
  }

  void _recordEvidence({
    required EvidenceTemplate prompt,
    required String answer,
    bool keepCurrentQuestion = false,
  }) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return;
    }
    if (_isTerminal(session.currentState)) {
      return;
    }
    if (_currentSafetyStop() != null) {
      return;
    }

    final recorded =
        widget.dependencies.buildDecisionContext(session.id).evidence;
    final existingAnswer = answerForTemplate(
      recordedEvidence: recorded,
      templateId: prompt.id,
    );
    final normalizedExisting = normalizeObservationAnswer(existingAnswer);
    final normalizedNew = normalizeObservationAnswer(answer);
    final isRevising = _revisingTemplateId == prompt.id;

    if (isRevising &&
        normalizedExisting != null &&
        normalizedExisting == normalizedNew) {
      setState(() {
        if (!keepCurrentQuestion) {
          _pendingAnswerPrompt = null;
          _pendingPhotoPath = null;
          _clearRevisionState();
        }
      });
      _persistUiResume();
      return;
    }

    String? existingPhoto;
    for (final item in recorded.reversed) {
      if (item.templateId == prompt.id) {
        existingPhoto = item.localPhotoPath;
        break;
      }
    }

    final evidence = Evidence(
      id: widget.dependencies.nextId('evidence'),
      sessionId: session.id,
      applianceId: session.applianceId,
      type: prompt.expectedEvidenceType,
      observation: observationPromptTitle(prompt),
      answer: answer,
      templateId: prompt.id,
      collectedAt: widget.dependencies.nextTimestamp(),
      collectedInState: session.currentState,
      source: EvidenceSource.user,
      schemaVersion: session.schemaVersion,
      localPhotoPath: keepCurrentQuestion
          ? existingPhoto
          : (_pendingPhotoPath ?? existingPhoto),
    );

    try {
      if (isRevising || existingAnswer != null) {
        widget.dependencies.sessionCoordinator.reviseObservationFromTemplate(
          sessionId: session.id,
          fromTemplateId: prompt.id,
          replacementEvidence: evidence,
          evidenceLinkId: widget.dependencies.nextId('evidence-link'),
        );
      } else {
        widget.dependencies.sessionCoordinator.addEvidence(
          evidence: evidence,
          evidenceLinkId: widget.dependencies.nextId('evidence-link'),
        );
      }
      if (prompt.id == gasDryerTypeTemplateId) {
        widget.dependencies.syncDryerEnergyFromInterview(
          appliance: widget.appliance,
          answer: answer,
        );
      }
      setState(() {
        if (!keepCurrentQuestion) {
          _pendingAnswerPrompt = null;
          _pendingPhotoPath = null;
          _clearRevisionState();
        }
      });
      _persistUiResume();
      unawaited(widget.dependencies.flushPersist());
      if (!keepCurrentQuestion) {
        final nextContext =
            widget.dependencies.buildDecisionContext(session.id);
        final nextReasoning = _evaluateReasoning(nextContext);
        final nextId = nextReasoning?.suggestedNextTemplateId;
        if (nextId != null && nextId != prompt.id) {
          _prefetchAlreadyChosenNext(
            templateId: nextId,
            templates: nextContext.package?.evidenceTemplates ?? const [],
            evidence: nextContext.evidence,
            orderedFailureModes: nextReasoning?.orderedFailureModes ?? const [],
            standings: nextReasoning?.standings ?? const {},
            packageModes: nextContext.package?.failureModes ?? const [],
          );
        }
      }
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  Future<void> _pickEvidencePhoto({
    required EvidencePhotoOrigin origin,
    required bool standalone,
  }) async {
    if (_photoCaptureOff || _currentSafetyStop() != null) {
      return;
    }
    try {
      final path = await widget.dependencies.photoPicker.pick(origin: origin);
      if (!mounted || path == null) {
        return;
      }
      if (standalone) {
        _recordStandalonePhoto(path);
        return;
      }
      setState(() {
        _pendingPhotoPath = path;
      });
    } on PhotoPermissionDeniedException {
      if (!mounted) {
        return;
      }
      setState(() => _photoPermissionDenied = true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _recordStandalonePhoto(String path) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null || _isTerminal(session.currentState)) {
      return;
    }
    if (_currentSafetyStop() != null) {
      return;
    }
    final evidence = Evidence(
      id: widget.dependencies.nextId('evidence'),
      sessionId: session.id,
      applianceId: session.applianceId,
      type: EvidenceType.photo,
      observation: 'Photo',
      answer: 'Attached photo',
      collectedAt: widget.dependencies.nextTimestamp(),
      collectedInState: session.currentState,
      source: EvidenceSource.photo,
      schemaVersion: session.schemaVersion,
      localPhotoPath: path,
    );
    try {
      widget.dependencies.sessionCoordinator.addEvidence(
        evidence: evidence,
        evidenceLinkId: widget.dependencies.nextId('evidence-link'),
      );
      setState(() {});
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  void _selectPrimaryFailureMode(FailureMode failureMode) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return;
    }
    if (_isTerminal(session.currentState)) {
      return;
    }
    if (_currentSafetyStop() != null) {
      return;
    }

    try {
      final existing = widget.dependencies.repairSessionRepository
          .hypothesesForSession(session.id);

      for (final hypothesis in existing) {
        if (hypothesis.failureModeId == failureMode.id) {
          continue;
        }
        if (hypothesis.status == HypothesisStatus.ruledOut) {
          continue;
        }
        widget.dependencies.sessionCoordinator.updateHypothesis(
          hypothesis.copyWith(status: HypothesisStatus.ruledOut),
        );
      }

      Hypothesis? matching;
      for (final hypothesis in existing) {
        if (hypothesis.failureModeId == failureMode.id) {
          matching = hypothesis;
          break;
        }
      }

      if (matching == null) {
        widget.dependencies.sessionCoordinator.attachHypothesis(
          Hypothesis(
            id: widget.dependencies.nextId('hypothesis'),
            sessionId: session.id,
            failureModeId: failureMode.id,
            label: failureMode.label,
            currentConfidence: 0,
            status: HypothesisStatus.confirmed,
            schemaVersion: session.schemaVersion,
          ),
        );
      } else {
        widget.dependencies.sessionCoordinator.updateHypothesis(
          matching.copyWith(status: HypothesisStatus.confirmed),
        );
      }

      setState(() {
        _pendingAnswerPrompt = null;
        _pendingCloseVerification = null;
        _lastShownOpenInterviewTemplateId = null;
        _closePathPhase = ClosePathPhase.conclusion;
        _choseRepair = false;
        _guidanceStepIndex = 0;
        _completedGuidanceStepIds.clear();
        _guidanceCouldNot = false;
      });
      _persistUiResume();
    } on StateError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    }
  }

  Future<void> _closeFromReadiness(SessionCloseKind kind) async {
    try {
      widget.dependencies.endSession(
        sessionId: widget.sessionId,
        closeKind: kind,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(error))),
        );
      }
    }
  }

  void _markReadinessTool(RepairReadinessItem item, bool have) {
    setState(() {
      _readinessHaveByToolId[item.id] = have;
      if (!have) {
        _readinessContinueWithCaution = false;
      }
    });
    _persistUiResume();
  }

  void _saveReadinessToolToInventory(RepairReadinessItem item, bool save) {
    if (save) {
      widget.dependencies.rememberOwnedTool(item.id);
    } else {
      widget.dependencies.forgetOwnedTool(item.id);
    }
    setState(() {});
    unawaited(widget.dependencies.flushPersist());
  }

  void _continueReadinessWithCaution() {
    final closePath = _boundClosePathForCurrentSession();
    setState(() {
      _readinessContinueWithCaution = true;
      _guidanceCouldNot = false;
      if (closePath != null && _hasIncompleteInspect(closePath)) {
        _closePathPhase = ClosePathPhase.inspect;
      } else {
        _closePathPhase = ClosePathPhase.guidance;
        if (closePath != null) {
          _snapGuidanceResume(closePath);
        }
      }
    });
    _persistUiResume();
  }

  DiagnosticReasoningResult? _evaluateReasoning(
    DecisionContext context, {
    bool safetyStopActive = false,
  }) {
    return _reasoning.evaluateContext(
      context,
      safetyStopActive: safetyStopActive,
      energySource: widget.appliance.energySource,
      starterMatchedSymptomIds: _starterSymptomIds.toSet(),
    );
  }

  SafetyStop? _currentSafetyStop() {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null || _isTerminal(session.currentState)) {
      return null;
    }
    try {
      final context = widget.dependencies.buildDecisionContext(session.id);
      return _safety.evaluateContext(context);
    } on StateError {
      return null;
    }
  }

  Future<void> _endSession({
    required CloseResolveEligibility eligibility,
    String? rankingLeaderLabel,
    String? rankingLeaderFailureModeId,
    SessionCloseKind? initialCloseKind,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SessionOutcomeScreen(
          dependencies: widget.dependencies,
          appliance: widget.appliance,
          sessionId: widget.sessionId,
          eligibility: eligibility,
          rankingLeaderLabel: rankingLeaderLabel,
          rankingLeaderFailureModeId: rankingLeaderFailureModeId,
          initialCloseKind: initialCloseKind ??
              (eligibility == CloseResolveEligibility.safetyStop
                  ? SessionCloseKind.calledProfessional
                  : null),
        ),
      ),
    );
    if (saved == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  EvidenceTemplate? _templateById(
    List<EvidenceTemplate> templates,
    String? id,
  ) {
    if (id == null) {
      return null;
    }
    for (final template in templates) {
      if (template.id == id) {
        return template;
      }
    }
    return null;
  }

  Widget _guideUnavailableScaffold() {
    return Scaffold(
      key: const Key('missing-guide-scaffold'),
      appBar: AppBar(title: Text(widget.appliance.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              UserFacingCopy.packageUnavailable,
              key: const Key('prompts-unavailable-message'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              UserFacingCopy.packageInstallHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (_guideInstalling)
              const GuideLoadingIndicator()
            else
              FilledButton(
                key: const Key('package-install-local-button'),
                onPressed: _installMissingGuide,
                child: const Text(UserFacingCopy.installGuide),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('missing-guide-start-fresh'),
              onPressed: _startFreshFromMissingGuide,
              child: const Text(UserFacingCopy.startFresh),
            ),
            Text(
              UserFacingCopy.missingGuideStartFreshHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('missing-guide-ok'),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(UserFacingCopy.ok),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _installMissingGuide() async {
    setState(() => _guideInstalling = true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    widget.dependencies.installBundledPackage(widget.appliance.category);
    if (!mounted) {
      return;
    }
    if (!widget.dependencies.hasInstalledPackageFor(
      widget.appliance.category,
    )) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => PackageManagerScreen(
            dependencies: widget.dependencies,
            preferCategory: widget.appliance.category,
          ),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => _guideInstalling = false);
  }

  void _startFreshFromMissingGuide() {
    widget.dependencies.abandonOpenSession(widget.appliance);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.appliance.name)),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: EmptyHint(
            message: 'This repair session is no longer available.',
          ),
        ),
      );
    }

    final outcome = widget.dependencies.outcomeForSession(session.id);
    final appliance =
        widget.dependencies.applianceRepository.getById(widget.appliance.id) ??
            widget.appliance;
    DecisionContext decisionContext;
    try {
      decisionContext = widget.dependencies.buildDecisionContext(session.id);
    } on StateError {
      if (outcome != null) {
        return _historyMemoryScaffold(outcome);
      }
      return _guideUnavailableScaffold();
    }
    final package = decisionContext.package;
    final usability = assessKnowledgePackage(package);
    if (package == null || usability == PackageUsabilityKind.corrupt) {
      if (outcome != null) {
        return _historyMemoryScaffold(outcome);
      }
      return _guideUnavailableScaffold();
    }
    final prompts = widget.appliance.category == 'washer'
        ? washerLatchInterviewTemplates(
            package.evidenceTemplates,
            widget.appliance.washerLoadStyle,
          )
        : package.evidenceTemplates;
    final sessionObjective = session.sessionObjective;
    final primaryHypothesis = decisionContext.primaryHypothesis;
    final primaryFailureModeId = decisionContext.primaryFailureModeId;
    final reasoning = _evaluateReasoning(decisionContext);
    final standings =
        reasoning?.standings ?? const <String, FailureModeStanding>{};
    final orderedFailureModes =
        reasoning?.orderedFailureModes ?? const <FailureMode>[];
    final clearLeaderId = reasoning?.clearLeaderFailureModeId;
    final recommendPrimaryId = reasoning?.recommendPrimaryFailureModeId;
    final isTerminal = _isTerminal(session.currentState);
    final coverageNotice = dryerCoverageNotice(
      manufacturer: appliance.manufacturer,
      modelNumber: appliance.modelNumber,
      usingGeneralGuide: session.usingGeneralGuide,
      category: package.category,
    );
    final safetyStop =
        isTerminal ? null : _safety.evaluateContext(decisionContext);
    final easierPursuitId = easierFirstPursuitId(
      orderedFailureModes: orderedFailureModes,
      standings: standings,
      rankingLeaderId: reasoning?.closePath?.failureModeId,
      confirmedPrimaryId: primaryFailureModeId,
      exhaustedModeIds: _easierPathsExhausted,
    );
    final easierRankingPath = easierPursuitId == null
        ? reasoning?.closePath
        : (closePathForFailureMode(easierPursuitId) ?? reasoning?.closePath);
    final closePath = safetyStop == null
        ? _closePathBoundToConfirmedPrimary(
            rankingPath: easierRankingPath,
            primaryFailureModeId: primaryFailureModeId,
          )
        : null;
    final rule = stoppingRule(
      safetyStop: safetyStop,
      templates: prompts,
      recordedEvidence: decisionContext.evidence,
      primaryFailureModeId: primaryFailureModeId,
      recommendPrimaryFailureModeId: recommendPrimaryId,
      skipToBestGuess: _skipToBestGuess,
    );
    final investigationStopped = !isTerminal &&
        safetyStop == null &&
        shouldStopInvestigation(
          templates: prompts,
          recordedEvidence: decisionContext.evidence,
          primaryFailureModeId: primaryFailureModeId,
        );
    final isRevisingEvidence = _revisingTemplateId != null;
    final effectiveInvestigationStopped =
        investigationStopped && !isRevisingEvidence;
    final hideNextQuestion = !rule.askAnotherQuestion && !isRevisingEvidence;
    // After I'll repair, verification and End Session follow the bound
    // Primary path — the same path inspect and guidance already use.
    final verificationOutcome = closePath != null
        ? _closePathPolicy.outcomeForPrimary(
            evidence: decisionContext.evidence,
            primaryFailureModeId: closePath.failureModeId,
          )
        : (reasoning?.verificationOutcome ?? VerificationOutcome.notApplicable);
    final resolveEligibility = safetyStop != null
        ? CloseResolveEligibility.safetyStop
        : closePath != null
            ? _closePathPolicy.resolveEligibility(
                safetyStopActive: false,
                primaryFailureModeId: closePath.failureModeId,
                verificationOutcome: verificationOutcome,
                closePath: closePath,
              )
            : (reasoning?.resolveEligibility ??
                CloseResolveEligibility.unresolvedOnly);
    final interactionsLocked = isTerminal || safetyStop != null;
    var suggestedNext = _templateById(
      prompts,
      reasoning?.suggestedNextTemplateId,
    );
    if (suggestedNext != null &&
        !isRevisingEvidence &&
        isTemplateRecorded(
          template: suggestedNext,
          recordedEvidence: decisionContext.evidence,
        )) {
      suggestedNext = null;
    }
    if (_starterLimitedGuidance) {
      suggestedNext = nextUnmatchedUniversalTemplate(
        templates: prompts,
        recordedEvidence: decisionContext.evidence,
      );
    }
    final unmatchedNoMatch = _starterLimitedGuidance &&
        unmatchedUniversalSetComplete(
          templates: prompts,
          recordedEvidence: decisionContext.evidence,
        );
    var pendingForInterview = _pendingAnswerPrompt;
    if (pendingForInterview != null &&
        !isRevisingEvidence &&
        isTemplateRecorded(
          template: pendingForInterview,
          recordedEvidence: decisionContext.evidence,
        )) {
      pendingForInterview = null;
    }
    if (_starterLimitedGuidance &&
        pendingForInterview != null &&
        isRankedHeatOrNoiseInterviewTemplate(pendingForInterview.id)) {
      pendingForInterview = null;
    }
    final showClosePath = effectiveInvestigationStopped &&
        closePath != null &&
        safetyStop == null;
    FailureMode? recommendedPrimary;
    if (!_starterLimitedGuidance &&
        !effectiveInvestigationStopped &&
        safetyStop == null &&
        rule.showDiagnosis) {
      final diagnosisId = recommendPrimaryId ??
          ((hideNextQuestion && orderedFailureModes.isNotEmpty)
              ? orderedFailureModes.first.id
              : null);
      if (diagnosisId != null) {
        for (final mode in package.failureModes) {
          if (mode.id == diagnosisId) {
            recommendedPrimary = mode;
            break;
          }
        }
      }
    }
    final activeObservation =
        hideNextQuestion || safetyStop != null || unmatchedNoMatch
            ? (isRevisingEvidence ? _pendingAnswerPrompt : null)
            : (pendingForInterview ?? suggestedNext);
    if (activeObservation != null) {
      _lastShownOpenInterviewTemplateId = activeObservation.id;
    }
    final alternateObservations = !hideNextQuestion && !_starterLimitedGuidance
        ? unusedTemplates(
            templates: prompts,
            recordedEvidence: decisionContext.evidence,
          ).where((prompt) {
            if (prompt.id == activeObservation?.id) {
              return false;
            }
            return !shouldSuppressObservationForHeatPolarity(
              templateId: prompt.id,
              recordedEvidence: decisionContext.evidence,
              templates: prompts,
            );
          }).toList()
        : !_starterLimitedGuidance
            ? const <EvidenceTemplate>[]
            : unusedTemplates(
                templates: prompts,
                recordedEvidence: decisionContext.evidence,
              ).where((prompt) {
                if (prompt.id == activeObservation?.id) {
                  return false;
                }
                return unmatchedUniversalTemplateIds.contains(prompt.id);
              }).toList();
    final canGoBack = !interactionsLocked &&
        activeObservation != null &&
        _canGoBackOneQuestion(decisionContext.evidence);
    final selectedAnswerForActive = activeObservation == null
        ? null
        : answerForTemplate(
            recordedEvidence: decisionContext.evidence,
            templateId: activeObservation.id,
          );

    final clueCount = interviewObservationsInOrder(
      decisionContext.evidence,
    ).length;
    final offerAlreadyChecked = widget.dependencies
        .repairHistoryForAppliance(widget.appliance.id)
        .isNotEmpty;
    final safetyKind = safetyLightForSession(
      safetyStop: safetyStop != null,
      closePathActive: showClosePath,
      safetyLevel: decisionContext.safetyLevel,
    );
    final priorHint = isTerminal
        ? null
        : priorRootCauseHint(
            history: widget.dependencies.repairHistoryForAppliance(
              widget.appliance.id,
            ),
            excludeSessionId: widget.sessionId,
          );

    GroqPhrasingRequest? phrasingRequest;
    if (safetyStop != null) {
      phrasingRequest = GroqPhrasingRequest(
        hook: GroqPhrasingHook.safetyStop,
        family: widget.appliance.category,
        energy: groqEnergyTokenFromAppliance(widget.appliance),
        state: 'stop',
        comfort: groqComfortToken(_comfortLevel),
        evidenceNeeded: 'safety-stop',
        options: const [],
        lastObs: _lastObsLine(decisionContext.evidence),
        whyEngine: UserFacingCopy.safetyStopOfficial,
        safety: 'stop_unplug',
        packagedTitle: safetyStop.reason,
        packagedWhyOneLine: UserFacingCopy.safetyStopOfficial,
        safetyCritical: true,
      );
    } else if (_showResumeKnew &&
        _resumeKnewLine != null &&
        _phrasingScreenKey == null) {
      phrasingRequest = GroqPhrasingRequest(
        hook: GroqPhrasingHook.resume,
        family: widget.appliance.category,
        energy: groqEnergyTokenFromAppliance(widget.appliance),
        state: 'evidence',
        comfort: groqComfortToken(_comfortLevel),
        evidenceNeeded: 'resume',
        options: const [],
        lastObs: _lastObsLine(decisionContext.evidence),
        whyEngine: _resumeKnewLine!,
        safety: 'none',
        packagedTitle: kResumeKnewLead,
        packagedWhyOneLine: _resumeKnewLine!,
      );
    } else if (showClosePath &&
        verificationOutcome == VerificationOutcome.supported &&
        !closePath.allowResolvedWhenConfirmed) {
      phrasingRequest = GroqPhrasingRequest(
        hook: GroqPhrasingHook.confirmNotFixed,
        family: widget.appliance.category,
        energy: groqEnergyTokenFromAppliance(widget.appliance),
        state: 'verify',
        comfort: groqComfortToken(_comfortLevel),
        evidenceNeeded: closePath.failureModeId,
        options: const [],
        lastObs: _lastObsLine(decisionContext.evidence),
        whyEngine: kConfirmNotFixedPackaged,
        safety: 'none',
        packagedTitle: kConfirmNotFixedPackaged,
        packagedWhyOneLine: kConfirmNotFixedPackaged,
        allowResolvedWhenConfirmed: false,
        offersFixed: false,
      );
    } else if (showClosePath && _closePathPhase == ClosePathPhase.conclusion) {
      phrasingRequest = GroqPhrasingRequest(
        hook: GroqPhrasingHook.diagnosisSummary,
        family: widget.appliance.category,
        energy: groqEnergyTokenFromAppliance(widget.appliance),
        state: 'guidance',
        comfort: groqComfortToken(_comfortLevel),
        evidenceNeeded: primaryFailureModeId ?? 'diagnosis',
        options: const [],
        lastObs: _lastObsLine(decisionContext.evidence),
        whyEngine: primaryHypothesis?.label ?? '',
        safety: 'none',
        packagedTitle: primaryHypothesis?.label ?? 'Most likely',
        packagedWhyOneLine: leaderWhyFromStandings(
              orderedIds: orderedFailureModes.map((mode) => mode.id).toList(),
              orderedLabels:
                  orderedFailureModes.map((mode) => mode.label).toList(),
              standings: standings,
              preferredLabel: primaryHypothesis?.label,
            ) ??
            'Based on your answers — not a certainty or a percentage.',
      );
    } else if (activeObservation != null) {
      final whyEngine = _whyAskBody(
        template: activeObservation,
        inspectStep: _inspectStepForTemplate(activeObservation.id),
        orderedFailureModes: orderedFailureModes,
        standings: standings,
        packageModes: package.failureModes,
      );
      phrasingRequest = _questionPhrasingRequest(
        template: activeObservation,
        whyEngine: whyEngine,
        evidence: decisionContext.evidence,
      );
    }
    if (phrasingRequest != null) {
      _ensurePhrasing(phrasingRequest);
    }
    final phrasingOverlay =
        phrasingRequest == null ? null : _overlayFor(phrasingRequest.screenKey);

    final pinnedStopBanner = safetyStop == null
        ? null
        : _SafetyStopBanner(
            reason: safetyStopDisplayCopy(
              safetyStop,
              groqShortenedOfficial: phrasingOverlay != null &&
                      phrasingOverlay.screenKey.startsWith(
                        'safetyStop|',
                      )
                  ? phrasingOverlay.whyOneLine
                  : null,
            ),
          );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          widget.dependencies.noteLeftRepairSession(widget.sessionId);
        }
      },
      child: Scaffold(
      appBar: SessionChromeBar(
        applianceName: widget.appliance.name,
        safetyKind: safetyKind,
        clueSummary: householdClueSummary(clueCount),
        stateLabel: 'Now: ${_chromeNowLabel(
          session: session,
          safetyStop: safetyStop,
          showClosePath: showClosePath,
        )}',
        onExit: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pinnedStopBanner != null)
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ButlerPageBody(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: pinnedStopBanner,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('session-scroll-view'),
              padding: EdgeInsets.zero,
              child: ButlerPageBody(
                padding: pinnedStopBanner != null
                    ? const EdgeInsets.fromLTRB(20, 4, 20, 32)
                    : const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.dependencies.currentMember != null) ...[
                      Text(
                        'Using as ${widget.dependencies.currentMember!.displayName}',
                        key: const Key('session-current-member'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_showResumeKnew && _resumeKnewLine != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        resumeBannerSpokenLine(
                          packaged: _resumeKnewLine!,
                          overlay: phrasingOverlay,
                        ),
                        key: const Key('resume-knew-banner'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (_resumeFailed) ...[
                      const SizedBox(height: 16),
                      DegradedModeBanner(
                        kind: DegradedModeKind.resumeFailed,
                        onStartFresh: () {
                          widget.dependencies
                              .abandonOpenSession(widget.appliance);
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ],
                    if (!widget.dependencies.isOnline) ...[
                      const SizedBox(height: 16),
                      const DegradedModeBanner(
                        kind: DegradedModeKind.offline,
                        bannerKey: Key('session-offline-banner'),
                      ),
                    ],
                    if (usability == PackageUsabilityKind.thin) ...[
                      const SizedBox(height: 16),
                      const DegradedModeBanner(
                        kind: DegradedModeKind.packageThin,
                        bannerKey: Key('session-thin-package-banner'),
                      ),
                    ],
                    if (_photoCaptureOff) ...[
                      const SizedBox(height: 16),
                      DegradedModeBanner(
                        kind: DegradedModeKind.cameraDenied,
                        onOk: () {},
                        onContinueManually: () {},
                        onStartFresh: _startFreshFromDeniedSensor,
                      ),
                    ],
                    if (_voiceCaptureOff) ...[
                      const SizedBox(height: 16),
                      DegradedModeBanner(
                        kind: DegradedModeKind.micDenied,
                        onOk: () {},
                        onContinueManually: () {},
                        onStartFresh: _startFreshFromDeniedSensor,
                      ),
                    ],
                    if (_voiceHazardConfirm) ...[
                      const SizedBox(height: 16),
                      const ErrorBanner(
                        message: UserFacingCopy.voiceHazardConfirm,
                        messageKey: Key('voice-hazard-confirm-banner'),
                      ),
                    ],
                    if (shouldShowWarrantyHint(appliance)) ...[
                      const SizedBox(height: 16),
                      WarrantyHintCard(appliance: appliance),
                    ],
                    if (priorHint != null) ...[
                      const SizedBox(height: 16),
                      PriorRootCauseHintCard(
                        key: const Key('prior-root-cause-hint'),
                        hint: priorHint,
                      ),
                    ],
                    if (!isTerminal && coverageNotice != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        coverageNotice,
                        key: Key(
                          coverageNotice ==
                                  UserFacingCopy.missingMachinePlateNotice
                              ? 'missing-plate-notice'
                              : 'general-dryer-guide-notice',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (!isTerminal && session.overlayPackageId != null) ...[
                      const SizedBox(height: 12),
                      _OverlayAccessNotesCard(
                        notes: resolveKnowledgePackageForAppliance(
                          repository:
                              widget.dependencies.knowledgePackageRepository,
                          appliance: appliance,
                        ).accessNotes,
                      ),
                    ],
                    if (outcome != null) ...[
                      const SizedBox(height: 16),
                      _sessionOutcomeMemoryCard(
                        outcome: outcome,
                        evidenceCount: decisionContext.evidence.length,
                      ),
                    ],
                    if (safetyStop != null) const SizedBox(height: 8),
                    if (!isTerminal &&
                        effectiveInvestigationStopped &&
                        safetyStop == null) ...[
                      const SizedBox(height: 16),
                      if (_blockingReasonLineFor(
                        closePath: closePath,
                        safetyStop: false,
                      )
                          case final blocking?)
                        _BlockingReasonLine(line: blocking)
                      else
                        _NextActionCue(
                          key: const Key('next-action-cue'),
                          title: _steppedClosePathCueTitle(
                            verificationOutcome: verificationOutcome,
                            resolveEligibility: resolveEligibility,
                          ),
                          detail: _steppedClosePathCueDetail(
                            verificationOutcome: verificationOutcome,
                            resolveEligibility: resolveEligibility,
                          ),
                        ),
                      const SizedBox(height: 12),
                      ..._closePathSteppedContent(
                        closePath: closePath,
                        showClosePath: showClosePath,
                        primaryHypothesis: primaryHypothesis,
                        primaryFailureModeId: primaryFailureModeId,
                        verificationOutcome: verificationOutcome,
                        resolveEligibility: resolveEligibility,
                        orderedFailureModes: orderedFailureModes,
                        standings: standings,
                        decisionContext: decisionContext,
                        sessionObjective: sessionObjective,
                        isTerminal: isTerminal,
                        interactionsLocked: interactionsLocked,
                        rankingLeaderLabel: outcome?.rankingLeaderLabel,
                        phrasingOverlay: phrasingOverlay,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          showClosePath
                              ? 'No more questions for now — we have a most likely '
                                  'cause. Finish this step, then End Session.'
                              : 'No more questions for now — we have a most likely '
                                  'cause. Use End Session below to record what happened.',
                          key: const Key('observation-paused-message'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ] else if (!isTerminal && safetyStop == null) ...[
                      const SizedBox(height: 16),
                      _SessionObjectiveChips(
                        selected: sessionObjective,
                        enabled: !interactionsLocked,
                        onSelected: _setSessionObjective,
                      ),
                      if (!_starterConfirmed &&
                          decisionContext.evidence.isEmpty) ...[
                        const SizedBox(height: 16),
                        const _NextActionCue(
                          key: Key('next-action-cue'),
                          title: 'Next: choose what’s going on',
                          detail:
                              'Pick every observation that fits, or use Other / describe. '
                              'Confirm before questions begin.',
                        ),
                        const SizedBox(height: 12),
                        _ProblemStarterPanel(
                          selectedIds: _starterSelectedIds,
                          needsClarification: _starterNeedsClarification,
                          freeTextController: _starterFreeTextController,
                          onSelectEntry: _selectStarterEntry,
                          onClarify: _clarifyStarterWith,
                          onFreeTextChanged: (_) => setState(() {
                            _starterNeedsClarification = false;
                            _applyStarterKeywordMatcher();
                          }),
                          onConfirm: _confirmProblemStarter,
                          onSkip: _skipProblemStarter,
                        ),
                      ] else ...[
                        if (recommendedPrimary
                            case final FailureMode primary) ...[
                          const SizedBox(height: 16),
                          _NextActionCue(
                            key: const Key('next-action-cue'),
                            title: sessionObjectiveInterviewCueTitle(
                              objective: sessionObjective,
                              hasRecommendedPrimary: true,
                            ),
                            detail: sessionObjectiveInterviewCueDetail(
                              objective: sessionObjective,
                              hasRecommendedPrimary: true,
                              hideNextQuestion: hideNextQuestion,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RecommendedPrimaryCard(
                            failureMode: primary,
                            enabled: !interactionsLocked,
                            hint: sessionObjectiveRecommendedHint(
                                sessionObjective),
                            alternatives: rankedPossibilitiesForDisplay(
                              orderedFailureModes: orderedFailureModes,
                              standings: standings,
                              excludeFailureModeId: primary.id,
                              surface: ConfidenceDisplaySurface.recommendation,
                            ),
                            onAccept: () => _selectPrimaryFailureMode(primary),
                            onCallPro: showEarlyProHandoffOnRecommended(
                                    sessionObjective)
                                ? () => _endSession(
                                      eligibility: resolveEligibility,
                                      rankingLeaderLabel: primary.label,
                                      rankingLeaderFailureModeId: primary.id,
                                      initialCloseKind:
                                          SessionCloseKind.calledProfessional,
                                    )
                                : null,
                          ),
                          if (showPartsCostOnRecommendedPrimary(
                                  sessionObjective) &&
                              _partsEstimatesFor(primary.id).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            PartsCostCard(
                              parts: _partsEstimatesFor(primary.id),
                              diyOutOfScope: partsCostDiyOutOfScope(primary.id),
                              onIllRepair:
                                  showIllRepairOnPartsCard(sessionObjective)
                                      ? () {}
                                      : null,
                              onCallPro: showCallProOnPartsCard(
                                      sessionObjective)
                                  ? () => _endSession(
                                        eligibility: resolveEligibility,
                                        rankingLeaderLabel: primary.label,
                                        rankingLeaderFailureModeId: primary.id,
                                        initialCloseKind:
                                            SessionCloseKind.calledProfessional,
                                      )
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 28),
                        ] else ...[
                          const SizedBox(height: 16),
                          _NextActionCue(
                            key: const Key('next-action-cue'),
                            title: sessionObjectiveInterviewCueTitle(
                              objective: sessionObjective,
                              hasRecommendedPrimary: false,
                            ),
                            detail: sessionObjectiveInterviewCueDetail(
                              objective: sessionObjective,
                              hasRecommendedPrimary: false,
                              hideNextQuestion: hideNextQuestion,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (_starterSymptomIds.isNotEmpty) ...[
                          Text(
                            'Starting from: ${_starterSymptomIds.map((id) => dryerStarterFamilyById(id)?.label ?? id).join(', ')}',
                            key: const Key('starter-confirmed-summary'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_starterLimitedGuidance) ...[
                          Text(
                            UserFacingCopy.unmatchedStarterGuidance,
                            key: const Key('starter-limited-guidance'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            unmatchedNoteEcho(
                              unmatchedOtherNote(decisionContext.evidence),
                            ),
                            key: const Key('unmatched-note-echo'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (unmatchedNoMatch && !interactionsLocked) ...[
                          Text(
                            UserFacingCopy.unmatchedNoMatchTitle,
                            key: const Key('unmatched-no-match-title'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            UserFacingCopy.unmatchedNoMatchBody,
                            key: const Key('unmatched-no-match-body'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          PrimaryCta(
                            key: const Key('unmatched-no-match-call-pro'),
                            label: 'Call a pro',
                            semanticLabel: 'Call a pro',
                            onPressed: () => _endSession(
                              eligibility:
                                  CloseResolveEligibility.needsProfessional,
                              rankingLeaderLabel: null,
                              rankingLeaderFailureModeId: null,
                              initialCloseKind:
                                  SessionCloseKind.calledProfessional,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.dependencies
                            .acceptedEnrichmentNotes(applianceId: appliance.id)
                            .isNotEmpty) ...[
                          Text(
                            widget.dependencies
                                .acceptedEnrichmentNotes(
                                    applianceId: appliance.id)
                                .last
                                .body,
                            key: const Key('household-enrichment-note'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (rule.askAnotherQuestion &&
                            !interactionsLocked &&
                            !_starterLimitedGuidance &&
                            clueCount > 0 &&
                            packageCanDiagnose(package)) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: const Key('skip-to-best-guess'),
                              onPressed: _skipToBestGuessTapped,
                              child: const Text(UserFacingCopy.skipToBestGuess),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (activeObservation != null) ...[
                          Text(
                            isRevisingEvidence
                                ? 'Change previous answer'
                                : recommendedPrimary == null
                                    ? 'Current question'
                                    : 'Optional follow-up question',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final inspectStep = _inspectStepForTemplate(
                                activeObservation.id,
                              );
                              final packagedWhy = _whyAskBody(
                                template: activeObservation,
                                inspectStep: inspectStep,
                                orderedFailureModes: orderedFailureModes,
                                standings: standings,
                                packageModes: package.failureModes,
                              );
                              final questionOverlay = phrasingOverlay != null &&
                                      phrasingOverlay.screenKey.contains(
                                        activeObservation.id,
                                      )
                                  ? phrasingOverlay
                                  : null;
                              // Unmatched Other: packaged observation-only why. Groq
                              // may phrase the echo; it must not rewrite this into a
                              // diagnosis they never gave.
                              final displayedWhy = _starterLimitedGuidance
                                  ? packagedWhy
                                  : (questionOverlay?.whyOneLine ??
                                      packagedWhy);
                              if (inspectStep != null) {
                                return InspectStepCard(
                                  step: inspectStep,
                                  selectedAnswer: selectedAnswerForActive,
                                  cameraStartDenied:
                                      widget.dependencies.simulateMediaDenied,
                                  offerLiveCamera: false,
                                  expertMode: widget.dependencies.expertMode,
                                  offerAlreadyChecked: offerAlreadyChecked,
                                  whyAskBody: displayedWhy,
                                  onChip: (chip) => _submitInterviewInspectChip(
                                    step: inspectStep,
                                    prompt: activeObservation,
                                    chip: chip,
                                  ),
                                );
                              }
                              return _AnswerChoicePanel(
                                prompt: activeObservation,
                                expertMode: widget.dependencies.expertMode,
                                offerAlreadyChecked: offerAlreadyChecked,
                                displayTitle: questionOverlay?.title,
                                optionLabels: questionOverlay?.optionLabels,
                                whyAskBody: displayedWhy,
                                emphasize: recommendedPrimary == null,
                                selectedAnswer: selectedAnswerForActive,
                                isRevising: isRevisingEvidence,
                                photoPath: _pendingPhotoPath,
                                photoEnabled:
                                    !interactionsLocked && !_photoCaptureOff,
                                photoVisible: !_photoCaptureOff,
                                voiceListening: _voiceListening,
                                voiceAvailable: widget
                                        .dependencies.voiceAnswer.isAvailable &&
                                    !_voiceCaptureOff,
                                voiceShowButton: widget
                                        .dependencies.voiceAnswer.isAvailable &&
                                    !_voiceCaptureOff,
                                voiceUnavailableHint: !kIsWeb &&
                                    !widget
                                        .dependencies.voiceAnswer.isAvailable &&
                                    !_voiceCaptureOff,
                                freeNoteController: _freeObservationController,
                                freeNoteEnabled: !interactionsLocked,
                                freeNoteSuggestions:
                                    _freeObservationSuggestions,
                                onSaveFreeNote: _saveFreeObservationNote,
                                onMarkFreeNoteSuggestion:
                                    _markFreeObservationSuggestion,
                                onVoice: () => _captureVoiceAnswer(
                                  choices: answerChoicesFor(
                                    activeObservation,
                                    offerAlreadyChecked: offerAlreadyChecked,
                                  ),
                                  onChip: (choice) => _selectAnswerChoice(
                                    choice,
                                    forPrompt: activeObservation,
                                  ),
                                  onDescribe: (note) => _selectAnswerChoice(
                                    kOtherDescribeChoiceId,
                                    forPrompt: activeObservation,
                                    describeNote: note,
                                  ),
                                ),
                                onPickGallery: () => _pickEvidencePhoto(
                                  origin: EvidencePhotoOrigin.gallery,
                                  standalone: false,
                                ),
                                onPickCamera: () => _pickEvidencePhoto(
                                  origin: EvidencePhotoOrigin.camera,
                                  standalone: false,
                                ),
                                onSelected: (choice) => _selectAnswerChoice(
                                  choice,
                                  forPrompt: activeObservation,
                                ),
                                onBack: canGoBack
                                    ? () => _goBackOneQuestion(
                                          evidence: decisionContext.evidence,
                                          templates: prompts,
                                        )
                                    : null,
                                onCancel: _pendingAnswerPrompt == null &&
                                        !isRevisingEvidence
                                    ? null
                                    : () {
                                        setState(() {
                                          _pendingAnswerPrompt = null;
                                          _pendingPhotoPath = null;
                                          _clearRevisionState();
                                        });
                                        _persistUiResume();
                                      },
                              );
                            },
                          ),
                        ] else if (prompts.isEmpty)
                          const Text(
                            UserFacingCopy.emptyRepairQuestions,
                            key: Key('empty-prompts-message'),
                          )
                        else ...[
                          _NextActionCue(
                            key: const Key('suggested-next-empty'),
                            title: UserFacingCopy.emptyFurtherQuestionsTitle,
                            detail: recommendedPrimary != null
                                ? UserFacingCopy
                                    .emptyFurtherQuestionsWithPrimary
                                : UserFacingCopy
                                    .emptyFurtherQuestionsWithoutPrimary,
                          ),
                        ],
                      ],
                    ],
                    if (!isTerminal && safetyStop != null) ...[
                      const SizedBox(height: 16),
                      const _BlockingReasonLine(line: blockingReasonSafetyLine),
                      const SizedBox(height: 16),
                      _endSessionCta(
                        eligibility: resolveEligibility,
                        orderedFailureModes: orderedFailureModes,
                        primaryFailureModeId: primaryFailureModeId,
                        isTerminal: isTerminal,
                      ),
                    ],
                    if (outcome != null) ...[
                      const SizedBox(height: 16),
                      _NextActionCue(
                        key: const Key('finished-next-action-cue'),
                        title: 'Session finished',
                        detail: switch (outcome.resolutionStatus) {
                          SessionResolutionStatus.resolved =>
                            'Fixed was recorded. Exit to return home.',
                          SessionResolutionStatus.partiallyResolved =>
                            'Needs a professional was recorded. Exit to return home.',
                          SessionResolutionStatus.unresolved =>
                            'Unresolved was recorded. Exit to return home.',
                        },
                      ),
                      const SizedBox(height: 16),
                      HowWeGotHereTile(
                        observations: sessionTimelineObservations(
                          decisionContext.evidence,
                        ),
                        leaderWhy: leaderWhyFromStandings(
                          orderedIds: orderedFailureModes
                              .map((mode) => mode.id)
                              .toList(),
                          orderedLabels: orderedFailureModes
                              .map((mode) => mode.label)
                              .toList(),
                          standings: standings,
                          preferredLabel: outcome.rankingLeaderLabel,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _SessionSecondaryDetails(
                      children: [
                        if (alternateObservations.isNotEmpty &&
                            safetyStop == null &&
                            !isTerminal)
                          _OtherObservationsPicker(
                            prompts: alternateObservations,
                            enabled: !interactionsLocked,
                            photoVisible: !_photoCaptureOff,
                            onSelected: _beginAnswerPrompt,
                            onPickGallery: () => _pickEvidencePhoto(
                              origin: EvidencePhotoOrigin.gallery,
                              standalone: true,
                            ),
                            onPickCamera: () => _pickEvidencePhoto(
                              origin: EvidencePhotoOrigin.camera,
                              standalone: true,
                            ),
                          ),
                        ExpansionTile(
                          key: const Key('evidence-history-tile'),
                          title: Text(
                            UserFacingCopy.cluesListTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          subtitle: Text(
                            decisionContext.evidence.isEmpty
                                ? UserFacingCopy.emptyEvidence
                                : 'Tap an answer to change it',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          children: [
                            if (decisionContext.evidence.isEmpty)
                              const ListTile(
                                title: Text(
                                  UserFacingCopy.emptyEvidence,
                                  key: Key('empty-evidence-message'),
                                ),
                              )
                            else
                              for (final evidenceItem
                                  in decisionContext.evidence.reversed)
                                ListTile(
                                  dense: true,
                                  enabled: !interactionsLocked &&
                                      isInterviewObservationEvidence(
                                          evidenceItem),
                                  leading: Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  title: Text(
                                    evidenceItem.answer == null
                                        ? evidenceItem.observation
                                        : 'Answer: ${evidenceItem.answer}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  subtitle: evidenceItem.answer == null
                                      ? null
                                      : Text(
                                          evidenceItem.observation,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                  trailing: evidenceItem.localPhotoPath ==
                                              null ||
                                          evidenceItem.localPhotoPath!.isEmpty
                                      ? null
                                      : EvidencePhotoThumb(
                                          key: Key(
                                            'evidence-history-photo-${evidenceItem.id}',
                                          ),
                                          path: evidenceItem.localPhotoPath!,
                                        ),
                                  onTap: interactionsLocked ||
                                          !isInterviewObservationEvidence(
                                            evidenceItem,
                                          )
                                      ? null
                                      : () => _beginReviseEvidence(
                                            evidence: evidenceItem,
                                            templates: prompts,
                                          ),
                                ),
                          ],
                        ),
                        if (safetyStop == null && !isTerminal)
                          ExpansionTile(
                            key: const Key('failure-modes-tile'),
                            title: Text(
                              'Browse failure modes',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            subtitle: Text(
                              recommendedPrimary != null
                                  ? 'Optional — a recommendation is already shown above'
                                  : 'Optional — set Primary manually if needed',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            children: [
                              if (package.failureModes.isEmpty)
                                const ListTile(
                                  title: Text(
                                    UserFacingCopy.emptyFailureModes,
                                    key: Key('empty-failure-modes-message'),
                                  ),
                                )
                              else
                                for (final failureMode in orderedFailureModes)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _FailureModeTile(
                                      failureMode: failureMode,
                                      isPrimary: failureMode.id ==
                                          primaryFailureModeId,
                                      standing: standings[failureMode.id] ??
                                          const FailureModeStanding(
                                            supportCount: 0,
                                            excludeCount: 0,
                                          ),
                                      isClearLeader:
                                          clearLeaderId == failureMode.id &&
                                              failureMode.id !=
                                                  primaryFailureModeId,
                                      showStandingChrome: false,
                                      enabled: !interactionsLocked,
                                      onSelected: () =>
                                          _selectPrimaryFailureMode(
                                              failureMode),
                                    ),
                                  ),
                            ],
                          ),
                        ExpansionTile(
                          key: const Key('package-summary-tile'),
                          title: Text(
                            'About this guide',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          children: [_PackageSummaryCard(package: package)],
                        ),
                        ExpansionTile(
                          key: const Key('hypotheses-tile'),
                          title: Text(
                            'Working notes (${decisionContext.currentHypotheses.length})',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          children: [
                            if (decisionContext.currentHypotheses.isEmpty)
                              const ListTile(
                                title: Text(
                                  UserFacingCopy.emptyHypotheses,
                                  key: Key('empty-hypotheses-message'),
                                ),
                              )
                            else
                              for (final hypothesis
                                  in decisionContext.currentHypotheses)
                                ListTile(
                                  key: Key('hypothesis-${hypothesis.id}'),
                                  title: Text(hypothesis.label),
                                  subtitle: Text(
                                    switch (hypothesis.status) {
                                      HypothesisStatus.confirmed => 'Primary',
                                      HypothesisStatus.ruledOut => 'Ruled out',
                                      HypothesisStatus.active =>
                                        'Still possible',
                                    },
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                          ],
                        ),
                        ExpansionTile(
                          key: const Key('decision-context-tile'),
                          title: Text(
                            'Session details',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          subtitle: Text(
                            householdClueSummary(clueCount),
                            key: const Key('context-evidence-count'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          children: [
                            ListTile(
                              key: const Key('decision-context-summary'),
                              title: Text(
                                'State: ${_stateLabel(decisionContext.currentState)}',
                              ),
                              subtitle: Text(
                                _safetyLevelLine(decisionContext.safetyLevel),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (outcome == null &&
                        safetyStop == null &&
                        !effectiveInvestigationStopped)
                      _endSessionCta(
                        eligibility: resolveEligibility,
                        orderedFailureModes: orderedFailureModes,
                        primaryFailureModeId: primaryFailureModeId,
                        isTerminal: isTerminal,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _historyMemoryScaffold(SessionOutcome outcome) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appliance.name)),
      body: ButlerPageBody(
        child: ListView(
          children: [
            _sessionOutcomeMemoryCard(
              outcome: outcome,
              evidenceCount: widget.dependencies.repairSessionRepository
                  .evidenceForSession(outcome.sessionId)
                  .length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionOutcomeMemoryCard({
    required SessionOutcome outcome,
    required int evidenceCount,
  }) {
    return Card(
      key: const Key('session-outcome-summary'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Outcome',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${_outcomeStatusLabel(outcome)}',
              key: const Key('outcome-status'),
            ),
            if (outcome.sessionObjective != null) ...[
              const SizedBox(height: 4),
              Text(
                'Goal: ${sessionObjectiveChipLabel(outcome.sessionObjective!)}',
                key: const Key('session-objective-memory'),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'What failed: ${outcome.immediateCause}',
              key: const Key('outcome-primary-hypothesis'),
            ),
            if (outcome.rootCause != null &&
                outcome.rootCause!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Root cause',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                outcome.rootCause!,
                key: const Key('outcome-root-cause'),
              ),
            ],
            if (outcome.contributingFactors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Contributing factors',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final factor in outcome.contributingFactors)
                Text(
                  '• $factor',
                  key: Key('outcome-contributing-${factor.hashCode}'),
                ),
            ],
            if (outcome.preventiveActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Prevention',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final action in outcome.preventiveActions)
                Text(
                  '• $action',
                  key: Key('outcome-prevention-${action.hashCode}'),
                ),
            ],
            const SizedBox(height: 4),
            Text(
              'Evidence recorded: $evidenceCount',
              key: const Key('outcome-evidence-count'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: RepairLogExportButton(
                sessionId: outcome.sessionId,
                applianceName: widget.appliance.name,
                date: outcome.recordedAt,
                outcome: outcome,
                dependencies: widget.dependencies,
                appliance: widget.appliance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _guidanceCueTitle() {
    final path = _boundClosePathForCurrentSession();
    if (path != null && closePathDiyCannotComplete(path)) {
      if (!_proScopeAcknowledged && _completedGuidanceStepIds.isEmpty) {
        return 'Next: a full fix likely needs a pro';
      }
      final steps = _gatedGuidanceSteps(path);
      final incomplete = firstIncompleteGuidanceIndex(
        steps: steps,
        completedIds: _completedGuidanceStepIds,
      );
      if (steps.isEmpty || incomplete >= steps.length) {
        return 'Next: Pro recommended';
      }
    }
    return 'Next: complete this step';
  }

  String _guidanceCueDetail() {
    final path = _boundClosePathForCurrentSession();
    if (path != null && closePathDiyCannotComplete(path)) {
      if (!_proScopeAcknowledged && _completedGuidanceStepIds.isEmpty) {
        return 'Safe checks help a technician. They are not a full home repair.';
      }
      final steps = _gatedGuidanceSteps(path);
      final incomplete = firstIncompleteGuidanceIndex(
        steps: steps,
        completedIds: _completedGuidanceStepIds,
      );
      if (steps.isEmpty || incomplete >= steps.length) {
        return 'Remaining work is not beginner DIY. Tell a technician what you already checked.';
      }
    }
    return 'Do this step only. Tap I did this to move on, or I couldn’t to stop or call a pro.';
  }

  String _closePathNextActionTitle({
    required VerificationOutcome verificationOutcome,
    required CloseResolveEligibility resolveEligibility,
    required bool answersOpen,
  }) {
    if (verificationOutcome == VerificationOutcome.pending) {
      return answersOpen
          ? 'Next: choose a verification result'
          : 'Next: answer verification';
    }
    return switch (resolveEligibility) {
      CloseResolveEligibility.allowResolved => 'Next: Fixed',
      CloseResolveEligibility.needsProfessional => 'Next: Needs a professional',
      CloseResolveEligibility.unresolvedOnly => 'Next: Unresolved',
      CloseResolveEligibility.pendingVerification =>
        'Next: answer verification',
      CloseResolveEligibility.safetyStop => 'Next: Needs a professional',
    };
  }

  String _closePathNextActionDetail({
    required VerificationOutcome verificationOutcome,
    required CloseResolveEligibility resolveEligibility,
  }) {
    if (verificationOutcome == VerificationOutcome.pending) {
      return 'Follow Safe Guidance, then record Confirmed / Not confirmed.';
    }
    return switch (resolveEligibility) {
      CloseResolveEligibility.allowResolved =>
        'Verification confirmed — resolve the session when ready.',
      CloseResolveEligibility.needsProfessional =>
        'Safe checks did not close this — choose Needs a professional.',
      CloseResolveEligibility.unresolvedOnly =>
        'Choose Unresolved or Needs a professional.',
      CloseResolveEligibility.pendingVerification =>
        'Complete verification first.',
      CloseResolveEligibility.safetyStop =>
        'Stop DIY checks and end as Needs a professional.',
    };
  }

  String _endSessionButtonLabel(CloseResolveEligibility eligibility) {
    return switch (eligibility) {
      CloseResolveEligibility.safetyStop => 'Needs a professional',
      CloseResolveEligibility.allowResolved => 'Fixed',
      CloseResolveEligibility.needsProfessional => 'Needs a professional',
      CloseResolveEligibility.pendingVerification =>
        'End Session (complete verification to resolve)',
      CloseResolveEligibility.unresolvedOnly => 'Unresolved',
    };
  }

  String _outcomeStatusLabel(SessionOutcome outcome) {
    return sessionCloseKindLabel(outcome.closeKind);
  }

  bool _isTerminal(RepairSessionState state) {
    return state == RepairSessionState.sessionClosed ||
        state == RepairSessionState.escalated ||
        state == RepairSessionState.abandoned ||
        state == RepairSessionState.error;
  }

  /// Abandon this session and open a new one (camera/mic Start fresh).
  void _startFreshFromDeniedSensor() {
    final appliance = widget.appliance;
    widget.dependencies.abandonOpenSession(appliance);
    late final String newId;
    try {
      newId = widget.dependencies.startOrResumeSession(appliance);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
      Navigator.of(context).maybePop();
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SessionScreen(
          dependencies: widget.dependencies,
          appliance: appliance,
          sessionId: newId,
        ),
      ),
    );
  }

  /// Visible chrome: close-path / stop take priority over stored
  /// evidenceCollection.
  String _chromeNowLabel({
    required RepairSession session,
    required SafetyStop? safetyStop,
    required bool showClosePath,
  }) {
    if (safetyStop != null) {
      return 'Stopped for safety';
    }
    if (showClosePath) {
      return switch (_closePathPhase) {
        ClosePathPhase.tools => 'Checking tools',
        ClosePathPhase.inspect => 'Matching what you see',
        ClosePathPhase.guidance => 'Following safe steps',
        ClosePathPhase.verification => 'Checking whether it worked',
        ClosePathPhase.parts => 'Reviewing parts',
        ClosePathPhase.decision => 'Choosing repair or a professional',
        ClosePathPhase.opportunistic => 'Optional extras',
        ClosePathPhase.done => 'Ready to finish',
        ClosePathPhase.conclusion => 'Reviewing the likely cause',
      };
    }
    return _plainStateLabel(session.currentState);
  }

  String _plainStateLabel(RepairSessionState state) {
    return switch (state) {
      RepairSessionState.newSession => 'Getting started',
      RepairSessionState.selectAppliance => 'Choosing the appliance',
      RepairSessionState.problemReported => 'Describing the problem',
      RepairSessionState.basicConditionVerification => 'First checks',
      RepairSessionState.evidenceCollection => 'Answering questions',
      RepairSessionState.hypothesisBuilding => 'Narrowing it down',
      RepairSessionState.riskCheck => 'Checking for hazards',
      RepairSessionState.safeGuidance => 'Following safe steps',
      RepairSessionState.verification => 'Checking whether it worked',
      RepairSessionState.rootCauseAnalysis => 'Looking at why it failed',
      RepairSessionState.preventiveRecommendation => 'Preventing a repeat',
      RepairSessionState.sessionClosed => 'Finished',
      RepairSessionState.escalated => 'Handed to a professional',
      RepairSessionState.abandoned => 'Stopped',
      RepairSessionState.error => 'This step couldn’t continue',
    };
  }

  /// End Session action. Wraps at large text scales and keeps one semantic name.
  Widget _endSessionCta({
    required CloseResolveEligibility eligibility,
    required List<FailureMode> orderedFailureModes,
    required String? primaryFailureModeId,
    required bool isTerminal,
    String? closePathFailureModeId,
  }) {
    final leaderId = closePathFailureModeId ??
        primaryFailureModeId ??
        (orderedFailureModes.isEmpty ? null : orderedFailureModes.first.id);
    String? leaderLabel;
    if (leaderId != null) {
      for (final mode in orderedFailureModes) {
        if (mode.id == leaderId) {
          leaderLabel = mode.label;
          break;
        }
      }
    }
    leaderLabel ??=
        orderedFailureModes.isEmpty ? null : orderedFailureModes.first.label;
    return PrimaryCta(
      key: const Key('end-session-button'),
      label: _endSessionButtonLabel(eligibility),
      semanticLabel: 'End Session',
      onPressed: isTerminal
          ? null
          : () => _endSession(
                eligibility: eligibility,
                rankingLeaderLabel: leaderLabel,
                rankingLeaderFailureModeId: leaderId,
              ),
    );
  }

  /// Session details never show the raw placeholder level string.
  String _safetyLevelLine(String safetyLevel) {
    final level = safetyLevel.trim();
    if (level.isEmpty ||
        level.toLowerCase() == 'not evaluated' ||
        level.toLowerCase() == 'unknown') {
      return 'No hazard has been recorded in this session.';
    }
    return 'Safety level: $level';
  }

  String _stateLabel(RepairSessionState state) {
    return switch (state) {
      RepairSessionState.newSession => 'New session',
      RepairSessionState.selectAppliance => 'Select appliance',
      RepairSessionState.problemReported => 'Problem reported',
      RepairSessionState.basicConditionVerification =>
        'Basic condition verification',
      RepairSessionState.evidenceCollection => 'Evidence collection',
      RepairSessionState.hypothesisBuilding => 'Hypothesis building',
      RepairSessionState.riskCheck => 'Risk check',
      RepairSessionState.safeGuidance => 'Safe guidance',
      RepairSessionState.verification => 'Verification',
      RepairSessionState.rootCauseAnalysis => 'Root cause analysis',
      RepairSessionState.preventiveRecommendation =>
        'Preventive recommendation',
      RepairSessionState.sessionClosed => 'Session closed',
      RepairSessionState.escalated => 'Escalated',
      RepairSessionState.abandoned => 'Abandoned',
      RepairSessionState.error => 'Error',
    };
  }

  void _skipOpportunisticMaintenance() {
    setState(() {
      _opportunisticSkippedAll = true;
      _closePathPhase = ClosePathPhase.done;
    });
    _persistUiResume();
  }

  void _acceptOpportunisticMaintenance(String label) {
    if (_opportunisticAcceptedLabels.contains(label)) {
      return;
    }
    setState(() {
      _opportunisticAcceptedLabels.add(label);
    });
    widget.dependencies.addMaintenanceReminder(
      applianceId: widget.appliance.id,
      note: label,
      remindOn: widget.dependencies.nextTimestamp(),
      sessionId: widget.sessionId,
      done: true,
    );
    _persistUiResume();
  }

  List<VisualGuideAnchor> _resolvedVisualGuides(
    FailureModeClosePath closePath,
  ) {
    final session = widget.dependencies.repairSessionRepository
        .getSession(widget.sessionId);
    final appliance = session == null
        ? null
        : widget.dependencies.applianceRepository.getById(
            session.applianceId,
          );
    final overlay = appliance == null
        ? null
        : matchBrandOverlay(
            category: appliance.category,
            manufacturer: appliance.manufacturer,
            modelNumber: appliance.modelNumber,
          );
    return visualGuidesForOverlay(
      guides: visualGuidesForAppliance(
        guides: closePath.visualGuides,
        applianceCategory: appliance?.category,
      ),
      overlay: overlay,
    );
  }

  Widget? _opportunisticMaintenanceCard(FailureModeClosePath closePath) {
    if (_opportunisticSkippedAll) {
      return null;
    }
    final extras = opportunisticMaintenanceItems(
      safeGuidanceSteps: visibleSafeGuidanceSteps(
        closePath,
        expertMode: widget.dependencies.expertMode,
      ),
      visualGuides: _resolvedVisualGuides(closePath),
      failureModeId: closePath.failureModeId,
    );
    if (extras.isEmpty) {
      return null;
    }
    return _OpportunisticMaintenanceCard(
      items: extras,
      acceptedLabels: _opportunisticAcceptedLabels,
      onAccept: _acceptOpportunisticMaintenance,
      onSkipAll: _skipOpportunisticMaintenance,
    );
  }

  String _steppedClosePathCueTitle({
    required VerificationOutcome verificationOutcome,
    required CloseResolveEligibility resolveEligibility,
  }) {
    return switch (_closePathPhase) {
      ClosePathPhase.conclusion => 'Next: review the most likely cause',
      ClosePathPhase.decision => "Next: I'll repair or call a pro",
      ClosePathPhase.parts => 'Next: review parts and cost estimates',
      ClosePathPhase.tools => 'Next: check the tools you have',
      ClosePathPhase.inspect => 'Next: match what you see',
      ClosePathPhase.guidance => _guidanceCueTitle(),
      ClosePathPhase.verification => _closePathNextActionTitle(
          verificationOutcome: verificationOutcome,
          resolveEligibility: resolveEligibility,
          answersOpen: _pendingCloseVerification != null,
        ),
      ClosePathPhase.opportunistic => 'Next: optional extras, then done',
      ClosePathPhase.done => _closePathNextActionTitle(
          verificationOutcome: verificationOutcome,
          resolveEligibility: resolveEligibility,
          answersOpen: false,
        ),
    };
  }

  String _steppedClosePathCueDetail({
    required VerificationOutcome verificationOutcome,
    required CloseResolveEligibility resolveEligibility,
  }) {
    return switch (_closePathPhase) {
      ClosePathPhase.conclusion =>
        'This screen names the most likely cause. Repair steps come after you choose I’ll repair.',
      ClosePathPhase.decision =>
        'Choose I’ll repair to see parts and tools. Call a pro uses the existing handoff.',
      ClosePathPhase.parts =>
        'Estimates only — no payment. Continue when you are ready for the tools list.',
      ClosePathPhase.tools =>
        'Mark I have / I don’t. A missing required tool locks panel and parts steps.',
      ClosePathPhase.inspect =>
        'Look at the part. Choose whether it matches, does not match, or you cannot see it.',
      ClosePathPhase.guidance => _guidanceCueDetail(),
      ClosePathPhase.verification => _closePathNextActionDetail(
          verificationOutcome: verificationOutcome,
          resolveEligibility: resolveEligibility,
        ),
      ClosePathPhase.opportunistic =>
        'Optional while-you’re-there checks. Skip if you want to finish.',
      ClosePathPhase.done => _closePathNextActionDetail(
          verificationOutcome: verificationOutcome,
          resolveEligibility: resolveEligibility,
        ),
    };
  }

  List<Widget> _closePathSteppedContent({
    required FailureModeClosePath? closePath,
    required bool showClosePath,
    required Hypothesis? primaryHypothesis,
    required String? primaryFailureModeId,
    required VerificationOutcome verificationOutcome,
    required CloseResolveEligibility resolveEligibility,
    required List<FailureMode> orderedFailureModes,
    required Map<String, FailureModeStanding> standings,
    required DecisionContext decisionContext,
    required SessionObjective? sessionObjective,
    required bool isTerminal,
    required bool interactionsLocked,
    required String? rankingLeaderLabel,
    GroqPhrasingAccepted? phrasingOverlay,
  }) {
    if (!showClosePath || closePath == null) {
      return [
        if (primaryHypothesis != null)
          _PrimaryHypothesisBanner(
            label: primaryHypothesis.label,
            verificationOutcome: verificationOutcome,
            resolveEligibility: resolveEligibility,
          ),
        const SizedBox(height: 12),
        _CurrentConclusionCard(primaryLabel: primaryHypothesis?.label),
        const SizedBox(height: 12),
        _VerificationStatusCard(
          resolveEligibility: resolveEligibility,
          confirmNotFixedLine: _confirmNotFixedLine(
            closePath: closePath,
            verificationOutcome: verificationOutcome,
            overlay: phrasingOverlay,
          ),
        ),
        const SizedBox(height: 16),
        _endSessionCta(
          eligibility: resolveEligibility,
          orderedFailureModes: orderedFailureModes,
          primaryFailureModeId: primaryFailureModeId,
          isTerminal: isTerminal,
        ),
      ];
    }

    final hasParts = _partsEstimatesFor(primaryFailureModeId).isNotEmpty;
    final items = _readinessItemsFor(closePath.failureModeId);
    final hasTools = items.isNotEmpty;
    final haveByToolId = _haveByToolId(items);
    final missing = missingRequiredTools(
      items: items,
      haveByToolId: haveByToolId,
    );
    final steps = _gatedGuidanceSteps(closePath);
    var stepIndex = _guidanceStepIndex;
    if (steps.isNotEmpty) {
      stepIndex = stepIndex.clamp(0, steps.length - 1);
      final incomplete = firstIncompleteGuidanceIndex(
        steps: steps,
        completedIds: _completedGuidanceStepIds,
      );
      if (_closePathPhase == ClosePathPhase.guidance &&
          incomplete < steps.length) {
        stepIndex = incomplete;
      }
    }

    Widget backButton(ClosePathPhase to) {
      return TextButton(
        key: const Key('close-path-back'),
        onPressed: () => _goClosePathPhase(to, closePath: closePath),
        child: const Text('Back'),
      );
    }

    switch (_closePathPhase) {
      case ClosePathPhase.conclusion:
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-conclusion'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BookSectionLabel('Most likely'),
                const SizedBox(height: 8),
                _SpeakHumanCard(
                  diagnosis: applySpeakHumanOverlay(
                    packaged: packagedSpeakHuman(
                      primaryLabel: primaryHypothesis?.label,
                      why: leaderWhyFromStandings(
                        orderedIds:
                            orderedFailureModes.map((mode) => mode.id).toList(),
                        orderedLabels: orderedFailureModes
                            .map((mode) => mode.label)
                            .toList(),
                        standings: standings,
                        preferredLabel: primaryHypothesis?.label,
                      ),
                      observations: sessionTimelineObservations(
                        decisionContext.evidence,
                      ),
                      nextStep: _closePathNextActionDetail(
                        verificationOutcome: verificationOutcome,
                        resolveEligibility: resolveEligibility,
                      ),
                      confidenceBand: () {
                        final id = primaryHypothesis?.failureModeId;
                        if (id == null) {
                          return null;
                        }
                        final standing = standings[id];
                        if (standing == null) {
                          return null;
                        }
                        return householdStandingPhrase(
                          standing: standing,
                          surface: ConfidenceDisplaySurface.diagnosisSummary,
                        );
                      }(),
                    ),
                    overlay: phrasingOverlay != null &&
                            phrasingOverlay.screenKey.startsWith(
                              'diagnosisSummary|',
                            )
                        ? phrasingOverlay
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                if (_confirmNotFixedLine(
                  closePath: closePath,
                  verificationOutcome: verificationOutcome,
                  overlay: phrasingOverlay,
                )
                    case final confirmLine?) ...[
                  Text(
                    confirmLine,
                    key: const Key('confirm-not-fixed-line'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                if (primaryHypothesis != null)
                  _PrimaryHypothesisBanner(
                    label: primaryHypothesis.label,
                    verificationOutcome: verificationOutcome,
                    resolveEligibility: resolveEligibility,
                  ),
                const SizedBox(height: 12),
                _CurrentConclusionCard(
                  primaryLabel: primaryHypothesis?.label,
                ),
                if (closePathDiyCannotComplete(closePath)) ...[
                  const SizedBox(height: 12),
                  _ProScopeNoticeLine(),
                ],
                if (shouldShowBrickRiskWarning(closePath)) ...[
                  const SizedBox(height: 12),
                  const _BrickRiskWarningBanner(),
                ],
                const SizedBox(height: 16),
                const BookSectionLabel('Why'),
                const SizedBox(height: 8),
                if (primaryFailureModeId != null)
                  _RootCauseInsightCard(failureModeId: primaryFailureModeId),
                if (easierFirstDualFaultActive(
                  orderedFailureModes: orderedFailureModes,
                  standings: standings,
                  exhaustedModeIds: _easierPathsExhausted,
                )) ...[
                  const SizedBox(height: 12),
                  Text(
                    _easierPathsExhausted.isEmpty
                        ? easierFirstNotice
                        : easierFirstContinueNotice,
                    key: const Key('easier-first-notice'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                _RemainingLikelyModesCard(
                  orderedFailureModes: orderedFailureModes,
                  standings: standings,
                  excludedFailureModeId: primaryFailureModeId,
                ),
                const SizedBox(height: 16),
                HowWeGotHereTile(
                  observations: sessionTimelineObservations(
                    decisionContext.evidence,
                  ),
                  leaderWhy: leaderWhyFromStandings(
                    orderedIds:
                        orderedFailureModes.map((mode) => mode.id).toList(),
                    orderedLabels:
                        orderedFailureModes.map((mode) => mode.label).toList(),
                    standings: standings,
                    preferredLabel: rankingLeaderLabel,
                  ),
                ),
                const SizedBox(height: 16),
                if (_inspectStepsFor(closePath).isNotEmpty) ...[
                  OutlinedButton(
                    key: const Key('close-path-show-inspect'),
                    onPressed: () => _goClosePathPhase(
                      ClosePathPhase.inspect,
                      closePath: closePath,
                      inspectReviewOnly: true,
                    ),
                    child: const Text(UserFacingCopy.inspectShowMeWhatToCheck),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  key: const Key('close-path-continue'),
                  onPressed: () => _goClosePathPhase(
                    phaseAfterConclusion(
                      objective: sessionObjective,
                      hasParts: hasParts,
                      hasTools: hasTools,
                      hasIncompleteInspect: _hasIncompleteInspect(closePath),
                    ),
                    closePath: closePath,
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ];
      case ClosePathPhase.decision:
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-decision'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How do you want to handle this?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  primaryHypothesis?.label ?? 'Most likely cause',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (showIllRepairOnPartsCard(sessionObjective))
                  FilledButton(
                    key: const Key('close-path-ill-repair'),
                    onPressed: () {
                      final next = phaseAfterRepairChoice(
                        objective: sessionObjective,
                        hasParts: hasParts,
                        hasTools: hasTools,
                        hasIncompleteInspect: _hasIncompleteInspect(closePath),
                      );
                      setState(() {
                        _choseRepair = true;
                        _closePathPhase = next;
                      });
                      _persistUiResume();
                    },
                    child: const Text("I'll repair"),
                  ),
                if (showIllRepairOnPartsCard(sessionObjective) &&
                    showCallProOnPartsCard(sessionObjective))
                  const SizedBox(height: 8),
                if (showCallProOnPartsCard(sessionObjective))
                  FilledButton.tonal(
                    key: const Key('close-path-call-pro'),
                    onPressed: () => _endSession(
                      eligibility: resolveEligibility,
                      rankingLeaderLabel: primaryHypothesis?.label,
                      rankingLeaderFailureModeId: primaryFailureModeId,
                      initialCloseKind: SessionCloseKind.calledProfessional,
                    ),
                    child: const Text('Call a pro'),
                  ),
                const SizedBox(height: 8),
                backButton(
                  _inspectStepsFor(closePath).isNotEmpty
                      ? ClosePathPhase.inspect
                      : ClosePathPhase.conclusion,
                ),
              ],
            ),
          ),
        ];
      case ClosePathPhase.parts:
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-parts'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PartsCostCard(
                  parts: _partsEstimatesFor(primaryFailureModeId),
                  diyOutOfScope: partsCostDiyOutOfScope(primaryFailureModeId),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('close-path-parts-continue'),
                  onPressed: () => _goClosePathPhase(
                    phaseAfterParts(
                      hasTools: hasTools,
                      hasIncompleteInspect: _hasIncompleteInspect(closePath),
                    ),
                    closePath: closePath,
                  ),
                  child: const Text('Continue'),
                ),
                backButton(ClosePathPhase.decision),
              ],
            ),
          ),
        ];
      case ClosePathPhase.tools:
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-tools'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RepairReadinessCard(
                  items: items,
                  haveByToolId: haveByToolId,
                  ownedToolIds:
                      widget.dependencies.currentHousehold?.ownedToolIds ??
                          const [],
                  onMark: _markReadinessTool,
                  onSaveToInventory: _saveReadinessToolToInventory,
                ),
                if (toolsChecklistComplete(
                      items: items,
                      haveByToolId: haveByToolId,
                    ) &&
                    missing.isNotEmpty &&
                    !_readinessContinueWithCaution) ...[
                  const SizedBox(height: 12),
                  _MissingCriticalToolPanel(
                    missing: missing,
                    allowCaution: allowContinueWithCaution(missing),
                    onStop: () => _closeFromReadiness(SessionCloseKind.stopped),
                    onCallPro: () => _closeFromReadiness(
                      SessionCloseKind.calledProfessional,
                    ),
                    onContinueCaution: _continueReadinessWithCaution,
                  ),
                ],
                if (toolsChecklistComplete(
                      items: items,
                      haveByToolId: haveByToolId,
                    ) &&
                    missing.isEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('close-path-tools-continue'),
                    onPressed: () => _maybeAdvanceFromTools(closePath),
                    child: const Text('Continue'),
                  ),
                ],
                const SizedBox(height: 8),
                backButton(
                  closePathShowsParts(
                    objective: sessionObjective,
                    hasParts: hasParts,
                  )
                      ? ClosePathPhase.parts
                      : closePathShowsDecision(sessionObjective)
                          ? ClosePathPhase.decision
                          : ClosePathPhase.conclusion,
                ),
              ],
            ),
          ),
        ];
      case ClosePathPhase.inspect:
        final inspectSteps = _inspectStepsFor(closePath);
        if (_inspectReviewOnly) {
          final rows = inspectReviewRows(
            steps: inspectSteps,
            recordedEvidence: decisionContext.evidence,
          );
          return [
            KeyedSubtree(
              key: const Key('close-path-phase-inspect'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    UserFacingCopy.inspectShowMeWhatToCheck,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UserFacingCopy.inspectReviewIntro,
                    key: const Key('inspect-review-intro'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final row in rows) ...[
                    Card(
                      key: Key('inspect-review-${row.step.id}'),
                      child: ListTile(
                        title: Text(row.step.title),
                        subtitle: Text(inspectReviewAnswerLabel(row)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    key: const Key('inspect-review-back'),
                    onPressed: () => _goClosePathPhase(
                      ClosePathPhase.conclusion,
                      closePath: closePath,
                    ),
                    child: const Text('Back to most likely'),
                  ),
                  const SizedBox(height: 8),
                  backButton(ClosePathPhase.conclusion),
                ],
              ),
            ),
          ];
        }
        final inspectProgressValues = inspectProgress(
          steps: inspectSteps,
          recordedEvidence: decisionContext.evidence,
        );
        final inspectStep = firstIncompleteInspectStep(
          steps: inspectSteps,
          recordedEvidence: decisionContext.evidence,
        );
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-inspect'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inspectStep != null)
                  InspectStepCard(
                    step: inspectStep,
                    progressCurrent: inspectProgressValues.current,
                    progressTotal: inspectProgressValues.total,
                    selectedAnswer: answerForTemplate(
                      recordedEvidence: decisionContext.evidence,
                      templateId: inspectStep.evidenceTemplateId,
                    ),
                    cameraStartDenied: widget.dependencies.simulateMediaDenied,
                    offerLiveCamera: false,
                    expertMode: widget.dependencies.expertMode,
                    offerAlreadyChecked: widget.dependencies
                        .repairHistoryForAppliance(widget.appliance.id)
                        .isNotEmpty,
                    whyAskBody: _whyAskBody(
                      template: _templateById(
                        decisionContext.package?.evidenceTemplates ?? const [],
                        inspectStep.evidenceTemplateId,
                      ),
                      inspectStep: inspectStep,
                      orderedFailureModes: orderedFailureModes,
                      standings: standings,
                      packageModes:
                          decisionContext.package?.failureModes ?? const [],
                    ),
                    onChip: (chip) => _submitInspectChip(
                      step: inspectStep,
                      chip: chip,
                      closePath: closePath,
                    ),
                  )
                else
                  FilledButton(
                    key: const Key('inspect-continue-guidance'),
                    onPressed: () => _goClosePathPhase(
                      _phaseAfterInspectComplete(closePath),
                      closePath: closePath,
                    ),
                    child: const Text('Continue'),
                  ),
                const SizedBox(height: 8),
                backButton(
                  _choseRepair && closePathShowsDecision(sessionObjective)
                      ? ClosePathPhase.decision
                      : ClosePathPhase.conclusion,
                ),
              ],
            ),
          ),
        ];
      case ClosePathPhase.guidance:
        final diyPro = closePathDiyCannotComplete(closePath);
        final incompleteIndex = firstIncompleteGuidanceIndex(
          steps: steps,
          completedIds: _completedGuidanceStepIds,
        );
        final safeChecksDone = steps.isEmpty || incompleteIndex >= steps.length;
        final showProWarning = diyPro &&
            !_proScopeAcknowledged &&
            _completedGuidanceStepIds.isEmpty;
        final showProHandoff = diyPro && !showProWarning && safeChecksDone;
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-guidance'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_readinessContinueWithCaution &&
                    missing.isNotEmpty &&
                    _blockingReasonLineFor(
                          closePath: closePath,
                          safetyStop: false,
                        ) ==
                        null) ...[
                  _ReadinessCautionBanner(missing: missing),
                  const SizedBox(height: 12),
                ],
                if (shouldShowBrickRiskWarning(closePath)) ...[
                  const _BrickRiskWarningBanner(),
                  const SizedBox(height: 12),
                ],
                if (showProWarning)
                  _ProScopeWarningCard(
                    onDoSafeChecks: () {
                      setState(() => _proScopeAcknowledged = true);
                      _persistUiResume();
                    },
                    onEndSession: () => _endAsProfessional(
                      rankingLeaderLabel: rankingLeaderLabel,
                      rankingLeaderFailureModeId: primaryFailureModeId,
                    ),
                  )
                else if (showProHandoff)
                  _ProRecommendedCard(
                    why: proHandoffWhy(closePath),
                    observations: sessionTimelineObservations(
                      decisionContext.evidence,
                    ),
                    tellTechnician: proHandoffTellTechnician(closePath),
                    checksDone: [
                      for (var i = 0; i < steps.length; i++)
                        if (_completedGuidanceStepIds.contains(
                          guidanceStepId(i, steps[i]),
                        ))
                          guidanceForSafeStep(steps[i]).what,
                    ],
                    onUnderstand: () => _endAsProfessional(
                      rankingLeaderLabel: rankingLeaderLabel,
                      rankingLeaderFailureModeId: primaryFailureModeId,
                    ),
                    onCouldNot: () {
                      setState(() => _guidanceCouldNot = true);
                    },
                  )
                else if (steps.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Continue when you are ready to record how this check went.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const Key('close-path-continue'),
                            onPressed: () => _enterVerification(closePath),
                            child: const Text('Continue to verification'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _SafeGuidanceCard(
                    steps: steps,
                    stepIndex: stepIndex,
                    expertMode: widget.dependencies.expertMode,
                    comfort: widget.dependencies.repairComfort.levelFor(
                      widget.appliance.category,
                    ),
                    onDidThis: () => _guidanceDidThis(closePath),
                    onAlreadyChecked: () => _guidanceDidThis(closePath),
                    onCouldNot: () {
                      final current = steps.isEmpty
                          ? ''
                          : steps[stepIndex.clamp(0, steps.length - 1)];
                      if (isEasyCheckGuidanceStep(current)) {
                        _guidanceDidThis(closePath);
                        return;
                      }
                      setState(() => _guidanceCouldNot = true);
                    },
                    onBack: () => _guidanceBack(closePath),
                  ),
                if (_guidanceCouldNot) ...[
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('guidance-could-not-panel'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Could not complete this step',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Stop here, or call a professional. Do not skip '
                            'into panel or parts work if this step is blocked.',
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            key: const Key('guidance-could-not-stop'),
                            onPressed: () => _closeFromReadiness(
                              SessionCloseKind.stopped,
                            ),
                            child: const Text('Stop'),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            key: const Key('guidance-could-not-call-pro'),
                            onPressed: () => _closeFromReadiness(
                              SessionCloseKind.calledProfessional,
                            ),
                            child: const Text('Call a professional'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ];
      case ClosePathPhase.verification:
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-verification'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CloseVerificationCard(
                  closePath: closePath,
                  outcome: verificationOutcome,
                  enabled: !interactionsLocked,
                  expertMode: widget.dependencies.expertMode,
                  answersVisible: _pendingCloseVerification != null,
                  onAnswer: _beginCloseVerification,
                  onChangeAnswer:
                      verificationOutcome != VerificationOutcome.pending &&
                              !interactionsLocked
                          ? () => _beginCloseVerification(closePath)
                          : null,
                ),
                if (_pendingCloseVerification != null &&
                    !interactionsLocked) ...[
                  const SizedBox(height: 12),
                  _CloseAnswerChoicePanel(
                    ask: _pendingCloseVerification!.verificationAsk,
                    selectedAnswer: answerForTemplate(
                      recordedEvidence: decisionContext.evidence,
                      templateId: closeVerificationTemplateId(
                        _pendingCloseVerification!.failureModeId,
                      ),
                    ),
                    voiceListening: _voiceListening,
                    voiceAvailable:
                        widget.dependencies.voiceAnswer.isAvailable &&
                            !_voiceCaptureOff,
                    voiceShowButton:
                        widget.dependencies.voiceAnswer.isAvailable &&
                            !_voiceCaptureOff,
                    onVoice: () => _captureVoiceAnswer(
                      choices: closeVerificationChoices,
                      onChip: _selectAnswerChoice,
                      onDescribe: (_) {},
                    ),
                    onSelected: _selectAnswerChoice,
                    onBack: verificationOutcome != VerificationOutcome.pending
                        ? () {
                            setState(() {
                              _pendingCloseVerification = null;
                            });
                            _persistUiResume();
                          }
                        : null,
                    onCancel: () {
                      setState(() {
                        _pendingCloseVerification = null;
                      });
                      _persistUiResume();
                    },
                  ),
                ],
                if (verificationOutcome != VerificationOutcome.pending) ...[
                  const SizedBox(height: 12),
                  const _NextActionCue(
                    key: Key('resolve-next-hint'),
                    title: 'Next: End Session',
                    detail:
                        'Use the button below to record the session outcome.',
                  ),
                  const SizedBox(height: 16),
                  _endSessionCta(
                    eligibility: resolveEligibility,
                    orderedFailureModes: orderedFailureModes,
                    primaryFailureModeId: primaryFailureModeId,
                    closePathFailureModeId: closePath.failureModeId,
                    isTerminal: isTerminal,
                  ),
                  if (_opportunisticMaintenanceCard(closePath) != null) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      key: const Key('close-path-continue'),
                      onPressed: () =>
                          _goClosePathPhase(ClosePathPhase.opportunistic),
                      child: const Text('While you\'re there'),
                    ),
                  ],
                ],
                TextButton(
                  key: const Key('close-path-back'),
                  onPressed: () {
                    setState(() {
                      _closePathPhase = ClosePathPhase.guidance;
                      _pendingCloseVerification = null;
                    });
                    _persistUiResume();
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ];
      case ClosePathPhase.opportunistic:
        final opportunistic = _opportunisticMaintenanceCard(closePath);
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-opportunistic'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (opportunistic != null) opportunistic,
                const SizedBox(height: 16),
                _endSessionCta(
                  eligibility: resolveEligibility,
                  orderedFailureModes: orderedFailureModes,
                  primaryFailureModeId: primaryFailureModeId,
                  closePathFailureModeId: closePath.failureModeId,
                  isTerminal: isTerminal,
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  key: const Key('close-path-continue'),
                  onPressed: () => _goClosePathPhase(ClosePathPhase.done),
                  child: const Text('Done'),
                ),
                backButton(ClosePathPhase.verification),
              ],
            ),
          ),
        ];
      case ClosePathPhase.done:
        return [
          KeyedSubtree(
            key: const Key('close-path-phase-done'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (verificationOutcome != VerificationOutcome.pending)
                  const _NextActionCue(
                    key: Key('resolve-next-hint'),
                    title: 'Next: End Session',
                    detail:
                        'Use the button below to record the session outcome.',
                  ),
                const SizedBox(height: 16),
                _endSessionCta(
                  eligibility: resolveEligibility,
                  orderedFailureModes: orderedFailureModes,
                  primaryFailureModeId: primaryFailureModeId,
                  closePathFailureModeId: closePath.failureModeId,
                  isTerminal: isTerminal,
                ),
              ],
            ),
          ),
        ];
    }
  }
}

class _SessionObjectiveChips extends StatelessWidget {
  const _SessionObjectiveChips({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final SessionObjective? selected;
  final bool enabled;
  final ValueChanged<SessionObjective> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('session-objective-chips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UserFacingCopy.sessionObjectivePrompt,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final objective in SessionObjective.values)
              FilterChip(
                key: Key('session-objective-chip-${objective.name}'),
                label: Text(sessionObjectiveChipLabel(objective)),
                selected: selected == objective,
                onSelected: enabled ? (_) => onSelected(objective) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _OverlayAccessNotesCard extends StatelessWidget {
  const _OverlayAccessNotesCard({required this.notes});

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      key: const Key('model-overlay-access-notes'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model-family notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final note in notes) ...[
              Text('• $note'),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProblemStarterPanel extends StatelessWidget {
  const _ProblemStarterPanel({
    required this.selectedIds,
    required this.needsClarification,
    required this.freeTextController,
    required this.onSelectEntry,
    required this.onClarify,
    required this.onFreeTextChanged,
    required this.onConfirm,
    required this.onSkip,
  });

  final Set<String> selectedIds;
  final bool needsClarification;
  final TextEditingController freeTextController;
  final ValueChanged<String> onSelectEntry;
  final ValueChanged<String> onClarify;
  final ValueChanged<String> onFreeTextChanged;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final describing = selectedIds.contains(dryerStarterOtherDescribeId);
    final chipIds = {
      for (final id in selectedIds)
        if (id != dryerStarterOtherDescribeId) id,
    };
    var resolution = resolveDryerStarter(
      selectedSymptomIds: chipIds,
      freeText: describing ? freeTextController.text : '',
    );
    if (describing) {
      resolution = resolutionWithoutHeatNoiseUnlessChecked(
        resolution: resolution,
        selectedSymptomIds: chipIds,
      );
    }
    final canConfirm = selectedIds.isNotEmpty &&
        !needsClarification &&
        (describing
            ? (freeTextController.text.trim().isNotEmpty || chipIds.isNotEmpty)
            : true);

    return Card(
      key: const Key('problem-starter-panel'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "What's going on?",
              key: const Key('problem-starter-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              UserFacingCopy.problemStarterHelper,
              key: const Key('problem-starter-helper'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Select every observation that fits. You can pick more than one.',
              key: const Key('problem-starter-multiselect-hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final id in dryerStarterEntryChoiceIds) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: Key('starter-chip-$id'),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                      color: selectedIds.contains(id)
                          ? scheme.primary
                          : scheme.outline,
                      width: selectedIds.contains(id) ? 1.5 : 1,
                    ),
                    backgroundColor: selectedIds.contains(id)
                        ? scheme.primaryContainer.withValues(alpha: 0.55)
                        : null,
                  ),
                  onPressed: () => onSelectEntry(id),
                  child: Row(
                    children: [
                      Icon(
                        selectedIds.contains(id)
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(dryerStarterEntryChipLabel(id))),
                    ],
                  ),
                ),
              ),
            ],
            if (describing) ...[
              const SizedBox(height: 8),
              Text(
                UserFacingCopy.problemStarterHelper,
                key: const Key('problem-starter-describe-helper'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('problem-starter-freetext'),
                controller: freeTextController,
                onChanged: onFreeTextChanged,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                  hintText: 'e.g. no heat, too hot, won’t start',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
            ],
            if (needsClarification) ...[
              DecoratedBox(
                key: const Key('problem-starter-clarification'),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'No keyword match — pick the closest observation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Free text does not pick a cause. Choose one path below.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      for (final id in dryerStarterClarifyChoiceIds)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            key: Key('starter-clarify-$id'),
                            onPressed: () => onClarify(id),
                            child: Text(dryerStarterEntryChipLabel(id)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (resolution.hasMatch) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observations selected',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resolution.labels.join(' · '),
                        key: const Key('problem-starter-interpretation'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resolution.isHazard
                            ? 'This will stop DIY checks and direct you to a professional.'
                            : 'Confirm to record this complaint and open the first relevant question.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else if (describing &&
                freeTextController.text.trim().isNotEmpty) ...[
              Text(
                'We’ll use what you typed; specific guidance may be limited. '
                'Confirm to continue, or pick the closest observation below '
                'if you want a tighter match.',
                key: const Key('problem-starter-no-match'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
            ],
            if (!needsClarification)
              PrimaryCta(
                key: const Key('problem-starter-confirm'),
                onPressed: canConfirm ? onConfirm : null,
                semanticLabel: PrimaryCtaSemantics.continueAction,
                label: describing &&
                        !resolution.hasMatch &&
                        freeTextController.text.trim().isNotEmpty
                    ? 'Confirm with what I typed'
                    : resolution.isHazard
                        ? 'Confirm — stop and get help'
                        : 'Confirm and continue',
              ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('problem-starter-skip'),
              onPressed: onSkip,
              child: const Text('Skip — start general interview'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet dump for history / notes / guide. Tiles stay default-collapsed
/// so the primary path is current question, Why ask this?, chips.
class _SessionSecondaryDetails extends StatelessWidget {
  const _SessionSecondaryDetails({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('session-secondary-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More about this session',
                style: text.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Evidence, notes, and this guide',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _BlockingReasonLine extends StatelessWidget {
  const _BlockingReasonLine({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('blocking-reason-line'),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Text(
          line,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _NextActionCue extends StatelessWidget {
  const _NextActionCue({
    super.key,
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedPrimaryCard extends StatelessWidget {
  const _RecommendedPrimaryCard({
    required this.failureMode,
    required this.enabled,
    required this.onAccept,
    this.hint,
    this.onCallPro,
    this.alternatives = const [],
  });

  final FailureMode failureMode;
  final bool enabled;
  final VoidCallback onAccept;
  final String? hint;
  final VoidCallback? onCallPro;
  final List<RankedPossibility> alternatives;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('recommended-primary-card'),
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              UserFacingCopy.bestMatchSoFar,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              failureMode.label,
              key: Key('recommended-primary-label-${failureMode.id}'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              failureMode.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              hint ?? UserFacingCopy.bestMatchHumble,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Other possibilities',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final item in alternatives) ...[
                Text(
                  item.caption == null
                      ? item.failureMode.label
                      : '${item.failureMode.label} — ${item.caption}',
                  key: Key('ranked-possibility-${item.failureMode.id}'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: Key('accept-recommended-primary-${failureMode.id}'),
              onPressed: enabled ? onAccept : null,
              child: const Text('Accept as Primary & verify'),
            ),
            if (onCallPro != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                key: const Key('recommended-call-pro'),
                onPressed: enabled ? onCallPro : null,
                child: const Text('Call a pro'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FailureModeTile extends StatelessWidget {
  const _FailureModeTile({
    required this.failureMode,
    required this.isPrimary,
    required this.standing,
    required this.isClearLeader,
    required this.enabled,
    required this.onSelected,
    this.showStandingChrome = false,
  });

  final FailureMode failureMode;
  final bool isPrimary;
  final FailureModeStanding standing;
  final bool isClearLeader;
  final bool enabled;
  final VoidCallback onSelected;
  final bool showStandingChrome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final standingPhrase = showStandingChrome
        ? householdStandingPhrase(
            standing: standing,
            surface: ConfidenceDisplaySurface.diagnosisSummary,
          )
        : null;
    final statusNote = [
      if (standingPhrase != null) standingPhrase,
      if (showStandingChrome && isClearLeader)
        'Clear leader — tap to set Primary',
    ].join('\n');
    return Card(
      key: Key('failure-mode-${failureMode.id}'),
      color: isPrimary ? scheme.primaryContainer : scheme.surface,
      child: ListTile(
        title: Text(
          failureMode.label,
          style: TextStyle(
            fontWeight: isPrimary ? FontWeight.w600 : null,
          ),
        ),
        subtitle: Text(
          statusNote.isEmpty
              ? failureMode.description
              : '${failureMode.description}\n$statusNote',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        isThreeLine: statusNote.isNotEmpty,
        trailing: Text(
          isPrimary ? 'Primary' : 'Select',
          key: Key(
            isPrimary
                ? 'failure-mode-primary-${failureMode.id}'
                : 'failure-mode-select-${failureMode.id}',
          ),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isPrimary ? scheme.primary : scheme.onSurfaceVariant,
              ),
        ),
        onTap: enabled ? onSelected : null,
      ),
    );
  }
}

class _VoiceAnswerMicButton extends StatelessWidget {
  const _VoiceAnswerMicButton({
    required this.listening,
    required this.onPressed,
    this.available = true,
    this.micKey = const Key('voice-answer-mic'),
  });

  final bool listening;
  final bool available;
  final VoidCallback onPressed;
  final Key micKey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: micKey,
      tooltip: !available
          ? UserFacingCopy.voiceWorksBestOnPhone
          : listening
              ? 'Listening…'
              : 'Speak your answer',
      onPressed: !available || listening ? null : onPressed,
      icon: listening
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(available ? Icons.mic_none : Icons.mic_off_outlined),
    );
  }
}

class _AnswerChoicePanel extends StatelessWidget {
  const _AnswerChoicePanel({
    required this.prompt,
    required this.onSelected,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onVoice,
    this.voiceListening = false,
    this.voiceAvailable = true,
    this.voiceShowButton = true,
    this.voiceUnavailableHint = false,
    this.onCancel,
    this.onBack,
    this.selectedAnswer,
    this.isRevising = false,
    this.emphasize = true,
    this.photoPath,
    this.photoEnabled = true,
    this.photoVisible = true,
    required this.freeNoteController,
    required this.freeNoteEnabled,
    required this.freeNoteSuggestions,
    required this.onSaveFreeNote,
    required this.onMarkFreeNoteSuggestion,
    this.whyAskBody,
    this.displayTitle,
    this.optionLabels,
    this.expertMode = false,
    this.offerAlreadyChecked = true,
  });

  final EvidenceTemplate prompt;
  final String? whyAskBody;
  final String? displayTitle;
  final Map<String, String>? optionLabels;
  final bool expertMode;
  final bool offerAlreadyChecked;
  final ValueChanged<String> onSelected;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onVoice;
  final bool voiceListening;
  final bool voiceAvailable;
  final bool voiceShowButton;
  final bool voiceUnavailableHint;
  final VoidCallback? onCancel;
  final VoidCallback? onBack;
  final String? selectedAnswer;
  final bool isRevising;
  final bool emphasize;
  final String? photoPath;
  final bool photoEnabled;
  final bool photoVisible;
  final TextEditingController freeNoteController;
  final bool freeNoteEnabled;
  final List<FreeObservationSuggestion> freeNoteSuggestions;
  final VoidCallback onSaveFreeNote;
  final ValueChanged<FreeObservationSuggestion> onMarkFreeNoteSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final choices = answerChoicesFor(
      prompt,
      offerAlreadyChecked: offerAlreadyChecked,
    );
    final normalizedSelected = normalizeObservationAnswer(selectedAnswer);
    return Card(
      key: const Key('answer-choice-panel'),
      color: emphasize ? scheme.surface : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: emphasize
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outline,
          width: emphasize ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRevising
                        ? 'Change this answer'
                        : 'Answer this observation',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (voiceShowButton)
                  _VoiceAnswerMicButton(
                    listening: voiceListening,
                    available: voiceAvailable,
                    onPressed: onVoice,
                  ),
              ],
            ),
            if (voiceUnavailableHint) ...[
              const SizedBox(height: 4),
              Text(
                UserFacingCopy.voiceWorksBestOnPhone,
                key: const Key('voice-works-best-on-phone'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (isRevising && selectedAnswer != null) ...[
              const SizedBox(height: 6),
              Text(
                'Current: $selectedAnswer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            KeyedSubtree(
              key: const Key('answer-choice-prompt'),
              child: Text(
                displayTitle?.trim().isNotEmpty == true
                    ? displayTitle!.trim()
                    : observationPromptTitle(prompt),
                key: Key('observation-prompt-${prompt.id}'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      height: 1.35,
                    ),
              ),
            ),
            if (visibleGuidanceDisplayBlock(
              observationGuidanceForTemplate(prompt.id),
              expertMode: expertMode,
            )
                case final guidance?) ...[
              const SizedBox(height: 12),
              _GuidanceBlockCard(
                block: guidance,
                compact: true,
                expertMode: expertMode,
              ),
            ],
            WhyAskThisTile(
              body: visibleHouseholdHowTo(
                whyAskBody ?? '',
                expertMode: expertMode,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in choices)
                  _AnswerChoiceButton(
                    choice: choice,
                    displayLabel: optionLabels?[choice],
                    isSelected: normalizedSelected != null &&
                        normalizedSelected ==
                            normalizeObservationAnswer(choice),
                    onPressed: () => onSelected(choice),
                  ),
              ],
            ),
            if (photoVisible) ...[
              const SizedBox(height: 12),
              _EvidencePhotoActions(
                galleryKey: 'answer-photo-gallery',
                cameraKey: 'answer-photo-camera',
                thumbKey: 'answer-photo-thumb',
                photoPath: photoPath,
                enabled: photoEnabled,
                onGallery: onPickGallery,
                onCamera: onPickCamera,
              ),
            ],
            const SizedBox(height: 16),
            _FreeObservationIntake(
              controller: freeNoteController,
              enabled: freeNoteEnabled,
              suggestions: freeNoteSuggestions,
              onSave: onSaveFreeNote,
              onMark: onMarkFreeNoteSuggestion,
            ),
            if (onBack != null || onCancel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (onBack != null)
                      PrimaryCta(
                        key: const Key('answer-choice-back'),
                        style: PrimaryCtaStyle.outlined,
                        icon: Icons.arrow_back,
                        label: 'Back',
                        semanticLabel: PrimaryCtaSemantics.back,
                        onPressed: onBack,
                      ),
                    const Spacer(),
                    if (onCancel != null)
                      TextButton(
                        key: const Key('answer-choice-cancel'),
                        onPressed: onCancel,
                        child: Text(isRevising ? 'Done' : 'Cancel'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FreeObservationIntake extends StatelessWidget {
  const _FreeObservationIntake({
    required this.controller,
    required this.enabled,
    required this.suggestions,
    required this.onSave,
    required this.onMark,
  });

  final TextEditingController controller;
  final bool enabled;
  final List<FreeObservationSuggestion> suggestions;
  final VoidCallback onSave;
  final ValueChanged<FreeObservationSuggestion> onMark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: const Key('free-observation-intake'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            UserFacingCopy.freeObservationTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            UserFacingCopy.freeObservationHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('free-observation-field'),
            controller: controller,
            enabled: enabled,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Lint on the vent, a new sound, anything else…',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const Key('free-observation-save'),
              onPressed: enabled ? onSave : null,
              child: const Text(UserFacingCopy.freeObservationSave),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              UserFacingCopy.freeObservationChipsLead,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    key: Key(
                      'free-observation-suggest-${suggestion.keySuffix}',
                    ),
                    label: Text(suggestion.chipLabel),
                    onPressed: enabled ? () => onMark(suggestion) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerChoiceButton extends StatelessWidget {
  const _AnswerChoiceButton({
    required this.choice,
    required this.isSelected,
    required this.onPressed,
    this.displayLabel,
  });

  final String choice;
  final String? displayLabel;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = Text(
      displayLabel?.trim().isNotEmpty == true ? displayLabel!.trim() : choice,
    );
    final key = Key('answer-choice-${answerChoiceKeySuffix(choice)}');
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
    if (isSelected) {
      return FilledButton.tonal(
        key: key,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        onPressed: onPressed,
        child: child,
      );
    }
    return OutlinedButton(
      key: key,
      style: style.copyWith(
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outline),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

class _OtherObservationsPicker extends StatelessWidget {
  const _OtherObservationsPicker({
    required this.prompts,
    required this.enabled,
    required this.onSelected,
    required this.onPickGallery,
    required this.onPickCamera,
    this.photoVisible = true,
  });

  final List<EvidenceTemplate> prompts;
  final bool enabled;
  final bool photoVisible;
  final ValueChanged<EvidenceTemplate> onSelected;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: const Key('other-observations-picker'),
      title: Text(
        UserFacingCopy.otherObservationPickerTitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      children: [
        if (photoVisible)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _EvidencePhotoActions(
              galleryKey: 'other-photo-gallery',
              cameraKey: 'other-photo-camera',
              photoPath: null,
              enabled: enabled,
              onGallery: onPickGallery,
              onCamera: onPickCamera,
            ),
          ),
        for (final prompt in prompts)
          ListTile(
            key: Key('observation-prompt-${prompt.id}'),
            enabled: enabled,
            title: Text(
              observationPromptTitle(prompt),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: enabled ? () => onSelected(prompt) : null,
          ),
      ],
    );
  }
}

class _EvidencePhotoActions extends StatelessWidget {
  const _EvidencePhotoActions({
    required this.galleryKey,
    required this.cameraKey,
    required this.enabled,
    required this.onGallery,
    required this.onCamera,
    this.photoPath,
    this.thumbKey,
  });

  final String galleryKey;
  final String cameraKey;
  final String? thumbKey;
  final String? photoPath;
  final bool enabled;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final path = photoPath?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional photo of what you see. It stays on this device.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: Key(galleryKey),
              onPressed: enabled ? onGallery : null,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Gallery'),
            ),
            OutlinedButton.icon(
              key: Key(cameraKey),
              onPressed: enabled ? onCamera : null,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Camera'),
            ),
            if (path != null && path.isNotEmpty)
              EvidencePhotoThumb(
                key: Key(thumbKey ?? 'evidence-photo-thumb'),
                path: path,
              ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryHypothesisBanner extends StatelessWidget {
  const _PrimaryHypothesisBanner({
    required this.label,
    required this.verificationOutcome,
    required this.resolveEligibility,
  });

  final String label;
  final VerificationOutcome verificationOutcome;
  final CloseResolveEligibility resolveEligibility;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nextStep = switch (resolveEligibility) {
      CloseResolveEligibility.pendingVerification =>
        'Next: complete Verification, then follow Safe Guidance.',
      CloseResolveEligibility.allowResolved =>
        'Verification confirmed — you can record Fixed.',
      CloseResolveEligibility.needsProfessional =>
        'Safe checks did not close this case — Needs a professional.',
      CloseResolveEligibility.unresolvedOnly =>
        'Unresolved, or Needs a professional.',
      CloseResolveEligibility.safetyStop =>
        'Safety stop — Needs a professional.',
    };
    return Card(
      key: const Key('primary-hypothesis-banner'),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Primary',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              key: const Key('primary-hypothesis-label'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Verification: ${_verificationLabel(verificationOutcome)}',
              key: const Key('primary-verification-state'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              nextStep,
              key: const Key('primary-next-step'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _verificationLabel(VerificationOutcome outcome) {
    return switch (outcome) {
      VerificationOutcome.pending => 'Pending',
      VerificationOutcome.supported => 'Confirmed',
      VerificationOutcome.contradicted => 'Not confirmed',
      VerificationOutcome.inconclusive => 'Could not complete',
      VerificationOutcome.notApplicable => 'Not started',
    };
  }
}

class _VerificationStatusCard extends StatelessWidget {
  const _VerificationStatusCard({
    required this.resolveEligibility,
    this.confirmNotFixedLine,
  });

  final CloseResolveEligibility resolveEligibility;
  final String? confirmNotFixedLine;

  @override
  Widget build(BuildContext context) {
    final message = switch (resolveEligibility) {
      CloseResolveEligibility.allowResolved =>
        'Verification confirmed. End Session — Ready to resolve.',
      CloseResolveEligibility.needsProfessional =>
        'Call a professional. Resolved is not available for this result.',
      CloseResolveEligibility.unresolvedOnly =>
        'Unresolved remains available. Do not mark Resolved.',
      CloseResolveEligibility.pendingVerification =>
        'Verification still needed before resolving.',
      CloseResolveEligibility.safetyStop =>
        'Safety stop — Needs a professional only.',
    };
    return Card(
      key: const Key('verification-status-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, key: const Key('verification-status-message')),
            if (confirmNotFixedLine != null &&
                confirmNotFixedLine!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                confirmNotFixedLine!,
                key: const Key('confirm-not-fixed-line'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeakHumanCard extends StatelessWidget {
  const _SpeakHumanCard({required this.diagnosis});

  final SpeakHumanDiagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('speak-human-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kSpeakHumanHeading, style: text.titleSmall),
            const SizedBox(height: 10),
            Text(kSpeakHumanMostLikelyLabel, style: text.labelLarge),
            Text(
              diagnosis.mostLikely,
              key: const Key('speak-human-most-likely'),
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(kSpeakHumanWhyLabel, style: text.labelLarge),
            Text(
              diagnosis.why,
              key: const Key('speak-human-why'),
              style: text.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(kSpeakHumanSawLabel, style: text.labelLarge),
            Text(
              diagnosis.whatYouSaw,
              key: const Key('speak-human-what-you-saw'),
              style: text.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(kSpeakHumanNextLabel, style: text.labelLarge),
            Text(
              diagnosis.nextStep,
              key: const Key('speak-human-next-step'),
              style: text.bodyMedium,
            ),
            if (diagnosis.confidenceBand != null &&
                diagnosis.confidenceBand!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                diagnosis.confidenceBand!,
                key: const Key('speak-human-confidence'),
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentConclusionCard extends StatelessWidget {
  const _CurrentConclusionCard({required this.primaryLabel});

  final String? primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('current-conclusion-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current conclusion',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              primaryLabel ?? 'Insufficient evidence',
              key: const Key('current-conclusion-label'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your answers — not a certainty or a percentage.',
              key: const Key('current-conclusion-humble'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ranked modes still standing when beginner questions are exhausted.
///
/// Presentation only — reuses the ranking snapshot already computed for this
/// build so the user sees why the beginner path ended instead of a bare
/// end/escalate button. Renders nothing when no mode has net support.
class _RemainingLikelyModesCard extends StatelessWidget {
  const _RemainingLikelyModesCard({
    required this.orderedFailureModes,
    required this.standings,
    required this.excludedFailureModeId,
  });

  final List<FailureMode> orderedFailureModes;
  final Map<String, FailureModeStanding> standings;
  final String? excludedFailureModeId;

  @override
  Widget build(BuildContext context) {
    final remaining = rankedPossibilitiesForDisplay(
      orderedFailureModes: orderedFailureModes,
      standings: standings,
      excludeFailureModeId: excludedFailureModeId,
      surface: ConfidenceDisplaySurface.diagnosisSummary,
    );
    if (remaining.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        key: const Key('remaining-likely-modes-card'),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            'Other possibilities',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            'Also consistent with some of your answers. Not a score, and not '
            'a diagnosis. A qualified technician may still be needed.',
            key: const Key('remaining-likely-modes-reason'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            for (final item in remaining)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    item.caption == null
                        ? item.failureMode.label
                        : '${item.failureMode.label} — ${item.caption}',
                    key: Key('remaining-likely-mode-${item.failureMode.id}'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CloseVerificationCard extends StatelessWidget {
  const _CloseVerificationCard({
    required this.closePath,
    required this.outcome,
    required this.enabled,
    required this.answersVisible,
    required this.onAnswer,
    this.onChangeAnswer,
    this.expertMode = false,
  });

  final FailureModeClosePath closePath;
  final VerificationOutcome outcome;
  final bool enabled;
  final bool answersVisible;
  final ValueChanged<FailureModeClosePath> onAnswer;
  final VoidCallback? onChangeAnswer;
  final bool expertMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final answered = outcome != VerificationOutcome.pending;
    return Card(
      key: const Key('verification-card'),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              answered ? 'Verification result' : 'Verification (required)',
              key: const Key('verification-title'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              closePath.verificationAsk,
              key: const Key('verification-ask'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              closePath.verificationWhy,
              key: const Key('verification-why'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _GuidanceBlockCard(
              block: guidanceForVerification(
                ask: closePath.verificationAsk,
                why: closePath.verificationWhy,
                failureModeId: closePath.failureModeId,
              ),
              compact: true,
              expertMode: expertMode,
            ),
            const SizedBox(height: 14),
            if (answered)
              Text(
                'Result: ${_resultLabel(outcome)}',
                key: const Key('verification-result'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
              )
            else if (answersVisible)
              Text(
                'Choose Confirmed / Not confirmed / Could not complete below.',
                key: const Key('verification-answers-open-hint'),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              FilledButton(
                key: Key(
                  'verification-prompt-${closeVerificationTemplateId(closePath.failureModeId)}',
                ),
                onPressed: enabled ? () => onAnswer(closePath) : null,
                child: const Text('Answer verification'),
              ),
            if (answered && onChangeAnswer != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('verification-change-result'),
                  onPressed: onChangeAnswer,
                  child: const Text('Change verification result'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resultLabel(VerificationOutcome outcome) {
    return switch (outcome) {
      VerificationOutcome.supported => 'Confirmed',
      VerificationOutcome.contradicted => 'Not confirmed',
      VerificationOutcome.inconclusive => 'Could not complete',
      VerificationOutcome.pending => 'Pending',
      VerificationOutcome.notApplicable => 'Not started',
    };
  }
}

class _RepairReadinessCard extends StatelessWidget {
  const _RepairReadinessCard({
    required this.items,
    required this.haveByToolId,
    required this.ownedToolIds,
    required this.onMark,
    required this.onSaveToInventory,
  });

  final List<RepairReadinessItem> items;
  final Map<String, bool> haveByToolId;
  final List<String> ownedToolIds;
  final void Function(RepairReadinessItem item, bool have) onMark;
  final void Function(RepairReadinessItem item, bool save) onSaveToInventory;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('repair-readiness-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tools',
              key: const Key('repair-readiness-title'),
              style: text.titleSmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Required tools must be marked I have before panel steps unlock.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Text(
                'No extra tools listed for this path.',
                key: const Key('repair-readiness-empty'),
                style: text.bodySmall,
              ),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ReadinessToolRow(
                item: items[i],
                have: haveByToolId[items[i].id],
                alreadyOwned: ownedToolIds.contains(items[i].id),
                onMark: onMark,
                onSaveToInventory: onSaveToInventory,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessToolRow extends StatelessWidget {
  const _ReadinessToolRow({
    required this.item,
    required this.have,
    required this.alreadyOwned,
    required this.onMark,
    required this.onSaveToInventory,
  });

  final RepairReadinessItem item;
  final bool? have;
  final bool alreadyOwned;
  final void Function(RepairReadinessItem item, bool have) onMark;
  final void Function(RepairReadinessItem item, bool save) onSaveToInventory;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: Key('readiness-tool-${item.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                readinessDisplayLabel(item),
                style: text.titleSmall,
              ),
            ),
            Text(
              item.optional
                  ? 'Optional'
                  : item.liveElectrical
                      ? 'Not for beginner steps'
                      : 'Required',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        if (alreadyOwned && have != false) ...[
          const SizedBox(height: 4),
          Text(
            'In your tools',
            key: Key('readiness-in-inventory-${item.id}'),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ] else if (!alreadyOwned && have != true) ...[
          const SizedBox(height: 4),
          Text(
            'Not in your tools',
            key: Key('readiness-not-in-inventory-${item.id}'),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Semantics(
              selected: have == true,
              button: true,
              child: OutlinedButton(
                key: Key('readiness-have-${item.id}'),
                onPressed: () => onMark(item, true),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      have == true ? scheme.primaryContainer : null,
                ),
                child: const Text('I have this'),
              ),
            ),
            OutlinedButton(
              key: Key('readiness-missing-${item.id}'),
              onPressed: () => onMark(item, false),
              style: OutlinedButton.styleFrom(
                backgroundColor: have == false ? scheme.errorContainer : null,
              ),
              child: const Text("I don't"),
            ),
          ],
        ),
        if (have == true && !alreadyOwned) ...[
          const SizedBox(height: 4),
          CheckboxListTile(
            key: Key('readiness-save-${item.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Also save to my tools'),
            value: false,
            onChanged: (_) => onSaveToInventory(item, true),
          ),
        ],
      ],
    );
  }
}

class _MissingCriticalToolPanel extends StatelessWidget {
  const _MissingCriticalToolPanel({
    required this.missing,
    required this.allowCaution,
    required this.onStop,
    required this.onCallPro,
    required this.onContinueCaution,
  });

  final List<RepairReadinessItem> missing;
  final bool allowCaution;
  final VoidCallback onStop;
  final VoidCallback onCallPro;
  final VoidCallback onContinueCaution;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('readiness-missing-critical-panel'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Get this tool first', style: text.titleSmall),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('readiness-stop'),
              onPressed: onStop,
              child: const Text('Stop'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const Key('readiness-call-pro'),
              onPressed: onCallPro,
              child: const Text('Call a professional'),
            ),
            if (allowCaution) ...[
              const SizedBox(height: 8),
              PrimaryCta(
                key: const Key('readiness-continue-caution'),
                style: PrimaryCtaStyle.outlined,
                label: 'Exterior checks only',
                semanticLabel: PrimaryCtaSemantics.continueAction,
                onPressed: onContinueCaution,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessCautionBanner extends StatelessWidget {
  const _ReadinessCautionBanner({required this.missing});

  final List<RepairReadinessItem> missing;

  @override
  Widget build(BuildContext context) {
    final names = missing.map((item) => item.label).join(', ');
    return Card(
      key: const Key('readiness-caution-banner'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Continuing without $names. Skip any step you cannot do safely. '
          'Do not attempt live electrical work.',
        ),
      ),
    );
  }
}

class _OpportunisticMaintenanceCard extends StatelessWidget {
  const _OpportunisticMaintenanceCard({
    required this.items,
    required this.acceptedLabels,
    required this.onAccept,
    required this.onSkipAll,
  });

  final List<OpportunisticMaintenanceItem> items;
  final Set<String> acceptedLabels;
  final ValueChanged<String> onAccept;
  final VoidCallback onSkipAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PaperCard(
      key: const Key('opportunistic-maintenance-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            UserFacingCopy.opportunisticMaintenanceTitle,
            style: text.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            UserFacingCopy.opportunisticMaintenanceBody,
            key: const Key('opportunistic-maintenance-body'),
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final item in items)
            CheckboxListTile(
              key: Key('opportunistic-item-${item.id}'),
              contentPadding: EdgeInsets.zero,
              value: acceptedLabels.contains(item.label),
              onChanged: acceptedLabels.contains(item.label)
                  ? null
                  : (_) => onAccept(item.label),
              title: Text(item.label),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('opportunistic-skip-all'),
              onPressed: onSkipAll,
              child: const Text(UserFacingCopy.opportunisticSkipAll),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrickRiskWarningBanner extends StatelessWidget {
  const _BrickRiskWarningBanner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('brick-risk-warning'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(brickRiskWarningTitle, style: text.titleSmall),
          const SizedBox(height: 6),
          Text(brickRiskWarningBody, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _ProScopeWarningCard extends StatelessWidget {
  const _ProScopeWarningCard({
    required this.onDoSafeChecks,
    required this.onEndSession,
  });

  final VoidCallback onDoSafeChecks;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('pro-scope-warning-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(proScopeWarningTitle, style: text.titleMedium),
            const SizedBox(height: 8),
            Text(proScopeWarningBody, style: text.bodyMedium),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('pro-scope-do-safe-checks'),
              onPressed: onDoSafeChecks,
              child: const Text(proScopeDoSafeChecksLabel),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const Key('pro-scope-end-session'),
              onPressed: onEndSession,
              child: const Text(proScopeEndSessionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same honesty as the guidance-phase warning, shown at the conclusion so a
/// household knows before choosing "I'll repair" or gathering tools.
class _ProScopeNoticeLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('pro-scope-notice-line'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(proScopeWarningTitle, style: text.titleSmall),
          const SizedBox(height: 6),
          Text(proScopeNoticeBody, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _ProRecommendedCard extends StatelessWidget {
  const _ProRecommendedCard({
    required this.why,
    required this.observations,
    required this.tellTechnician,
    required this.checksDone,
    required this.onUnderstand,
    required this.onCouldNot,
  });

  final String why;
  final List<SessionTimelineObservation> observations;
  final List<String> tellTechnician;
  final List<String> checksDone;
  final VoidCallback onUnderstand;
  final VoidCallback onCouldNot;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('pro-recommended-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              proRecommendedTitle,
              key: const Key('pro-recommended-title'),
              style: text.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Why we’re stopping', style: text.titleSmall),
            const SizedBox(height: 4),
            Text(why, key: const Key('pro-handoff-why')),
            const SizedBox(height: 12),
            Text('What you already observed', style: text.titleSmall),
            const SizedBox(height: 4),
            if (observations.isEmpty)
              const Text('Nothing recorded yet.')
            else
              for (final item in observations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${item.prompt}: ${item.answer}'),
                ),
            const SizedBox(height: 12),
            Text('What a technician should be told', style: text.titleSmall),
            const SizedBox(height: 4),
            for (final bullet in tellTechnician)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $bullet'),
              ),
            if (checksDone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Safe checks already done', style: text.titleSmall),
              const SizedBox(height: 4),
              for (final check in checksDone)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $check'),
                ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('pro-handoff-understand'),
              onPressed: onUnderstand,
              child: const Text(proHandoffUnderstandLabel),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const Key('pro-handoff-could-not'),
              onPressed: onCouldNot,
              child: const Text(proHandoffCouldNotLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeGuidanceCard extends StatelessWidget {
  const _SafeGuidanceCard({
    required this.steps,
    required this.stepIndex,
    required this.onDidThis,
    required this.onCouldNot,
    required this.onBack,
    this.onAlreadyChecked,
    this.comfort = RepairComfortLevel.standard,
    this.expertMode = false,
  });

  final List<String> steps;
  final int stepIndex;
  final VoidCallback onDidThis;
  final VoidCallback onCouldNot;
  final VoidCallback onBack;
  final VoidCallback? onAlreadyChecked;
  final RepairComfortLevel comfort;
  final bool expertMode;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }
    final index = stepIndex.clamp(0, steps.length - 1);
    final step = steps[index];
    final scheme = Theme.of(context).colorScheme;
    final block = visibleGuidanceDisplayBlock(
          guidanceForSafeStep(step),
          expertMode: expertMode,
        ) ??
        guidanceForSafeStep(step);
    final visibleStep = visibleHouseholdHowTo(step, expertMode: expertMode);
    final visibility = comfortStepVisibility(level: comfort, step: step);
    final safetyNeeded = visibility.showWhenToStop &&
        block.whenToStop.trim().isNotEmpty &&
        block.whenToStop.trim() != step.trim() &&
        block.whenToStop != _defaultGuidanceWhenToStop;
    return Card(
      key: const Key('safe-guidance-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              comfort == RepairComfortLevel.standard
                  ? 'Step ${index + 1} of ${steps.length}'
                  : 'Step ${index + 1} of ${steps.length} · Step detail: ${comfort.label}',
              key: const Key('guidance-step-progress'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Safe Guidance',
              key: const Key('safe-guidance-title'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 10),
            HouseholdHowToText(
              text: block.what,
              expertMode: expertMode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (visibility.showFullStep &&
                visibleStep.isNotEmpty &&
                !_sameGuidanceLine(visibleStep, block.what) &&
                !_sameGuidanceLine(visibleStep, block.how)) ...[
              const SizedBox(height: 8),
              Text(visibleStep, style: Theme.of(context).textTheme.bodyLarge),
            ],
            if (block.how.isNotEmpty &&
                !_sameGuidanceLine(block.how, block.what)) ...[
              const SizedBox(height: 8),
              HouseholdHowToText(
                text: block.how,
                expertMode: expertMode,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (visibility.showResultMeans && block.resultMeans.isNotEmpty) ...[
              const SizedBox(height: 8),
              HouseholdHowToText(
                key: Key('guidance-result-means-${index + 1}'),
                text: block.resultMeans,
                expertMode: expertMode,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (safetyNeeded && block.whenToStop.isNotEmpty) ...[
              const SizedBox(height: 8),
              HouseholdHowToText(
                key: Key('guidance-when-to-stop-${index + 1}'),
                text: block.whenToStop,
                expertMode: expertMode,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('guidance-did-this'),
              onPressed: onDidThis,
              child: const Text('I did this'),
            ),
            if (onAlreadyChecked != null && isEasyCheckGuidanceStep(step)) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                key: const Key('guidance-already-checked'),
                onPressed: onAlreadyChecked,
                child: const Text(alreadyDidThisEasyCheckLabel),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.tonal(
              key: const Key('guidance-could-not'),
              onPressed: onCouldNot,
              child: const Text("I couldn't"),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('guidance-back'),
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameGuidanceLine(String a, String b) {
  String norm(String value) =>
      value.trim().replaceAll(RegExp(r'[.;:]+$'), '').trim().toLowerCase();
  return norm(a) == norm(b);
}

const _defaultGuidanceWhenToStop =
    'Stop and call a professional if you notice smoke, a sharp burning-plastic '
    'or electrical smell, sparking, melting, or anything that feels unsafe.';

class _RootCauseInsightCard extends StatelessWidget {
  const _RootCauseInsightCard({required this.failureModeId});

  final String failureModeId;

  @override
  Widget build(BuildContext context) {
    final insight = FailureModeAuthoringRegistry.lookup(failureModeId);
    if (insight == null || !insight.hasRootCauseInsight) {
      return const SizedBox.shrink();
    }

    return Card(
      key: const Key('root-cause-insight-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this likely happened',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (insight.rootCause.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                insight.rootCause,
                key: const Key('root-cause-text'),
              ),
            ],
            if (insight.contributingFactors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Contributing factors',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final factor in insight.contributingFactors)
                Text('• $factor'),
            ],
            if (insight.preventionActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Prevention',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final action in insight.preventionActions) Text('• $action'),
            ],
            if (insight.commonMisdiagnoses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Easy to mix up with',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final item in insight.commonMisdiagnoses) Text('• $item'),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuidanceBlockCard extends StatelessWidget {
  const _GuidanceBlockCard({
    required this.block,
    this.compact = false,
    this.expertMode = false,
  });

  final GuidanceDisplayBlock block;
  final bool compact;
  final bool expertMode;

  @override
  Widget build(BuildContext context) {
    final shown =
        visibleGuidanceDisplayBlock(block, expertMode: expertMode) ?? block;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shown.how.isNotEmpty) ...[
          Text('How to check', style: labelStyle),
          const SizedBox(height: 6),
          HouseholdHowToText(
            key: const Key('observation-how'),
            text: shown.how,
            expertMode: expertMode,
            style: bodyStyle,
          ),
        ],
        if (!compact) ...[
          if (shown.what.isNotEmpty) ...[
            const SizedBox(height: 4),
            HouseholdHowToText(
              text: 'What: ${shown.what}',
              expertMode: expertMode,
              style: bodyStyle,
            ),
          ],
          if (shown.resultMeans.isNotEmpty) ...[
            const SizedBox(height: 4),
            HouseholdHowToText(
              text: 'Result means: ${shown.resultMeans}',
              expertMode: expertMode,
              style: bodyStyle,
            ),
          ],
          if (shown.whenToStop.isNotEmpty) ...[
            const SizedBox(height: 4),
            HouseholdHowToText(
              text: 'Stop if: ${shown.whenToStop}',
              expertMode: expertMode,
              style: bodyStyle?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _CloseAnswerChoicePanel extends StatelessWidget {
  const _CloseAnswerChoicePanel({
    required this.ask,
    required this.onSelected,
    required this.onCancel,
    required this.onVoice,
    this.voiceListening = false,
    this.voiceAvailable = true,
    this.voiceShowButton = true,
    this.onBack,
    this.selectedAnswer,
  });

  final String ask;
  final ValueChanged<String> onSelected;
  final VoidCallback onCancel;
  final VoidCallback onVoice;
  final bool voiceListening;
  final bool voiceAvailable;
  final bool voiceShowButton;
  final VoidCallback? onBack;
  final String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final normalizedSelected = normalizeObservationAnswer(selectedAnswer);
    return Card(
      key: const Key('close-answer-choice-panel'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedAnswer == null
                        ? 'Select a verification result'
                        : 'Change verification result',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (voiceShowButton)
                  _VoiceAnswerMicButton(
                    micKey: const Key('voice-answer-mic-close'),
                    listening: voiceListening,
                    available: voiceAvailable,
                    onPressed: onVoice,
                  ),
              ],
            ),
            if (selectedAnswer != null) ...[
              const SizedBox(height: 6),
              Text(
                'Current: $selectedAnswer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              ask,
              key: const Key('close-answer-choice-prompt'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in closeVerificationChoices)
                  _AnswerChoiceButton(
                    choice: choice,
                    isSelected: normalizedSelected != null &&
                        normalizedSelected ==
                            normalizeObservationAnswer(choice),
                    onPressed: () => onSelected(choice),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (onBack != null)
                    PrimaryCta(
                      key: const Key('close-answer-choice-back'),
                      style: PrimaryCtaStyle.text,
                      icon: Icons.arrow_back,
                      label: 'Back',
                      semanticLabel: PrimaryCtaSemantics.back,
                      onPressed: onBack,
                    ),
                  const Spacer(),
                  TextButton(
                    key: const Key('close-answer-choice-cancel'),
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyStopBanner extends StatelessWidget {
  const _SafetyStopBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('safety-stop-banner'),
      color: scheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.error, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Needs a professional',
              key: const Key('safety-stop-title'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              key: const Key('safety-stop-reason'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageSummaryCard extends StatelessWidget {
  const _PackageSummaryCard({required this.package});

  final KnowledgePackage? package;

  @override
  Widget build(BuildContext context) {
    if (package == null) {
      return const DegradedModeBanner(
        kind: DegradedModeKind.packageMissing,
        messageKey: Key('error-banner-package'),
      );
    }

    final metaStyle = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        key: const Key('package-summary'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Knowledge Package',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text('Name: ${package!.displayName}', key: const Key('package-name')),
          Text(
            'Version: ${package!.version}',
            key: const Key('package-version'),
            style: metaStyle,
          ),
          Text(
            'Category: ${package!.category}',
            key: const Key('package-category'),
            style: metaStyle,
          ),
          Text(
            'Failure modes: ${package!.failureModes.length}',
            key: const Key('package-failure-mode-count'),
            style: metaStyle,
          ),
          Text(
            'Observation prompts: ${package!.evidenceTemplates.length}',
            key: const Key('package-prompt-count'),
            style: metaStyle,
          ),
        ],
      ),
    );
  }
}

/// Owns the optional describe field so its controller is disposed with the dialog.
///
/// Packaged title/hint paint first. The same question-card overlay may swap
/// a nicer line. Typing does not call Groq. Recorded prefix stays
/// [kOtherDescribeChoiceId].
class _OptionalDescribeNoteDialog extends StatefulWidget {
  const _OptionalDescribeNoteDialog({required this.phrasing});

  final ValueListenable<GroqPhrasingAccepted?> phrasing;

  @override
  State<_OptionalDescribeNoteDialog> createState() =>
      _OptionalDescribeNoteDialogState();
}

class _OptionalDescribeNoteDialogState
    extends State<_OptionalDescribeNoteDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GroqPhrasingAccepted?>(
      valueListenable: widget.phrasing,
      builder: (context, overlay, _) {
        final title = overlay?.describeTitle.trim().isNotEmpty == true
            ? overlay!.describeTitle.trim()
            : kPackagedDescribeDialogTitle;
        final hint = overlay?.describeHint.trim().isNotEmpty == true
            ? overlay!.describeHint.trim()
            : kPackagedDescribeDialogHint;
        return AlertDialog(
          title: Text(
            title,
            key: const Key('answer-other-note-title'),
          ),
          content: TextField(
            key: const Key('answer-other-note-field'),
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: kPackagedDescribeDialogLabel,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('answer-other-confirm'),
              onPressed: () => Navigator.of(context).pop(_controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
