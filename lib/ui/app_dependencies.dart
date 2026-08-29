import 'dart:async';

import 'package:flutter/foundation.dart';

import '../helpers/demo_sample_home.dart';
import '../helpers/device_online.dart';
import '../helpers/dryer_energy_source.dart';
import '../helpers/dryer_problem_starter.dart';
import '../models/enrichment_note.dart';
import '../services/enrichment_provider.dart';
import '../services/plugin_maintenance_notifier.dart';
import '../services/maintenance_notifier.dart';
import '../helpers/evidence_prompt_match.dart';
import '../helpers/household_entitlement.dart';
import '../helpers/household_member_label.dart';
import '../helpers/impact_tracker.dart';
import '../helpers/pattern_hint.dart';
import '../helpers/inventory_export.dart';
import '../helpers/package_resolve.dart';
import '../helpers/local_backup.dart';
import '../helpers/maintenance_reminder_copy.dart';
import '../helpers/safety_stop.dart';
import '../helpers/stale_session.dart';
import '../helpers/user_facing_error.dart';
import '../knowledge_factory/failure_mode_authoring_registry.dart';
import '../knowledge_factory/dishwasher_mvp_v01.dart';
import '../knowledge_factory/washer_mvp_v01.dart';
import '../models/appliance.dart';
import '../models/decision_context.dart';
import '../models/evidence.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/knowledge_package.dart';
import '../models/knowledge_package_ref.dart';
import '../models/maintenance_reminder.dart';
import '../models/repair_comfort_profile.dart';
import '../models/repair_session.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import '../models/session_ui_resume_state.dart';
import '../models/tool.dart';
import '../services/appliance_repository.dart';
import '../services/evidence_photo_picker.dart';
import '../services/household_repository.dart';
import '../services/knowledge_package_repository.dart';
import '../services/local_domain_store.dart';
import '../services/ranking_service.dart';
import '../services/rating_plate_ocr_factory.dart';
import '../services/appliance_barcode_scanner_factory.dart';
import '../services/repair_session_repository.dart';
import '../services/session_coordinator.dart';
import '../services/voice_answer.dart';
import '../services/voice_answer_speech.dart';
import 'app_theme.dart';

/// In-memory composition root for the developer UI.
///
/// It owns no diagnostic behavior. Its only workflow helper advances a newly
/// created demo session through the fixed setup states required before the UI
/// can collect observations.
class AppDependencies {
  factory AppDependencies({
    DateTime Function()? clock,
    LocalDomainStore? store,
    KnowledgePackageRepository? knowledgePackageRepository,
    EvidencePhotoPicker? photoPicker,
    RatingPlateOcr? ratingPlateOcr,
    ApplianceBarcodeScanner? barcodeScanner,
    VoiceAnswerListener? voiceAnswer,
    bool firstRunComplete = true,
    bool disclaimerAcknowledged = true,
    bool Function()? isOnline,
    Listenable? onlineListenable,
    MaintenanceNotifier? maintenanceNotifier,
    EnrichmentProvider? enrichmentProvider,
  }) {
    late final AppDependencies dependencies;
    void onChanged() => dependencies._schedulePersist();

    final householdRepository = HouseholdRepository(onChanged: onChanged);
    final applianceRepository = ApplianceRepository(onChanged: onChanged);
    final packages =
        knowledgePackageRepository ?? KnowledgePackageRepository();
    final repairSessionRepository = RepairSessionRepository(
      onChanged: onChanged,
    );

    dependencies = AppDependencies._(
      householdRepository: householdRepository,
      applianceRepository: applianceRepository,
      knowledgePackageRepository: packages,
      repairSessionRepository: repairSessionRepository,
      sessionCoordinator: SessionCoordinator(
        householdRepository: householdRepository,
        applianceRepository: applianceRepository,
        knowledgePackageRepository: packages,
        repairSessionRepository: repairSessionRepository,
      ),
      store: store,
      clock: clock ?? DateTime.now,
      firstRunComplete: firstRunComplete,
      disclaimerAcknowledged: disclaimerAcknowledged,
      photoPicker: photoPicker ?? ImagePickerEvidencePhotoPicker(),
      ratingPlateOcr: ratingPlateOcr ?? createRatingPlateOcr(),
      barcodeScanner:
          barcodeScanner ?? createApplianceBarcodeScanner(),
      voiceAnswer: voiceAnswer ?? const SilentVoiceAnswerListener(),
      isOnline: isOnline ?? () => true,
      onlineListenable: onlineListenable,
      maintenanceNotifier: maintenanceNotifier ?? SilentMaintenanceNotifier(),
      enrichmentProvider: enrichmentProvider ?? const StubEnrichmentProvider(),
    );
    return dependencies;
  }

  /// Creates dependencies and reloads any locally persisted domain state.
  static Future<AppDependencies> createPersisted({
    DateTime Function()? clock,
  }) async {
    final store = LocalDomainStore();
    await store.init();
    final firstRunComplete = await store.loadFirstRunComplete();
    final disclaimerAcknowledged = await store.loadDisclaimerAcknowledged();
    final onlineMonitor = DeviceOnlineMonitor();
    await onlineMonitor.start();
    final dependencies = AppDependencies(
      clock: clock,
      store: store,
      firstRunComplete: firstRunComplete,
      disclaimerAcknowledged: disclaimerAcknowledged,
      voiceAnswer: PlatformSpeechVoiceAnswer(),
      isOnline: () => onlineMonitor.isOnline,
      onlineListenable: onlineMonitor,
      maintenanceNotifier:
          kIsWeb ? SilentMaintenanceNotifier() : PluginMaintenanceNotifier(),
    );
    await dependencies.restore();
    await dependencies.loadThemeChoice();
    return dependencies;
  }

  AppDependencies._({
    required this.householdRepository,
    required this.applianceRepository,
    required this.knowledgePackageRepository,
    required this.repairSessionRepository,
    required this.sessionCoordinator,
    required LocalDomainStore? store,
    required DateTime Function() clock,
    required this.firstRunComplete,
    required this.disclaimerAcknowledged,
    required this.photoPicker,
    required this.ratingPlateOcr,
    required this.barcodeScanner,
    required this.voiceAnswer,
    required bool Function() isOnline,
    this.onlineListenable,
    required this.maintenanceNotifier,
    required this.enrichmentProvider,
  }) : _store = store,
       _clock = clock,
       _isOnline = isOnline;

  final HouseholdRepository householdRepository;
  final ApplianceRepository applianceRepository;
  final KnowledgePackageRepository knowledgePackageRepository;
  final RepairSessionRepository repairSessionRepository;
  final SessionCoordinator sessionCoordinator;
  final EvidencePhotoPicker photoPicker;
  final RatingPlateOcr ratingPlateOcr;
  final ApplianceBarcodeScanner barcodeScanner;
  final VoiceAnswerListener voiceAnswer;
  final MaintenanceNotifier maintenanceNotifier;
  final EnrichmentProvider enrichmentProvider;
  final Listenable? onlineListenable;
  final LocalDomainStore? _store;
  final DateTime Function() _clock;
  final bool Function() _isOnline;

  DateTime get now => _clock().toUtc();

  final Map<String, String> _sessionIdByApplianceId = {};
  final Map<String, SessionUiResumeState> _sessionUiResumeBySessionId = {};
  final List<MaintenanceReminder> _maintenanceReminders = [];
  final List<EnrichmentNote> _enrichmentNotes = [];
  final Set<String> _dismissedPatternHintKeys = {};
  DateTime _lastTimestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  int _idCounter = 0;
  Future<void>? _persistChain;
  Future<void>? _toolsPersistChain;

  Household? currentHousehold;
  String? currentMemberId;
  bool firstRunComplete;
  bool disclaimerAcknowledged;
  AppThemeChoice themeChoice = AppThemeChoice.butlersBook;
  AppThemeChoice lastLightTheme = AppThemeChoice.butlersBook;
  bool includeSampleOpenSession = true;

  /// Chrome/QA: treat camera and microphone as denied without OS dialogs.
  /// Repair still completes with chips, typed model, and diagrams.
  bool simulateMediaDenied = false;

  /// Chrome/QA: show Offline copy without OS airplane mode.
  bool simulateOffline = false;
  RepairComfortProfile repairComfort = const RepairComfortProfile();
  bool expertMode = false;
  bool householdProEnabled = false;

  HouseholdEntitlement get entitlement => HouseholdEntitlement(
        householdProEnabled: householdProEnabled,
      );

  Future<void> completeFirstRun() async {
    firstRunComplete = true;
    await _store?.saveFirstRunComplete();
  }

  Future<void> acknowledgeDisclaimer() async {
    disclaimerAcknowledged = true;
    await _store?.saveDisclaimerAcknowledged();
  }

  Future<void> loadThemeChoice() async {
    final store = _store;
    if (store == null) {
      return;
    }
    themeChoice = AppThemeChoice.parse(await store.loadThemeChoice());
    final lastLight = AppThemeChoice.parse(await store.loadLastLightTheme());
    lastLightTheme =
        lastLight.isDark ? AppThemeChoice.butlersBook : lastLight;
    if (!themeChoice.isDark) {
      lastLightTheme = themeChoice;
    }
  }

  Future<void> applyThemeChoice(AppThemeChoice choice) async {
    if (!choice.isDark) {
      lastLightTheme = choice;
    }
    themeChoice = choice;
    await _store?.saveThemeChoice(choice.name);
    await _store?.saveLastLightTheme(lastLightTheme.name);
  }

  /// Non-terminal repair sessions for the active profile.
  int get openSessionCount {
    var count = 0;
    for (final session in repairSessionRepository.listAllSessions()) {
      if (_isTerminal(session.currentState)) {
        continue;
      }
      if (!_applianceInCurrentHousehold(session.applianceId)) {
        continue;
      }
      count += 1;
    }
    return count;
  }

  String get dryerPackageVersion {
    final packages = knowledgePackageRepository.loadByCategory('dryer');
    if (packages.isEmpty) {
      return '—';
    }
    return packages.first.version;
  }

  bool get isOnline => !simulateOffline && _isOnline();

  bool hasInstalledPackageFor(String category) {
    return knowledgePackageRepository.loadByCategory(category).isNotEmpty;
  }

  /// Installs a bundled guide from this device. No network.
  bool installBundledPackage(String category) {
    return knowledgePackageRepository.installBundledCategory(category) != null;
  }

  /// Abandons in-progress sessions on the active profile. Does not write
  /// memory. Continue repair is gone; Start repair is a new empty session.
  /// See docs/qa/RESUME_CASES.md case 4.
  void clearOpenSessions() {
    final open = repairSessionRepository
        .listAllSessions()
        .where(
          (session) =>
              !_isTerminal(session.currentState) &&
              _applianceInCurrentHousehold(session.applianceId),
        )
        .toList();
    for (final session in open) {
      sessionCoordinator.transition(
        sessionId: session.id,
        to: RepairSessionState.abandoned,
        historyEntryId: _nextId('history'),
        reason: 'Cleared from Settings',
        triggeredBy: SessionTransitionTrigger.user,
        occurredAt: nextTimestamp(),
      );
      _sessionUiResumeBySessionId.remove(session.id);
      _sessionIdByApplianceId.remove(session.applianceId);
    }
    _scrubDeadOpenSessionState();
    _schedulePersist();
  }

  /// True when the in-progress session for [appliance] is older than
  /// [staleOpenSessionAfter].
  bool isOpenSessionStale(Appliance appliance) {
    final session = _openSessionForAppliance(appliance.id);
    if (session == null) {
      return false;
    }
    return sessionIsStale(session, _clock());
  }

  /// Abandons the in-progress session for [appliance] without a memory row.
  void abandonOpenSession(Appliance appliance) {
    final session = _openSessionForAppliance(appliance.id);
    if (session == null) {
      return;
    }
    sessionCoordinator.transition(
      sessionId: session.id,
      to: RepairSessionState.abandoned,
      historyEntryId: _nextId('history'),
      reason: 'Started fresh after stale session',
      triggeredBy: SessionTransitionTrigger.user,
      occurredAt: nextTimestamp(),
    );
    _sessionUiResumeBySessionId.remove(session.id);
    _sessionIdByApplianceId.remove(session.applianceId);
    _schedulePersist();
  }

  /// Local homes on this device, oldest first. No cloud account.
  List<Household> listHouseholds() {
    final items = householdRepository.listAll().toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(items);
  }

  /// People in the active home. Share appliances, tools, and House Book.
  List<HouseholdMember> listHouseholdMembers() {
    final items = [...(currentHousehold?.members ?? const <HouseholdMember>[])]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(items);
  }

  HouseholdMember? get currentMember {
    final household = currentHousehold;
    if (household == null) {
      return null;
    }
    final id = currentMemberId;
    if (id != null) {
      for (final member in household.members) {
        if (member.id == id) {
          return member;
        }
      }
    }
    if (household.members.isEmpty) {
      return null;
    }
    return household.members.first;
  }

  String displayNameForUserId(String? userId) {
    return householdMemberDisplayName(
      household: currentHousehold,
      userId: userId,
    );
  }

  /// Switches the active home. Appliances and memory follow the home.
  void switchHousehold(String householdId) {
    final household = householdRepository.getById(householdId);
    if (household == null) {
      throw StateError('That household profile was not found.');
    }
    currentHousehold = household;
    _syncCurrentMemberId();
    _schedulePersist();
  }

  void switchMember(String memberId) {
    final household = currentHousehold;
    if (household == null) {
      throw StateError('Create a household before switching who is using it.');
    }
    HouseholdMember? found;
    for (final member in household.members) {
      if (member.id == memberId) {
        found = member;
        break;
      }
    }
    if (found == null) {
      throw StateError('That person is not in this household.');
    }
    currentMemberId = found.id;
    _schedulePersist();
  }

  HouseholdMember addHouseholdMember(String displayName) {
    final household = currentHousehold;
    if (household == null) {
      throw StateError('Create a household before adding a person.');
    }
    if (!entitlement.allowsAnotherPerson(
      existingMemberCount: household.members.length,
    )) {
      throw StateError(UserFacingCopy.householdProExtraPersonBlocked);
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw StateError('Enter a name.');
    }
    final member = HouseholdMember(
      id: _nextId('member'),
      householdId: household.id,
      displayName: trimmed,
      createdAt: nextTimestamp(),
    );
    final updated = household.copyWith(
      members: [...household.members, member],
    );
    householdRepository.save(updated);
    currentHousehold = updated;
    currentMemberId = member.id;
    _schedulePersist();
    return member;
  }

  Household createHousehold(String name) {
    final existingCount = householdRepository.listAll().length;
    if (!entitlement.allowsAnotherHome(existingHomeCount: existingCount)) {
      throw StateError(UserFacingCopy.householdProExtraHomeBlocked);
    }
    final createdAt = nextTimestamp();
    final householdId = _nextId('household');
    final memberId = _nextId('member');
    final member = HouseholdMember(
      id: memberId,
      householdId: householdId,
      displayName: defaultHouseholdMemberDisplayName,
      createdAt: createdAt,
    );
    final household = householdRepository.create(
      Household(
        id: householdId,
        name: name.trim(),
        ownerUserId: memberId,
        createdAt: createdAt,
        schemaVersion: '1.0',
        members: [member],
      ),
    );
    currentHousehold = household;
    currentMemberId = memberId;
    _schedulePersist();
    return household;
  }

  Household? findSampleHousehold() {
    for (final household in householdRepository.listAll()) {
      if (household.name == DemoSampleHome.householdName) {
        return household;
      }
    }
    return null;
  }

  bool get hasSampleHome => findSampleHousehold() != null;

  /// Seeds one dryer and one washer with stable model labels, closed dryer
  /// history, and optionally an open dryer session.
  ///
  /// Replaces prior sample-home appliances and sessions. Other households
  /// are left unchanged.
  Household loadSampleHome({bool? includeOpenSession}) {
    final withOpen = includeOpenSession ?? includeSampleOpenSession;
    includeSampleOpenSession = withOpen;
    installBundledPackage('dryer');
    installBundledPackage('washer');

    var household = findSampleHousehold();
    if (household == null) {
      household = createHousehold(DemoSampleHome.householdName);
    } else {
      switchHousehold(household.id);
      _purgeHouseholdContents(household.id);
    }

    final dryer = addDryer(
      name: DemoSampleHome.dryerName,
      manufacturer: DemoSampleHome.manufacturer,
      modelNumber: DemoSampleHome.modelNumber,
      serialNumber: DemoSampleHome.dryerSerial,
      location: DemoSampleHome.location,
      energySource: ApplianceEnergySource.electric,
    );
    addWasher(
      name: DemoSampleHome.washerName,
      manufacturer: DemoSampleHome.manufacturer,
      modelNumber: DemoSampleHome.washerModelNumber,
      serialNumber: DemoSampleHome.washerSerial,
      location: DemoSampleHome.location,
    );

    _recordClosedSampleSession(
      dryer: dryer,
      whatFixedIt: 'Thermal fuse replaced',
      preventionNote: 'Keep the vent path clear',
      userNote: 'Thermal fuse replaced previously',
      rankingLeaderFailureModeId: 'thermal-fuse-open',
    );
    _recordClosedSampleSession(
      dryer: dryer,
      whatFixedIt: 'Lint cleaned thoroughly',
      preventionNote: 'Clean the lint filter every load',
      userNote: 'Lint cleaned thoroughly 3 months ago',
      rankingLeaderFailureModeId: 'dusty-lint-smell',
      rootCause: 'Packed lint in the filter screen',
    );

    addMaintenanceReminder(
      applianceId: dryer.id,
      note: cleanLintSystemTitle,
      remindOn: nextTimestamp().add(const Duration(days: 7)),
    );

    if (withOpen) {
      final sessionId = startOrResumeSession(dryer);
      final session = repairSessionRepository.getSession(sessionId);
      if (session != null) {
        final resolution = resolveDryerStarter(
          selectedSymptomIds: const {'no-heat'},
        );
        sessionCoordinator.addEvidence(
          evidence: Evidence(
            id: nextId('evidence'),
            sessionId: session.id,
            applianceId: dryer.id,
            type: EvidenceType.textObservation,
            observation: "What's going on with the dryer?",
            answer: buildStarterComplaintAnswer(resolution: resolution),
            templateId: problemStarterComplaintTemplateId,
            collectedAt: nextTimestamp(),
            collectedInState: session.currentState,
            source: EvidenceSource.user,
            schemaVersion: session.schemaVersion,
          ),
          evidenceLinkId: nextId('evidence-link'),
        );
      }
    }

    _scrubDeadOpenSessionState();
    _schedulePersist();
    return household;
  }

  /// Restores the canned sample home. No-op if sample was never loaded.
  Household? resetSampleData({bool? includeOpenSession}) {
    if (findSampleHousehold() == null) {
      _scrubDeadOpenSessionState();
      _schedulePersist();
      return null;
    }
    return loadSampleHome(includeOpenSession: includeOpenSession);
  }

  void _purgeHouseholdContents(String householdId) {
    final sessionIds = repairSessionRepository
        .listAllSessions()
        .where((session) => session.householdId == householdId)
        .map((session) => session.id)
        .toList();
    sessionCoordinator.removePackageRefs(sessionIds);
    repairSessionRepository.removeSessions(sessionIds);
    for (final sessionId in sessionIds) {
      _sessionUiResumeBySessionId.remove(sessionId);
    }

    final appliances = applianceRepository.listForHousehold(
      householdId,
      includeArchived: true,
    );
    for (final appliance in appliances) {
      _sessionIdByApplianceId.remove(appliance.id);
      applianceRepository.delete(appliance.id);
    }

    _maintenanceReminders.removeWhere(
      (item) => item.householdId == householdId,
    );
    _scrubDeadOpenSessionState();
  }

  /// Drops Continue-repair pointers and guidance resume for dead sessions.
  void _scrubDeadOpenSessionState() {
    _reconcileOpenSessionIndex();
    _sessionUiResumeBySessionId.removeWhere((sessionId, _) {
      final session = repairSessionRepository.getSession(sessionId);
      return session == null || _isTerminal(session.currentState);
    });
  }

  void _recordClosedSampleSession({
    required Appliance dryer,
    required String whatFixedIt,
    required String preventionNote,
    required String userNote,
    String? rankingLeaderFailureModeId,
    String? rootCause,
  }) {
    final sessionId = startOrResumeSession(dryer);
    endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: whatFixedIt,
      preventionNote: preventionNote,
      userNote: userNote,
      rankingLeaderFailureModeId: rankingLeaderFailureModeId,
      rootCause: rootCause,
    );
  }

  bool householdOwnsTool(String toolId) {
    return currentHousehold?.ownedToolIds.contains(toolId) ?? false;
  }

  void rememberOwnedTool(String toolId) {
    final household = currentHousehold;
    final id = toolId.trim();
    if (household == null || id.isEmpty || household.ownedToolIds.contains(id)) {
      return;
    }
    final nextIds = [...household.ownedToolIds, id]..sort();
    final updated = household.copyWith(
      ownedToolIds: List<String>.from(nextIds),
      ownedToolsGeneration: household.ownedToolsGeneration + 1,
    );
    currentHousehold = updated;
    householdRepository.save(updated);
    _persistOwnedTools(updated);
  }

  void forgetOwnedTool(String toolId) {
    final household = currentHousehold;
    if (household == null || !household.ownedToolIds.contains(toolId)) {
      return;
    }
    final nextIds =
        household.ownedToolIds.where((id) => id != toolId).toList()..sort();
    final updated = household.copyWith(
      ownedToolIds: List<String>.from(nextIds),
      ownedToolsGeneration: household.ownedToolsGeneration + 1,
    );
    currentHousehold = updated;
    householdRepository.save(updated);
    _persistOwnedTools(updated);
  }

  Appliance addDryer({
    String? name,
    String? manufacturer,
    String? modelNumber,
    String? serialNumber,
    String? location,
    DateTime? installationDate,
    int? estimatedAgeYears,
    String? ratingLabelPhotoPath,
    ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
  }) {
    return _addDemoAppliance(
      category: 'dryer',
      firstName: 'Laundry Room Dryer',
      numberedPrefix: 'Dryer',
      modelPrefix: 'DEMO-DRYER',
      name: name,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      location: location,
      installationDate: installationDate,
      estimatedAgeYears: estimatedAgeYears,
      ratingLabelPhotoPath: ratingLabelPhotoPath,
      energySource: energySource,
    );
  }

  Appliance addWasher({
    String? name,
    String? manufacturer,
    String? modelNumber,
    String? serialNumber,
    String? location,
    DateTime? installationDate,
    int? estimatedAgeYears,
    String? ratingLabelPhotoPath,
    WasherLoadStyle washerLoadStyle = WasherLoadStyle.unknown,
  }) {
    return _addDemoAppliance(
      category: 'washer',
      firstName: 'Laundry Room Washer',
      numberedPrefix: 'Washer',
      modelPrefix: 'DEMO-WASHER',
      name: name,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      location: location,
      installationDate: installationDate,
      estimatedAgeYears: estimatedAgeYears,
      ratingLabelPhotoPath: ratingLabelPhotoPath,
      washerLoadStyle: washerLoadStyle,
    );
  }

  Appliance addFridge({
    String? name,
    String? manufacturer,
    String? modelNumber,
    String? serialNumber,
    String? location,
    DateTime? installationDate,
    int? estimatedAgeYears,
    String? ratingLabelPhotoPath,
  }) {
    return _addDemoAppliance(
      category: 'fridge',
      firstName: 'Kitchen Fridge',
      numberedPrefix: 'Fridge',
      modelPrefix: 'DEMO-FRIDGE',
      name: name,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      location: location,
      defaultLocation: 'Kitchen',
      installationDate: installationDate,
      estimatedAgeYears: estimatedAgeYears,
      ratingLabelPhotoPath: ratingLabelPhotoPath,
    );
  }

  Appliance addDishwasher({
    String? name,
    String? manufacturer,
    String? modelNumber,
    String? serialNumber,
    String? location,
    DateTime? installationDate,
    int? estimatedAgeYears,
    String? ratingLabelPhotoPath,
  }) {
    return _addDemoAppliance(
      category: 'dishwasher',
      firstName: 'Kitchen Dishwasher',
      numberedPrefix: 'Dishwasher',
      modelPrefix: 'DEMO-DW',
      name: name,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      location: location,
      defaultLocation: 'Kitchen',
      installationDate: installationDate,
      estimatedAgeYears: estimatedAgeYears,
      ratingLabelPhotoPath: ratingLabelPhotoPath,
    );
  }

  Appliance _addDemoAppliance({
    required String category,
    required String firstName,
    required String numberedPrefix,
    required String modelPrefix,
    String? name,
    String? manufacturer,
    String? modelNumber,
    String? serialNumber,
    String? location,
    DateTime? installationDate,
    int? estimatedAgeYears,
    String? ratingLabelPhotoPath,
    String defaultLocation = 'Laundry Room',
    ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
    WasherLoadStyle washerLoadStyle = WasherLoadStyle.unknown,
  }) {
    final household = currentHousehold;
    if (household == null) {
      throw StateError('Create a household before adding an appliance.');
    }

    final timestamp = nextTimestamp();
    final number =
        applianceRepository
            .listForHousehold(household.id)
            .where((item) => item.category == category)
            .length +
        1;
    final trimmedName = name?.trim();
    final trimmedBrand = manufacturer?.trim();
    final trimmedModel = modelNumber?.trim();
    final trimmedSerial = serialNumber?.trim();
    final trimmedLocation = location?.trim();
    final appliance = applianceRepository.create(
      Appliance(
        id: _nextId('appliance'),
        householdId: household.id,
        name:
            (trimmedName != null && trimmedName.isNotEmpty)
                ? trimmedName
                : (number == 1 ? firstName : '$numberedPrefix $number'),
        category: category,
        manufacturer:
            (trimmedBrand != null && trimmedBrand.isNotEmpty)
                ? trimmedBrand
                : 'Demo Manufacturer',
        modelNumber:
            (trimmedModel != null && trimmedModel.isNotEmpty)
                ? trimmedModel
                : '$modelPrefix-$number',
        serialNumber:
            (trimmedSerial != null && trimmedSerial.isNotEmpty)
                ? trimmedSerial
                : null,
        location:
            (trimmedLocation != null && trimmedLocation.isNotEmpty)
                ? trimmedLocation
                : defaultLocation,
        status: ApplianceStatus.active,
        schemaVersion: '1.0',
        createdAt: timestamp,
        updatedAt: timestamp,
        installationDate: installationDate,
        estimatedAgeYears: estimatedAgeYears,
        ratingLabelPhotoPath: ratingLabelPhotoPath,
        energySource: energySource,
        washerLoadStyle: washerLoadStyle,
      ),
    );
    _schedulePersist();
    return appliance;
  }

  Appliance updateAppliance({
    required Appliance appliance,
    required String name,
    required String manufacturer,
    required String modelNumber,
    String? serialNumber,
    required String location,
    DateTime? installationDate,
    int? estimatedAgeYears,
    String? ratingLabelPhotoPath,
    ApplianceEnergySource? energySource,
    WasherLoadStyle? washerLoadStyle,
  }) {
    final household = currentHousehold;
    if (household == null || household.id != appliance.householdId) {
      throw StateError('The appliance does not belong to the active household.');
    }
    final trimmedName = name.trim();
    final trimmedBrand = manufacturer.trim();
    final trimmedModel = modelNumber.trim();
    final trimmedSerial = serialNumber?.trim() ?? '';
    final trimmedLocation = location.trim();
    final saved = applianceRepository.save(
      Appliance(
        id: appliance.id,
        householdId: appliance.householdId,
        name: trimmedName.isNotEmpty ? trimmedName : appliance.name,
        category: appliance.category,
        manufacturer: trimmedBrand,
        modelNumber: trimmedModel,
        serialNumber: trimmedSerial.isEmpty ? null : trimmedSerial,
        location:
            trimmedLocation.isNotEmpty ? trimmedLocation : appliance.location,
        status: appliance.status,
        schemaVersion: appliance.schemaVersion,
        createdAt: appliance.createdAt,
        updatedAt: nextTimestamp(),
        installationDate: installationDate,
        estimatedAgeYears: estimatedAgeYears,
        ratingLabelPhotoPath: ratingLabelPhotoPath,
        energySource: energySource ?? appliance.energySource,
        washerLoadStyle: washerLoadStyle ?? appliance.washerLoadStyle,
      ),
    );
    _schedulePersist();
    return saved;
  }

  void _ensureDryerEnergyEvidence({
    required Appliance appliance,
    required RepairSession session,
  }) {
    if (appliance.category != 'dryer') {
      return;
    }
    final answer = gasDryerTypeAnswerFor(appliance.energySource);
    if (answer == null) {
      return;
    }
    final recorded = repairSessionRepository.evidenceForSession(session.id);
    if (answerForTemplate(
          recordedEvidence: recorded,
          templateId: gasDryerTypeTemplateId,
        ) !=
        null) {
      return;
    }
    EvidenceTemplate? template;
    final package = packageForSession(session.id);
    if (package == null) {
      return;
    }
    template = gasDryerTypeTemplate(package.evidenceTemplates);
    if (template == null) {
      return;
    }
    sessionCoordinator.addEvidence(
      evidence: Evidence(
        id: _nextId('evidence'),
        sessionId: session.id,
        applianceId: appliance.id,
        type: EvidenceType.structuredAnswer,
        observation: observationPromptTitle(template),
        answer: answer,
        templateId: gasDryerTypeTemplateId,
        collectedAt: nextTimestamp(),
        collectedInState: session.currentState,
        source: EvidenceSource.system,
        schemaVersion: session.schemaVersion,
      ),
      evidenceLinkId: _nextId('evidence-link'),
    );
  }

  void syncDryerEnergyFromInterview({
    required Appliance appliance,
    required String answer,
  }) {
    if (appliance.category != 'dryer') {
      return;
    }
    final source = energySourceFromGasDryerTypeAnswer(answer);
    if (source == null) {
      return;
    }
    updateAppliance(
      appliance: appliance,
      name: appliance.name,
      manufacturer: appliance.manufacturer,
      modelNumber: appliance.modelNumber,
      serialNumber: appliance.serialNumber,
      location: appliance.location,
      installationDate: appliance.installationDate,
      estimatedAgeYears: appliance.estimatedAgeYears,
      ratingLabelPhotoPath: appliance.ratingLabelPhotoPath,
      energySource: source,
    );
  }

  List<Appliance> appliancesForCurrentHousehold() {
    final household = currentHousehold;
    if (household == null) {
      return const [];
    }
    return applianceRepository.listForHousehold(household.id);
  }

  /// Active and retired units for a proof-of-ownership inventory.
  List<Appliance> appliancesForInventoryExport() {
    final household = currentHousehold;
    if (household == null) {
      return const [];
    }
    final items = [
      ...applianceRepository.listForHousehold(
        household.id,
        includeArchived: true,
      ),
    ]..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (byName != 0) {
          return byName;
        }
        return a.category.compareTo(b.category);
      });
    return List.unmodifiable(items);
  }

  /// Plain-text inventory for the share sheet. Local only.
  String currentHouseholdInventoryExportText() {
    final household = currentHousehold;
    if (household == null) {
      throw StateError('Add a household to export an inventory.');
    }
    final rows = appliancesForInventoryExport()
        .map(_inventoryExportRow)
        .toList();
    return formatHouseholdInventoryExport(
      householdName: household.name,
      generatedAt: now,
      rows: rows,
      premiumFormatting: entitlement.allowsPremiumExportFormatting,
      memberNames: [
        for (final member in household.members) member.displayName,
      ],
    );
  }

  InventoryExportRow _inventoryExportRow(Appliance appliance) {
    final history = repairHistoryForAppliance(appliance.id, limit: 1);
    if (history.isEmpty) {
      return InventoryExportRow(appliance: appliance);
    }
    final item = history.first;
    return InventoryExportRow(
      appliance: appliance,
      lastRepairLine: inventoryLastRepairLine(
        completedAt: item.completedAt,
        outcome: item.outcome,
      ),
      lastRepairRootCause: item.outcome.rootCause,
      lastRepairContributing: item.outcome.contributingFactors,
    );
  }

  /// Soft-retires [appliance]. Historical sessions/outcomes remain readable.
  void archiveAppliance(Appliance appliance) {
    final household = currentHousehold;
    if (household == null || household.id != appliance.householdId) {
      throw StateError('The appliance does not belong to the active household.');
    }
    if (!applianceIsListed(appliance.status)) {
      return;
    }

    applianceRepository.archive(
      appliance.id,
      updatedAt: nextTimestamp(),
    );
    _sessionIdByApplianceId.remove(appliance.id);
    _schedulePersist();
  }

  /// True when [appliance] already has a non-terminal repair session.
  bool hasInProgressSession(Appliance appliance) {
    return _openSessionForAppliance(appliance.id) != null;
  }

  /// Open-session snapshot: id, appliance, evidence, and current step.
  ///
  /// Null when there is no in-progress repair. Does not create sessions or
  /// memory rows.
  ActiveSessionSnapshot? activeSessionSnapshotFor(Appliance appliance) {
    final session = _openSessionForAppliance(appliance.id);
    if (session == null) {
      return null;
    }
    return ActiveSessionSnapshot(
      sessionId: session.id,
      applianceId: session.applianceId,
      currentState: session.currentState,
      evidence: List<Evidence>.unmodifiable(
        repairSessionRepository.evidenceForSession(session.id),
      ),
      uiResume: uiResumeForSession(session.id),
    );
  }

  /// Ephemeral session UI fields that survive leaving SessionScreen.
  SessionUiResumeState? uiResumeForSession(String sessionId) {
    return _sessionUiResumeBySessionId[sessionId];
  }

  /// Persists pending question / close-verification panel for [sessionId].
  void saveSessionUiResume(String sessionId, SessionUiResumeState state) {
    if (state.isEmpty) {
      _sessionUiResumeBySessionId.remove(sessionId);
    } else {
      _sessionUiResumeBySessionId[sessionId] = state;
    }
    final session = repairSessionRepository.getSession(sessionId);
    if (session != null) {
      repairSessionRepository.saveGuidanceProgress(
        sessionId: sessionId,
        guidanceStepIndex: state.guidanceStepIndex,
        completedGuidanceStepIds: state.completedGuidanceStepIds,
        notify: false,
      );
    }
    _schedulePersist();
  }

  void clearSessionUiResume(String sessionId) {
    if (_sessionUiResumeBySessionId.remove(sessionId) != null) {
      _schedulePersist();
    }
  }

  String startOrResumeSession(Appliance appliance) {
    final current = applianceRepository.getById(appliance.id) ?? appliance;
    if (current.status != ApplianceStatus.active) {
      throw StateError(UserFacingCopy.applianceRetired);
    }

    final mappedId = _sessionIdByApplianceId[current.id];
    final existing = _openSessionForAppliance(current.id);
    if (existing != null) {
      _ensureDryerEnergyEvidence(appliance: current, session: existing);
      return existing.id;
    }
    if (mappedId != null) {
      clearSessionUiResume(mappedId);
    }

    final household = currentHousehold;
    if (household == null || household.id != current.householdId) {
      throw StateError('The appliance does not belong to the active household.');
    }

    final resolution = resolveKnowledgePackageForAppliance(
      repository: knowledgePackageRepository,
      appliance: current,
    );
    final package = resolution.basePackage;
    final session = sessionCoordinator.startSession(
      sessionId: _nextId('session'),
      householdId: household.id,
      applianceId: current.id,
      createdByUserId: currentMember?.id ?? household.ownerUserId,
      packageRef: KnowledgePackageRef.fromPackage(package),
      schemaVersion: '1.0',
      initialHistoryEntryId: _nextId('history'),
      startedAt: nextTimestamp(),
      userGoal: switch (current.category) {
        'washer' => 'Record what the washer is doing.',
        'fridge' => 'Record what the fridge is doing.',
        'dishwasher' => 'Record what the dishwasher is doing.',
        _ => 'Record what the dryer is doing.',
      },
      overlayPackageId: resolution.overlayId,
      overlayPackageVersion: resolution.overlayVersion,
      usingGeneralGuide: resolution.usingGeneralGuide,
    );
    _sessionIdByApplianceId[current.id] = session.id;

    const setupStates = [
      RepairSessionState.selectAppliance,
      RepairSessionState.problemReported,
      RepairSessionState.basicConditionVerification,
      RepairSessionState.evidenceCollection,
    ];
    for (final state in setupStates) {
      sessionCoordinator.transition(
        sessionId: session.id,
        to: state,
        historyEntryId: _nextId('history'),
        reason: 'Developer UI setup',
        triggeredBy: SessionTransitionTrigger.system,
        occurredAt: nextTimestamp(),
      );
    }

    final open = repairSessionRepository.getSession(session.id) ?? session;
    _ensureDryerEnergyEvidence(appliance: current, session: open);

    _schedulePersist();
    return session.id;
  }

  DecisionContext buildDecisionContext(String sessionId) {
    final session = repairSessionRepository.getSession(sessionId);
    final appliance =
        session == null ? null : applianceRepository.getById(session.applianceId);
    final tools = [
      for (final id in currentHousehold?.ownedToolIds ?? const <String>[])
        Tool(
          id: id,
          name: id,
          category: 'household',
          isOwnedByHousehold: true,
        ),
    ];
    final context = sessionCoordinator.buildDecisionContext(
      sessionId: sessionId,
      safetyLevel: 'not evaluated',
      userComfortLevel:
          appliance == null
              ? 'not specified'
              : repairComfort.levelFor(appliance.category).name,
      availableTools: tools,
    );
    if (appliance == null || context.package == null) {
      return context.withSafetyLevel(
        sessionSafetyLevelFor(
          evidence: context.evidence,
          primaryFailureModeId: context.primaryFailureModeId,
        ),
      );
    }
    final resolution = resolveKnowledgePackage(
      repository: knowledgePackageRepository,
      category: appliance.category,
      manufacturer: appliance.manufacturer,
      modelNumber: appliance.modelNumber,
      baseOverride: context.package,
    );
    final resolved = context.withResolvedKnowledge(
      package: resolution.package,
      authoringIndex: context.authoringIndex,
    );
    return resolved.withSafetyLevel(
      sessionSafetyLevelFor(
        evidence: resolved.evidence,
        primaryFailureModeId: resolved.primaryFailureModeId,
      ),
    );
  }

  /// Resolves the Knowledge Package already attached to [sessionId].
  ///
  /// Returns null when the session package reference cannot be loaded.
  KnowledgePackage? packageForSession(String sessionId) {
    try {
      return buildDecisionContext(sessionId).package;
    } on StateError {
      return null;
    }
  }

  SessionOutcome? outcomeForSession(String sessionId) {
    return sessionCoordinator.outcomeForSession(sessionId);
  }

  void setSessionObjective(String sessionId, SessionObjective? objective) {
    repairSessionRepository.setSessionObjective(
      sessionId: sessionId,
      objective: objective,
    );
    _schedulePersist();
  }

  /// Read-only recent completed outcomes for home-screen history.
  ///
  /// Newest first by recorded/end time. In-progress sessions are omitted.
  /// No ranking or diagnostic logic.
  List<RecentSessionOutcome> recentSessionOutcomes({int limit = 10}) {
    final items = _completedSessionOutcomes();
    if (items.length <= limit) {
      return items;
    }
    return List.unmodifiable(items.take(limit));
  }

  /// Completed terminal outcomes for the active household, newest first.
  /// In-progress sessions never appear. Fixed/verified rows are included.
  List<RecentSessionOutcome> _completedSessionOutcomes({
    String? applianceId,
  }) {
    final householdId = currentHousehold?.id;
    if (householdId == null) {
      return const [];
    }
    final items = <RecentSessionOutcome>[];
    for (final outcome in repairSessionRepository.listAllOutcomes()) {
      final session = repairSessionRepository.getSession(outcome.sessionId);
      if (session == null || !_isTerminal(session.currentState)) {
        continue;
      }
      if (applianceId != null && session.applianceId != applianceId) {
        continue;
      }
      final appliance = applianceRepository.getById(session.applianceId);
      if (appliance == null || appliance.householdId != householdId) {
        continue;
      }
      items.add(
        RecentSessionOutcome(
          outcome: outcome,
          session: session,
          appliance: appliance,
          applianceName: appliance.name,
          completedAt:
              outcome.recordedAt ?? session.endedAt ?? session.lastActivityAt,
        ),
      );
    }
    items.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.unmodifiable(items);
  }

  HouseholdImpact householdImpact() {
    return computeHouseholdImpact([
      for (final item in recentSessionOutcomes(limit: 10000))
        ImpactRepairInput(
          applianceId: item.session.applianceId,
          closeKind: item.outcome.closeKind,
          diyCostUsd: item.outcome.diyCostUsd,
          rankingLeaderFailureModeId: item.outcome.rankingLeaderFailureModeId,
        ),
    ]);
  }

  /// Local reminder stub. No push, schedule, or server.
  List<MaintenanceReminder> maintenanceRemindersForAppliance(
    String applianceId,
  ) {
    final items =
        _maintenanceReminders
            .where((item) => item.applianceId == applianceId)
            .toList()
          ..sort((a, b) {
            final byDone = a.done == b.done ? 0 : (a.done ? 1 : -1);
            if (byDone != 0) {
              return byDone;
            }
            return a.remindOn.compareTo(b.remindOn);
          });
    return List.unmodifiable(items);
  }

  /// Undone reminders, soonest due first. Overdue items stay visible.
  List<MaintenanceReminder> upcomingMaintenanceReminders({
    String? applianceId,
    int limit = 3,
  }) {
    final householdId = currentHousehold?.id;
    final items =
        _maintenanceReminders.where((item) {
            if (item.done) {
              return false;
            }
            if (householdId == null || item.householdId != householdId) {
              return false;
            }
            if (applianceId != null && item.applianceId != applianceId) {
              return false;
            }
            return true;
          }).toList()
          ..sort((a, b) => a.remindOn.compareTo(b.remindOn));
    if (items.length <= limit) {
      return List.unmodifiable(items);
    }
    return List.unmodifiable(items.take(limit));
  }

  MaintenanceReminder addMaintenanceReminder({
    required String applianceId,
    required String note,
    required DateTime remindOn,
    String? sessionId,
    bool done = false,
    int? intervalDays,
    DateTime? lastDoneAt,
  }) {
    final household = currentHousehold;
    if (household == null) {
      throw StateError('Create a household before saving a reminder.');
    }
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      throw StateError('Reminder title cannot be empty.');
    }
    final resolvedInterval =
        intervalDays ?? inferMaintenanceIntervalDays(trimmed);
    for (final existing in _maintenanceReminders) {
      if (existing.applianceId == applianceId &&
          existing.sessionId == sessionId &&
          existing.note.toLowerCase() == trimmed.toLowerCase()) {
        if (done && !existing.done) {
          setMaintenanceReminderDone(existing.id, done: true);
        }
        return existing;
      }
    }
    final today = maintenanceDateOnly(now);
    final completedOn = lastDoneAt == null
        ? (done ? today : null)
        : maintenanceDateOnly(lastDoneAt);
    final rolledDue = completedOn == null
        ? null
        : nextDueAfterDone(
            lastDoneOn: completedOn,
            intervalDays: resolvedInterval,
          );
    final reminder = MaintenanceReminder(
      id: _nextId('reminder'),
      householdId: household.id,
      applianceId: applianceId,
      note: trimmed,
      remindOn: rolledDue ?? remindOn.toUtc(),
      createdAt: nextTimestamp(),
      sessionId: sessionId,
      done: done,
      lastDoneAt: completedOn,
      intervalDays: resolvedInterval,
    );
    _maintenanceReminders.add(reminder);
    unawaited(_syncReminderNotification(reminder));
    _schedulePersist();
    return reminder;
  }

  void snoozeMaintenanceReminder(String id, {int days = 30}) {
    final index = _maintenanceReminders.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    final existing = _maintenanceReminders[index];
    final next = maintenanceDateOnly(now).add(Duration(days: days));
    final updated = existing.copyWith(remindOn: next, done: false);
    _maintenanceReminders[index] = updated;
    unawaited(_syncReminderNotification(updated));
    _schedulePersist();
  }

  List<MaintenanceReminder> dueMaintenanceReminders() {
    final householdId = currentHousehold?.id;
    final today = maintenanceDateOnly(now);
    final items = _maintenanceReminders.where((item) {
      if (item.done) {
        return false;
      }
      if (householdId == null || item.householdId != householdId) {
        return false;
      }
      return !maintenanceDateOnly(item.remindOn).isAfter(today);
    }).toList()
      ..sort((a, b) => a.remindOn.compareTo(b.remindOn));
    return List.unmodifiable(items);
  }

  Future<void> _syncReminderNotification(MaintenanceReminder reminder) async {
    if (reminder.done) {
      await maintenanceNotifier.cancel(reminder.id);
      return;
    }
    await maintenanceNotifier.schedule(reminder);
  }

  Future<void> _rescheduleAllReminderNotifications() async {
    await maintenanceNotifier.requestPermission();
    for (final reminder in _maintenanceReminders) {
      await _syncReminderNotification(reminder);
    }
  }

  List<EnrichmentNote> acceptedEnrichmentNotes({
    String? applianceId,
    String? cacheKey,
  }) {
    return [
      for (final note in _enrichmentNotes)
        if (!note.pending &&
            (applianceId == null || note.applianceId == applianceId) &&
            (cacheKey == null || note.key == cacheKey))
          note,
    ];
  }

  EnrichmentNote? enrichmentNoteForKey(String key) {
    for (final note in _enrichmentNotes.reversed) {
      if (note.key == key) {
        return note;
      }
    }
    return null;
  }

  void queueEnrichmentRequest(EnrichmentRequest request) {
    if (request.freeText.trim().isEmpty) {
      return;
    }
    final existing = enrichmentNoteForKey(request.key);
    if (existing != null) {
      return;
    }
    final pending = EnrichmentNote(
      id: _nextId('enrichment'),
      key: request.key,
      body: request.freeText.trim(),
      createdAt: nextTimestamp(),
      applianceId: request.applianceId,
      source: EnrichmentSource.household,
      pending: true,
    );
    _enrichmentNotes.add(pending);
    _schedulePersist();
    if (!kRuntimeEnrichmentCallsEnabled) {
      return;
    }
    unawaited(_runEnrichment(request, pending.id));
  }

  Future<void> _runEnrichment(EnrichmentRequest request, String noteId) async {
    try {
      final candidates = await enrichmentProvider.research(request);
      if (candidates.isEmpty) {
        return;
      }
      final index = _enrichmentNotes.indexWhere((item) => item.id == noteId);
      if (index < 0) {
        return;
      }
      _enrichmentNotes[index] = _enrichmentNotes[index].copyWith(
        body: candidates.first,
        pending: true,
      );
      _schedulePersist();
    } catch (_) {}
  }

  void acceptEnrichmentNote(String id) {
    final index = _enrichmentNotes.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    _enrichmentNotes[index] = _enrichmentNotes[index].copyWith(pending: false);
    _schedulePersist();
  }

  void setMaintenanceReminderDone(String id, {required bool done}) {
    final index = _maintenanceReminders.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    final existing = _maintenanceReminders[index];
    if (done) {
      final today = maintenanceDateOnly(now);
      final interval =
          existing.intervalDays ?? inferMaintenanceIntervalDays(existing.note);
      final rolled = nextDueAfterDone(
        lastDoneOn: today,
        intervalDays: interval,
      );
      _maintenanceReminders[index] = existing.copyWith(
        done: true,
        lastDoneAt: today,
        remindOn: rolled ?? existing.remindOn,
        intervalDays: interval,
      );
    } else {
      _maintenanceReminders[index] = existing.copyWith(
        done: false,
        clearLastDone: true,
      );
    }
    _schedulePersist();
    unawaited(_syncReminderNotification(_maintenanceReminders[index]));
  }

  /// Ends a session by advancing the remaining MVP path and recording an
  /// outcome. This performs no diagnosis; it only stores the user's result.
  SessionOutcome endSession({
    required String sessionId,
    SessionResolutionStatus? resolutionStatus,
    SessionCloseKind? closeKind,
    String? userNote,
    String? whatFixedIt,
    String? preventionNote,
    String? immediateCause,
    String? rootCause,
    List<String>? contributingFactors,
    List<String>? preventiveActions,
    double? diyCostUsd,
    String? rankingLeaderFailureModeId,
  }) {
    final kind = closeKind ??
        (resolutionStatus == null
            ? SessionCloseKind.notFixed
            : closeKindFromResolution(resolutionStatus));
    final status = resolutionStatus ?? resolutionStatusFromCloseKind(kind);

    final session = repairSessionRepository.getSession(sessionId);
    if (session == null) {
      throw StateError('Repair session "$sessionId" was not found.');
    }
    if (_isTerminal(session.currentState)) {
      throw StateError('This session is already finished.');
    }

    _advanceToPreventiveRecommendation(sessionId);

    final context = buildDecisionContext(sessionId);
    final primary = context.primaryHypothesis;

    String? rankingLeaderId =
        rankingLeaderFailureModeId ?? primary?.failureModeId;
    String? rankingLeaderLabel = primary?.label;
    if ((rankingLeaderId == null || rankingLeaderLabel == null) &&
        context.package != null) {
      final snapshot = const RankingService().evaluateContext(context);
      rankingLeaderId ??=
          snapshot.orderedFailureModes.isEmpty
              ? null
              : snapshot.orderedFailureModes.first.id;
      rankingLeaderLabel ??=
          snapshot.orderedFailureModes.isEmpty
              ? null
              : snapshot.orderedFailureModes.first.label;
    }

    final startSymptom = _startSymptomFromEvidence(context.evidence);
    final polarity = inferHeatPathPolarity(recordedEvidence: context.evidence);

    final authoring = FailureModeAuthoringRegistry.lookup(
      primary?.failureModeId ?? rankingLeaderId,
    );
    final trimmedWhatFixed = (immediateCause ?? whatFixedIt)?.trim();
    final trimmedNote = userNote?.trim();
    final trimmedPrevention = preventionNote?.trim();
    final userRoot = rootCause?.trim();
    final userContributing = contributingFactors == null
        ? null
        : [
            for (final factor in contributingFactors)
              if (factor.trim().isNotEmpty) factor.trim(),
          ];
    final userPreventive = preventiveActions == null
        ? (trimmedPrevention != null && trimmedPrevention.isNotEmpty
            ? [trimmedPrevention]
            : null)
        : [
            for (final action in preventiveActions)
              if (action.trim().isNotEmpty) action.trim(),
          ];
    // Null means the caller omitted actions — seed from the package.
    // An explicit empty list means the household declined every suggestion.
    var preventive = userPreventive ??
        authoring?.preventionActions ??
        const <String>[];
    final opportunistic =
        uiResumeForSession(sessionId)?.opportunisticAcceptedLabels ?? const [];
    if (opportunistic.isNotEmpty) {
      final seen = {
        for (final item in preventive) item.trim().toLowerCase(),
      };
      preventive = [
        ...preventive,
        for (final item in opportunistic)
          if (item.trim().isNotEmpty && seen.add(item.trim().toLowerCase()))
            item.trim(),
      ];
    }
    final recordedAt = nextTimestamp();
    final outcome = SessionOutcome(
      sessionId: sessionId,
      resolutionStatus: status,
      closeKind: kind,
      immediateCause:
          (trimmedWhatFixed != null && trimmedWhatFixed.isNotEmpty)
              ? trimmedWhatFixed
              : authoring?.immediateCause ??
                  primary?.label ??
                  rankingLeaderLabel ??
                  'No primary hypothesis was selected.',
      rootCause: rootCause != null
          ? (userRoot == null || userRoot.isEmpty ? null : userRoot)
          : authoring?.rootCause,
      contributingFactors: userContributing ??
          (authoring?.contributingFactors.isNotEmpty == true
              ? authoring!.contributingFactors
              : const []),
      preventiveActions: preventive,
      verified: status == SessionResolutionStatus.resolved,
      schemaVersion: session.schemaVersion,
      userNote: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      rankingLeaderFailureModeId: rankingLeaderId,
      rankingLeaderLabel: rankingLeaderLabel,
      startSymptom: startSymptom,
      heatPathPolarity: polarity.name,
      summary: defaultHouseholdMemorySummary(
        closeKind: kind,
        whatFixedIt: trimmedWhatFixed,
        rankingLeaderLabel: rankingLeaderLabel,
        startSymptom: startSymptom,
      ),
      recordedAt: recordedAt,
      diyCostUsd: kind == SessionCloseKind.fixed ? diyCostUsd : null,
      sessionObjective: session.sessionObjective,
      basePackageId: session.packageId,
      basePackageVersion: session.packageVersion,
      overlayPackageId: session.overlayPackageId,
      overlayPackageVersion: session.overlayPackageVersion,
      usingGeneralGuide: session.usingGeneralGuide,
    );

    final recorded = sessionCoordinator.closeSession(
      sessionId: sessionId,
      outcome: outcome,
      historyEntryId: _nextId('history'),
      reason: 'User recorded session outcome',
      occurredAt: recordedAt,
    );
    _sessionIdByApplianceId.removeWhere((_, id) => id == sessionId);
    _sessionUiResumeBySessionId.remove(sessionId);
    _schedulePersist();
    return recorded;
  }

  String? _startSymptomFromEvidence(List<Evidence> evidence) {
    for (final item in evidence) {
      if (item.templateId == problemStarterComplaintTemplateId ||
          item.templateId == washerComplaintTemplateId ||
          item.templateId == dishwasherComplaintTemplateId) {
        final answer = item.answer?.trim();
        if (answer != null && answer.isNotEmpty) {
          return answer;
        }
      }
    }
    for (final item in evidence) {
      if (item.templateId != 'heat-observed') {
        continue;
      }
      final answer = item.answer?.trim().toLowerCase();
      if (answer == 'no warmth') {
        return 'No heat';
      }
      if (answer == 'very hot') {
        return 'Too hot';
      }
    }
    return null;
  }

  /// Repair history for one appliance, newest first.
  ///
  /// Every terminal Fixed/verified outcome for this appliance is included.
  /// In-progress sessions are never listed. Empty only when this appliance
  /// has no completed outcomes.
  List<RecentSessionOutcome> repairHistoryForAppliance(
    String applianceId, {
    int limit = 20,
  }) {
    final items = _completedSessionOutcomes(applianceId: applianceId);
    if (items.length <= limit) {
      return items;
    }
    return List.unmodifiable(items.take(limit));
  }

  /// On-device repeat hint for this appliance. Null when history is too thin.
  PatternHint? patternHintForAppliance(String applianceId) {
    final prefix = '$applianceId::';
    final dismissed = <String>{};
    for (final key in _dismissedPatternHintKeys) {
      if (key.startsWith(prefix)) {
        dismissed.add(key.substring(prefix.length));
      }
    }
    return patternHintFromHistory(
      outcomes: [
        for (final item in repairHistoryForAppliance(applianceId, limit: 10000))
          item.outcome,
      ],
      reminders: maintenanceRemindersForAppliance(applianceId),
      dismissedFamilyIds: dismissed,
    );
  }

  void dismissPatternHint({
    required String applianceId,
    required String familyId,
  }) {
    _dismissedPatternHintKeys.add(
      patternHintDismissKey(applianceId, familyId),
    );
    _schedulePersist();
  }

  bool snapshotCorrupt = false;

  Future<void> restore() async {
    final store = _store;
    if (store == null) {
      return;
    }

    Map<String, OwnedToolsOverlayRecord> overlay = {};
    try {
      final snapshot = await store.load();
      overlay = await store.loadOwnedToolsOverlay();
      if (snapshot == null) {
        snapshotCorrupt = false;
        return;
      }
      applyHouseholdSnapshot(snapshot);
      snapshotCorrupt = false;
      _applyOwnedToolsOverlay(overlay);
      unawaited(_rescheduleAllReminderNotifications());
    } catch (_) {
      snapshotCorrupt = true;
      _applyOwnedToolsOverlay(overlay);
    }
  }

  /// Drops unreadable local household data. Does not use the cloud.
  Future<void> discardCorruptSnapshot() async {
    final store = _store;
    if (store != null) {
      await store.clearDomain();
      await store.clearOwnedToolsOverlay();
    }
    snapshotCorrupt = false;
  }

  /// Replaces in-memory household data. Does not rank.
  void applyHouseholdSnapshot(DomainSnapshot snapshot) {
    _idCounter = snapshot.idCounter;
    _lastTimestamp = snapshot.lastTimestamp;
    _sessionIdByApplianceId
      ..clear()
      ..addAll(snapshot.sessionIdByApplianceId);
    _sessionUiResumeBySessionId
      ..clear()
      ..addAll(snapshot.sessionUiResumeBySessionId);
    householdRepository.replaceAll(snapshot.households);
    applianceRepository.replaceAll(snapshot.appliances);
    repairSessionRepository.replacePersistedState(
      sessions: snapshot.sessions,
      evidence: snapshot.evidence,
      evidenceLinks: snapshot.evidenceLinks,
      hypotheses: snapshot.hypotheses,
      hypothesisIdsBySession: snapshot.hypothesisIdsBySession,
      outcomes: snapshot.outcomes,
    );
    sessionCoordinator.importPackageRefs(snapshot.packageRefsBySession);
    currentHousehold =
        snapshot.currentHouseholdId == null
            ? null
            : householdRepository.getById(snapshot.currentHouseholdId!);
    currentMemberId = snapshot.currentMemberId;
    _ensureHouseholdMembers();
    _maintenanceReminders
      ..clear()
      ..addAll(snapshot.maintenanceReminders);
    _enrichmentNotes
      ..clear()
      ..addAll(snapshot.enrichmentNotes);
    repairComfort = snapshot.repairComfort;
    expertMode = snapshot.expertMode;
    householdProEnabled = snapshot.householdProEnabled;
    _dismissedPatternHintKeys
      ..clear()
      ..addAll(snapshot.dismissedPatternHintKeys);
    _reconcileOpenSessionIndex();
    _rebindOpenSessionPackages();
  }

  /// Maps saved 0.1.0-era package refs onto bundled guides. Does not drop
  /// appliances, tools, or evidence.
  void _rebindOpenSessionPackages() {
    for (final session in repairSessionRepository.listAllSessions()) {
      if (_isTerminal(session.currentState)) {
        continue;
      }
      try {
        sessionCoordinator.buildDecisionContext(sessionId: session.id);
      } on StateError {
        continue;
      }
    }
  }

  String exportHouseholdBackupJson() {
    return encodeHouseholdBackup(
      _captureSnapshot(),
      exportedAt: nextTimestamp(),
    );
  }

  void restoreHouseholdBackupFromJson(String raw) {
    applyHouseholdSnapshot(decodeHouseholdBackup(raw));
    for (final household in householdRepository.listAll()) {
      _persistOwnedTools(household);
    }
    _schedulePersist();
  }

  bool _applianceInCurrentHousehold(String applianceId) {
    final householdId = currentHousehold?.id;
    if (householdId == null) {
      return false;
    }
    final appliance = applianceRepository.getById(applianceId);
    return appliance?.householdId == householdId;
  }

  RepairSession? _openSessionForAppliance(String applianceId) {
    final mappedId = _sessionIdByApplianceId[applianceId];
    if (mappedId != null) {
      final mapped = repairSessionRepository.getSession(mappedId);
      if (mapped != null &&
          mapped.applianceId == applianceId &&
          !_isTerminal(mapped.currentState)) {
        return mapped;
      }
    }

    RepairSession? newest;
    for (final session in repairSessionRepository.listAllSessions()) {
      if (session.applianceId != applianceId ||
          _isTerminal(session.currentState)) {
        continue;
      }
      if (newest == null ||
          session.lastActivityAt.isAfter(newest.lastActivityAt)) {
        newest = session;
      }
    }
    if (newest != null) {
      _sessionIdByApplianceId[applianceId] = newest.id;
    } else {
      _sessionIdByApplianceId.remove(applianceId);
    }
    return newest;
  }

  void _reconcileOpenSessionIndex() {
    final applianceIds = applianceRepository.listAll().map((item) => item.id);
    for (final applianceId in applianceIds) {
      _openSessionForAppliance(applianceId);
    }
    _sessionIdByApplianceId.removeWhere((applianceId, sessionId) {
      final session = repairSessionRepository.getSession(sessionId);
      return session == null ||
          session.applianceId != applianceId ||
          _isTerminal(session.currentState);
    });
  }

  void setRepairComfortLevel(String category, RepairComfortLevel level) {
    repairComfort = repairComfort.withLevel(category, level);
    _schedulePersist();
  }

  void setLearnPreferences(bool enabled) {
    repairComfort = repairComfort.withLearnPreferences(enabled);
    _schedulePersist();
  }

  /// Expert Mode stays off unless [adultConfirmed] is true.
  void setExpertMode({required bool enabled, required bool adultConfirmed}) {
    if (enabled && !adultConfirmed) {
      return;
    }
    expertMode = enabled;
    _schedulePersist();
  }

  void setHouseholdProEnabled(bool enabled) {
    householdProEnabled = enabled;
    _schedulePersist();
  }

  void _ensureHouseholdMembers() {
    final next = <Household>[];
    var mutated = false;
    for (final household in householdRepository.listAll()) {
      if (household.members.isNotEmpty) {
        next.add(household);
        continue;
      }
      mutated = true;
      next.add(_householdWithDefaultMember(household));
    }
    if (mutated) {
      householdRepository.replaceAll(next);
    }
    final currentId = currentHousehold?.id;
    if (currentId != null) {
      currentHousehold = householdRepository.getById(currentId);
    }
    final beforeMember = currentMemberId;
    _syncCurrentMemberId();
    if (mutated || beforeMember != currentMemberId) {
      _schedulePersist();
    }
  }

  Household _householdWithDefaultMember(Household household) {
    final ownerId = household.ownerUserId.trim().isEmpty
        ? '${household.id}-you'
        : household.ownerUserId;
    return household.copyWith(
      members: [
        HouseholdMember(
          id: ownerId,
          householdId: household.id,
          displayName: defaultHouseholdMemberDisplayName,
          createdAt: household.createdAt,
        ),
      ],
    );
  }

  void _syncCurrentMemberId() {
    final household = currentHousehold;
    if (household == null || household.members.isEmpty) {
      currentMemberId = null;
      return;
    }
    final ids = {for (final member in household.members) member.id};
    if (currentMemberId == null || !ids.contains(currentMemberId)) {
      currentMemberId = household.members.first.id;
    }
  }

  DomainSnapshot _captureSnapshot() {
    return DomainSnapshot(
      idCounter: _idCounter,
      lastTimestamp: _lastTimestamp,
      currentHouseholdId: currentHousehold?.id,
      currentMemberId: currentMemberId,
      sessionIdByApplianceId: Map<String, String>.from(_sessionIdByApplianceId),
      packageRefsBySession: sessionCoordinator.exportPackageRefs(),
      households: householdRepository.listAll(),
      appliances: applianceRepository.listAll(),
      sessions: repairSessionRepository.listAllSessions(),
      evidence: repairSessionRepository.listAllEvidence(),
      evidenceLinks: repairSessionRepository.listAllEvidenceLinks(),
      hypotheses: repairSessionRepository.listAllHypotheses(),
      hypothesisIdsBySession: repairSessionRepository.hypothesisIdsBySession(),
      outcomes: repairSessionRepository.listAllOutcomes(),
      sessionUiResumeBySessionId: Map<String, SessionUiResumeState>.from(
        _sessionUiResumeBySessionId,
      ),
      maintenanceReminders: List<MaintenanceReminder>.from(
        _maintenanceReminders,
      ),
      enrichmentNotes: List<EnrichmentNote>.from(_enrichmentNotes),
      repairComfort: repairComfort,
      expertMode: expertMode,
      householdProEnabled: householdProEnabled,
      dismissedPatternHintKeys: List<String>.from(_dismissedPatternHintKeys),
    );
  }

  void _persistOwnedTools(Household household) {
    final store = _store;
    if (store == null) {
      return;
    }
    final householdId = household.id;
    _schedulePersist();
    _toolsPersistChain = (_toolsPersistChain ?? Future<void>.value())
        .then((_) async {
          final latest = householdRepository.getById(householdId);
          await store.saveOwnedToolIds(
            householdId,
            List<String>.from(latest?.ownedToolIds ?? household.ownedToolIds),
            generation:
                latest?.ownedToolsGeneration ?? household.ownedToolsGeneration,
          );
        })
        .catchError((_) {});
  }

  void _applyOwnedToolsOverlay(Map<String, OwnedToolsOverlayRecord> overlay) {
    if (overlay.isEmpty) {
      return;
    }
    householdRepository.replaceAll([
      for (final household in householdRepository.listAll())
        _householdWithNewerOwnedTools(household, overlay[household.id]),
    ]);
    final currentId = currentHousehold?.id;
    if (currentId != null) {
      currentHousehold = householdRepository.getById(currentId);
    }
    _syncCurrentMemberId();
  }

  Household _householdWithNewerOwnedTools(
    Household household,
    OwnedToolsOverlayRecord? overlay,
  ) {
    if (overlay == null) {
      return household;
    }
    if (overlay.generation < household.ownedToolsGeneration) {
      return household;
    }
    return household.copyWith(
      ownedToolIds: List<String>.from(overlay.ids),
      ownedToolsGeneration: overlay.generation,
    );
  }

  void _schedulePersist() {
    final store = _store;
    if (store == null) {
      return;
    }

    _persistChain = (_persistChain ?? Future<void>.value())
        .then((_) async {
          final snapshot = _captureSnapshot();
          await store.save(snapshot);
          for (final household in snapshot.households) {
            await store.saveOwnedToolIds(
              household.id,
              List<String>.from(household.ownedToolIds),
              generation: household.ownedToolsGeneration,
            );
          }
        })
        .catchError((_) {});
  }

  /// Waits for any queued local snapshot write to finish.
  Future<void> flushPersist() async {
    await Future.wait([
      _persistChain ?? Future<void>.value(),
      _toolsPersistChain ?? Future<void>.value(),
    ]);
  }

  void _advanceToPreventiveRecommendation(String sessionId) {
    const closingPath = [
      RepairSessionState.hypothesisBuilding,
      RepairSessionState.riskCheck,
      RepairSessionState.safeGuidance,
      RepairSessionState.verification,
      RepairSessionState.rootCauseAnalysis,
      RepairSessionState.preventiveRecommendation,
    ];

    for (final state in closingPath) {
      final current = repairSessionRepository.getSession(sessionId);
      if (current == null) {
        throw StateError('Repair session "$sessionId" was not found.');
      }
      if (current.currentState == state ||
          current.currentState == RepairSessionState.preventiveRecommendation) {
        continue;
      }
      if (!repairSessionRepository.canTransition(
        from: current.currentState,
        to: state,
        triggeredBy: SessionTransitionTrigger.system,
      )) {
        continue;
      }
      sessionCoordinator.transition(
        sessionId: sessionId,
        to: state,
        historyEntryId: _nextId('history'),
        reason: 'Developer UI closing path',
        triggeredBy: SessionTransitionTrigger.system,
        occurredAt: nextTimestamp(),
      );
    }

    final ready = repairSessionRepository.getSession(sessionId);
    if (ready == null ||
        ready.currentState != RepairSessionState.preventiveRecommendation) {
      throw StateError(
        'Session must reach preventive recommendation before closing.',
      );
    }
  }

  DateTime nextTimestamp() {
    final candidate = _clock().toUtc();
    if (!candidate.isAfter(_lastTimestamp)) {
      _lastTimestamp = _lastTimestamp.add(const Duration(milliseconds: 1));
    } else {
      _lastTimestamp = candidate;
    }
    return _lastTimestamp;
  }

  String nextId(String prefix) => _nextId(prefix);

  String _nextId(String prefix) {
    _idCounter += 1;
    return '$prefix-$_idCounter';
  }

  bool _isTerminal(RepairSessionState state) {
    return state == RepairSessionState.sessionClosed ||
        state == RepairSessionState.escalated ||
        state == RepairSessionState.abandoned ||
        state == RepairSessionState.error;
  }
}

/// In-progress repair: identity, evidence so far, and current step.
class ActiveSessionSnapshot {
  const ActiveSessionSnapshot({
    required this.sessionId,
    required this.applianceId,
    required this.currentState,
    required this.evidence,
    this.uiResume,
  });

  final String sessionId;
  final String applianceId;
  final RepairSessionState currentState;
  final List<Evidence> evidence;
  final SessionUiResumeState? uiResume;
}

/// Read-only home-screen row for one completed session outcome.
class RecentSessionOutcome {
  const RecentSessionOutcome({
    required this.outcome,
    required this.session,
    required this.appliance,
    required this.applianceName,
    required this.completedAt,
  });

  final SessionOutcome outcome;
  final RepairSession session;
  final Appliance? appliance;
  final String applianceName;
  final DateTime completedAt;
}
