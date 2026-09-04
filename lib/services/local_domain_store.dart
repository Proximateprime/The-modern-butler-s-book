import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/user_facing_error.dart';
import '../models/enrichment_note.dart';
import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/hypothesis.dart';
import '../models/knowledge_package_ref.dart';
import '../models/maintenance_reminder.dart';
import '../models/repair_comfort_profile.dart';
import '../models/repair_session.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import '../models/session_ui_resume_state.dart';

/// Thin local JSON snapshot store backed by SharedPreferences.
///
/// No cloud, sync, or Supabase. This only survives local reloads/refreshes.
class LocalDomainStore {
  LocalDomainStore({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _storageKey = 'modern_butler_domain_v1';
  static const ownedToolsOverlayKey = 'modern_butler_owned_tools_v1';
  static const firstRunCompleteKey = 'modern_butler_first_run_complete_v1';
  static const disclaimerAcknowledgedKey =
      'modern_butler_disclaimer_acknowledged_v1';
  static const themeChoiceKey = 'modern_butler_theme_choice_v1';
  static const lastLightThemeKey = 'modern_butler_last_light_theme_v1';

  SharedPreferences? _preferences;

  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<DomainSnapshot?> load() async {
    await init();
    final raw = _preferences!.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const CorruptSnapshotException();
      }
      return DomainSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    } on CorruptSnapshotException {
      rethrow;
    } catch (_) {
      throw const CorruptSnapshotException();
    }
  }

  Future<void> clearDomain() async {
    await init();
    await _preferences!.remove(_storageKey);
  }

  Future<void> save(DomainSnapshot snapshot) async {
    await init();
    await _preferences!.setString(
      _storageKey,
      jsonEncode(snapshot.toJson()),
    );
  }

  /// Fast household-tool list, separate from the full domain snapshot.
  Future<void> saveOwnedToolIds(
    String householdId,
    List<String> ids, {
    int generation = 0,
  }) async {
    await init();
    final overlay = await loadOwnedToolsOverlay();
    final existing = overlay[householdId];
    if (existing != null && existing.generation > generation) {
      return;
    }
    overlay[householdId] = OwnedToolsOverlayRecord(
      ids: List<String>.from(ids),
      generation: generation,
    );
    await _preferences!.setString(
      ownedToolsOverlayKey,
      jsonEncode({
        for (final entry in overlay.entries)
          entry.key: {
            'ids': entry.value.ids,
            'generation': entry.value.generation,
          },
      }),
    );
  }

  Future<Map<String, OwnedToolsOverlayRecord>> loadOwnedToolsOverlay() async {
    await init();
    final raw = _preferences!.getString(ownedToolsOverlayKey);
    if (raw == null || raw.isEmpty) {
      return <String, OwnedToolsOverlayRecord>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, OwnedToolsOverlayRecord>{};
      }
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): _ownedToolsOverlayRecordFromJson(entry.value),
      };
    } catch (_) {
      return <String, OwnedToolsOverlayRecord>{};
    }
  }

  Future<void> clearOwnedToolsOverlay() async {
    await init();
    await _preferences!.remove(ownedToolsOverlayKey);
  }

  Future<bool> loadFirstRunComplete() async {
    await init();
    return _preferences!.getBool(firstRunCompleteKey) ?? false;
  }

  Future<void> saveFirstRunComplete() async {
    await init();
    await _preferences!.setBool(firstRunCompleteKey, true);
  }

  Future<void> clearFirstRunComplete() async {
    await init();
    await _preferences!.remove(firstRunCompleteKey);
  }

  Future<bool> loadDisclaimerAcknowledged() async {
    await init();
    return _preferences!.getBool(disclaimerAcknowledgedKey) ?? false;
  }

  Future<void> saveDisclaimerAcknowledged() async {
    await init();
    await _preferences!.setBool(disclaimerAcknowledgedKey, true);
  }

  Future<String?> loadThemeChoice() async {
    await init();
    return _preferences!.getString(themeChoiceKey);
  }

  Future<void> saveThemeChoice(String value) async {
    await init();
    await _preferences!.setString(themeChoiceKey, value);
  }

  Future<String?> loadLastLightTheme() async {
    await init();
    return _preferences!.getString(lastLightThemeKey);
  }

  Future<void> saveLastLightTheme(String value) async {
    await init();
    await _preferences!.setString(lastLightThemeKey, value);
  }

  static const wrongReportsKey = 'modern_butler_wrong_reports_v1';

  Future<List<Map<String, dynamic>>> loadWrongReports() async {
    await init();
    final raw = _preferences!.getString(wrongReportsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final item in decoded)
          if (item is Map)
            Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveWrongReports(List<Map<String, dynamic>> reports) async {
    await init();
    await _preferences!.setString(wrongReportsKey, jsonEncode(reports));
  }
}

/// Serializable domain state for local persistence only.
class DomainSnapshot {
  const DomainSnapshot({
    required this.idCounter,
    required this.lastTimestamp,
    required this.currentHouseholdId,
    this.currentMemberId,
    required this.sessionIdByApplianceId,
    required this.packageRefsBySession,
    required this.households,
    required this.appliances,
    required this.sessions,
    required this.evidence,
    required this.evidenceLinks,
    required this.hypotheses,
    required this.hypothesisIdsBySession,
    required this.outcomes,
    this.sessionUiResumeBySessionId = const {},
    this.foregroundSessionId,
    this.maintenanceReminders = const [],
    this.repairComfort = const RepairComfortProfile(),
    this.expertMode = false,
    this.householdProEnabled = false,
    this.dismissedPatternHintKeys = const [],
    this.enrichmentNotes = const [],
  });

  final int idCounter;
  final DateTime lastTimestamp;
  final String? currentHouseholdId;
  final String? currentMemberId;
  final Map<String, String> sessionIdByApplianceId;
  final Map<String, KnowledgePackageRef> packageRefsBySession;
  final List<Household> households;
  final List<Appliance> appliances;
  final List<RepairSession> sessions;
  final List<Evidence> evidence;
  final List<SessionEvidenceLink> evidenceLinks;
  final List<Hypothesis> hypotheses;
  final Map<String, List<String>> hypothesisIdsBySession;
  final List<SessionOutcome> outcomes;
  final Map<String, SessionUiResumeState> sessionUiResumeBySessionId;

  /// Session the user was looking at when the app last backgrounded.
  ///
  /// Null after they leave SessionScreen (Exit / back). Used to reopen that
  /// repair after a lock/kill, not to invent a new session.
  final String? foregroundSessionId;
  final List<MaintenanceReminder> maintenanceReminders;
  final RepairComfortProfile repairComfort;
  final bool expertMode;
  final bool householdProEnabled;
  final List<String> dismissedPatternHintKeys;
  final List<EnrichmentNote> enrichmentNotes;

  Map<String, dynamic> toJson() {
    return {
      'idCounter': idCounter,
      'lastTimestamp': lastTimestamp.toIso8601String(),
      'currentHouseholdId': currentHouseholdId,
      'currentMemberId': currentMemberId,
      'sessionIdByApplianceId': sessionIdByApplianceId,
      'packageRefsBySession': packageRefsBySession.map(
        (key, value) => MapEntry(key, _packageRefToJson(value)),
      ),
      'households': households.map(_householdToJson).toList(),
      'appliances': appliances.map(_applianceToJson).toList(),
      'sessions': sessions.map(_sessionToJson).toList(),
      'evidence': evidence.map(_evidenceToJson).toList(),
      'evidenceLinks': evidenceLinks.map(_evidenceLinkToJson).toList(),
      'hypotheses': hypotheses.map(_hypothesisToJson).toList(),
      'hypothesisIdsBySession': {
        for (final entry in hypothesisIdsBySession.entries)
          entry.key: List<String>.from(entry.value),
      },
      'outcomes': outcomes.map(_outcomeToJson).toList(),
      'sessionUiResumeBySessionId': sessionUiResumeBySessionId.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      if (foregroundSessionId != null)
        'foregroundSessionId': foregroundSessionId,
      'maintenanceReminders': maintenanceReminders
          .map((item) => item.toJson())
          .toList(),
      'repairComfort': repairComfort.toJson(),
      'expertMode': expertMode,
      'householdProEnabled': householdProEnabled,
      'dismissedPatternHintKeys': List<String>.from(dismissedPatternHintKeys),
      'enrichmentNotes': enrichmentNotes.map((item) => item.toJson()).toList(),
    };
  }

  factory DomainSnapshot.fromJson(Map<String, dynamic> json) {
    final resumeRaw =
        json['sessionUiResumeBySessionId'] as Map? ?? const {};
    return DomainSnapshot(
      idCounter: json['idCounter'] as int? ?? 0,
      lastTimestamp: DateTime.parse(json['lastTimestamp'] as String),
      currentHouseholdId: json['currentHouseholdId'] as String?,
      currentMemberId: json['currentMemberId'] as String?,
      sessionIdByApplianceId: Map<String, String>.from(
        json['sessionIdByApplianceId'] as Map? ?? const {},
      ),
      packageRefsBySession: (json['packageRefsBySession'] as Map? ?? const {}).map(
        (key, value) => MapEntry(
          key as String,
          _packageRefFromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      households: List<dynamic>.from(json['households'] as List? ?? const [])
          .map(
            (item) =>
                _householdFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      appliances: List<dynamic>.from(json['appliances'] as List? ?? const [])
          .map(
            (item) =>
                _applianceFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      sessions: List<dynamic>.from(json['sessions'] as List? ?? const [])
          .map(
            (item) =>
                _sessionFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      evidence: List<dynamic>.from(json['evidence'] as List? ?? const [])
          .map(
            (item) =>
                _evidenceFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      evidenceLinks: List<dynamic>.from(
        json['evidenceLinks'] as List? ?? const [],
      )
          .map(
            (item) => _evidenceLinkFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      hypotheses: List<dynamic>.from(json['hypotheses'] as List? ?? const [])
          .map(
            (item) =>
                _hypothesisFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      hypothesisIdsBySession: {
        for (final entry
            in (json['hypothesisIdsBySession'] as Map? ?? const {}).entries)
          entry.key as String: List<String>.from(
            entry.value as List? ?? const [],
          ),
      },
      outcomes: List<dynamic>.from(json['outcomes'] as List? ?? const [])
          .map(
            (item) =>
                _outcomeFromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      sessionUiResumeBySessionId: resumeRaw.map(
        (key, value) => MapEntry(
          key as String,
          SessionUiResumeState.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      ),
      foregroundSessionId: json['foregroundSessionId'] as String?,
      maintenanceReminders: List<dynamic>.from(
        json['maintenanceReminders'] as List? ?? const [],
      )
          .map(
            (item) => MaintenanceReminder.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      repairComfort: RepairComfortProfile.fromJson(
        json['repairComfort'] is Map
            ? Map<String, dynamic>.from(json['repairComfort'] as Map)
            : null,
      ),
      expertMode: json['expertMode'] as bool? ?? false,
      householdProEnabled: json['householdProEnabled'] as bool? ?? false,
      dismissedPatternHintKeys: List<String>.from(
        json['dismissedPatternHintKeys'] as List? ?? const [],
      ),
      enrichmentNotes: List<dynamic>.from(
        json['enrichmentNotes'] as List? ?? const [],
      )
          .map(
            (item) => EnrichmentNote.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

Map<String, dynamic> _packageRefToJson(KnowledgePackageRef value) {
  return {
    'id': value.id,
    'applianceCategory': value.applianceCategory,
    'version': value.version,
    'displayName': value.displayName,
  };
}

KnowledgePackageRef _packageRefFromJson(Map<String, dynamic> json) {
  return KnowledgePackageRef(
    id: json['id'] as String,
    applianceCategory: json['applianceCategory'] as String,
    version: json['version'] as String,
    displayName: json['displayName'] as String,
  );
}

Map<String, dynamic> _householdToJson(Household value) {
  return {
    'id': value.id,
    'name': value.name,
    'ownerUserId': value.ownerUserId,
    'createdAt': value.createdAt.toIso8601String(),
    'schemaVersion': value.schemaVersion,
    'ownedToolIds': List<String>.from(value.ownedToolIds),
    'ownedToolsGeneration': value.ownedToolsGeneration,
    'members': value.members.map(_memberToJson).toList(),
  };
}

Map<String, dynamic> _memberToJson(HouseholdMember value) {
  return {
    'id': value.id,
    'householdId': value.householdId,
    'displayName': value.displayName,
    'createdAt': value.createdAt.toIso8601String(),
  };
}

Household _householdFromJson(Map<String, dynamic> json) {
  return Household(
    id: json['id'] as String,
    name: json['name'] as String,
    ownerUserId: json['ownerUserId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    schemaVersion: json['schemaVersion'] as String,
    ownedToolIds: List<String>.from(json['ownedToolIds'] as List? ?? const []),
    ownedToolsGeneration: json['ownedToolsGeneration'] as int? ?? 0,
    members: List<dynamic>.from(json['members'] as List? ?? const [])
        .map(
          (item) => _memberFromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
  );
}

HouseholdMember _memberFromJson(Map<String, dynamic> json) {
  return HouseholdMember(
    id: json['id'] as String,
    householdId: json['householdId'] as String,
    displayName: json['displayName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, dynamic> _applianceToJson(Appliance value) {
  return {
    'id': value.id,
    'householdId': value.householdId,
    'name': value.name,
    'category': value.category,
    'manufacturer': value.manufacturer,
    'modelNumber': value.modelNumber,
    'serialNumber': value.serialNumber,
    'location': value.location,
    'status': value.status.name,
    'installationDate': value.installationDate?.toIso8601String(),
    'estimatedAgeYears': value.estimatedAgeYears,
    if (value.ratingLabelPhotoPath != null)
      'ratingLabelPhotoPath': value.ratingLabelPhotoPath,
    'energySource': value.energySource.name,
    'washerLoadStyle': value.washerLoadStyle.name,
    'schemaVersion': value.schemaVersion,
    'createdAt': value.createdAt.toIso8601String(),
    'updatedAt': value.updatedAt.toIso8601String(),
  };
}

Appliance _applianceFromJson(Map<String, dynamic> json) {
  return Appliance(
    id: json['id'] as String,
    householdId: json['householdId'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    manufacturer: json['manufacturer'] as String,
    modelNumber: json['modelNumber'] as String,
    serialNumber: json['serialNumber'] as String?,
    location: json['location'] as String,
    status: applianceStatusFromName(json['status'] as String?),
    installationDate:
        json['installationDate'] == null
            ? null
            : DateTime.parse(json['installationDate'] as String),
    estimatedAgeYears: json['estimatedAgeYears'] as int?,
    ratingLabelPhotoPath: json['ratingLabelPhotoPath'] as String?,
    energySource: applianceEnergySourceFromName(json['energySource'] as String?),
    washerLoadStyle: washerLoadStyleFromName(json['washerLoadStyle'] as String?),
    schemaVersion: json['schemaVersion'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _historyToJson(SessionStateHistory value) {
  return {
    'id': value.id,
    'sessionId': value.sessionId,
    'state': value.state.name,
    'enteredAt': value.enteredAt.toIso8601String(),
    'exitedAt': value.exitedAt?.toIso8601String(),
    'reasonForTransition': value.reasonForTransition,
    'triggeredBy': value.triggeredBy.name,
  };
}

SessionStateHistory _historyFromJson(Map<String, dynamic> json) {
  return SessionStateHistory(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    state: RepairSessionState.values.byName(json['state'] as String),
    enteredAt: DateTime.parse(json['enteredAt'] as String),
    exitedAt:
        json['exitedAt'] == null
            ? null
            : DateTime.parse(json['exitedAt'] as String),
    reasonForTransition: json['reasonForTransition'] as String,
    triggeredBy: SessionTransitionTrigger.values.byName(
      json['triggeredBy'] as String,
    ),
  );
}

Map<String, dynamic> _sessionToJson(RepairSession value) {
  return {
    'id': value.id,
    'applianceId': value.applianceId,
    'householdId': value.householdId,
    'currentState': value.currentState.name,
    'startedAt': value.startedAt.toIso8601String(),
    'lastActivityAt': value.lastActivityAt.toIso8601String(),
    'endedAt': value.endedAt?.toIso8601String(),
    'resolutionStatus': value.resolutionStatus?.name,
    'userGoal': value.userGoal,
    'sessionObjective': value.sessionObjective?.name,
    'createdByUserId': value.createdByUserId,
    'packageId': value.packageId,
    'packageVersion': value.packageVersion,
    'schemaVersion': value.schemaVersion,
    'overlayPackageId': value.overlayPackageId,
    'overlayPackageVersion': value.overlayPackageVersion,
    'usingGeneralGuide': value.usingGeneralGuide,
    'guidanceStepIndex': value.guidanceStepIndex,
    'completedGuidanceStepIds': value.completedGuidanceStepIds,
    'stateHistory': value.stateHistory.map(_historyToJson).toList(),
  };
}

RepairSession _sessionFromJson(Map<String, dynamic> json) {
  return RepairSession(
    id: json['id'] as String,
    applianceId: json['applianceId'] as String,
    householdId: json['householdId'] as String,
    currentState: RepairSessionState.values.byName(
      json['currentState'] as String,
    ),
    startedAt: DateTime.parse(json['startedAt'] as String),
    lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
    endedAt:
        json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt'] as String),
    resolutionStatus:
        json['resolutionStatus'] == null
            ? null
            : SessionResolutionStatus.values.byName(
              json['resolutionStatus'] as String,
            ),
    userGoal: json['userGoal'] as String?,
    sessionObjective: sessionObjectiveFromName(
      json['sessionObjective'] as String?,
    ),
    createdByUserId: json['createdByUserId'] as String,
    packageId: json['packageId'] as String,
    packageVersion: json['packageVersion'] as String,
    schemaVersion: json['schemaVersion'] as String,
    overlayPackageId: json['overlayPackageId'] as String?,
    overlayPackageVersion: json['overlayPackageVersion'] as String?,
    usingGeneralGuide: json['usingGeneralGuide'] as bool? ?? true,
    guidanceStepIndex: json['guidanceStepIndex'] as int? ?? 0,
    completedGuidanceStepIds: List<String>.from(
      json['completedGuidanceStepIds'] as List? ?? const [],
    ),
    stateHistory:
        (json['stateHistory'] as List)
            .map(
              (item) =>
                  _historyFromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
  );
}

Map<String, dynamic> _evidenceToJson(Evidence value) {
  return {
    'id': value.id,
    'sessionId': value.sessionId,
    'applianceId': value.applianceId,
    'type': value.type.name,
    'observation': value.observation,
    'answer': value.answer,
    'templateId': value.templateId,
    'collectedAt': value.collectedAt.toIso8601String(),
    'collectedInState': value.collectedInState.name,
    'source': value.source.name,
    'schemaVersion': value.schemaVersion,
    'confidenceContribution': value.confidenceContribution,
    if (value.localPhotoPath != null) 'localPhotoPath': value.localPhotoPath,
  };
}

Evidence _evidenceFromJson(Map<String, dynamic> json) {
  return Evidence(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    applianceId: json['applianceId'] as String,
    type: EvidenceType.values.byName(json['type'] as String),
    observation: json['observation'] as String,
    answer: json['answer'] as String?,
    templateId: json['templateId'] as String?,
    collectedAt: DateTime.parse(json['collectedAt'] as String),
    collectedInState: RepairSessionState.values.byName(
      json['collectedInState'] as String,
    ),
    source: EvidenceSource.values.byName(json['source'] as String),
    schemaVersion: json['schemaVersion'] as String,
    confidenceContribution: (json['confidenceContribution'] as num?)?.toDouble(),
    localPhotoPath: json['localPhotoPath'] as String?,
  );
}

Map<String, dynamic> _evidenceLinkToJson(SessionEvidenceLink value) {
  return {
    'id': value.id,
    'sessionId': value.sessionId,
    'evidenceId': value.evidenceId,
    'addedAt': value.addedAt.toIso8601String(),
    'sourceState': value.sourceState.name,
  };
}

SessionEvidenceLink _evidenceLinkFromJson(Map<String, dynamic> json) {
  return SessionEvidenceLink(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    evidenceId: json['evidenceId'] as String,
    addedAt: DateTime.parse(json['addedAt'] as String),
    sourceState: RepairSessionState.values.byName(json['sourceState'] as String),
  );
}

Map<String, dynamic> _hypothesisToJson(Hypothesis value) {
  return {
    'id': value.id,
    'sessionId': value.sessionId,
    'failureModeId': value.failureModeId,
    'label': value.label,
    'currentConfidence': value.currentConfidence,
    'status': value.status.name,
    'schemaVersion': value.schemaVersion,
  };
}

Hypothesis _hypothesisFromJson(Map<String, dynamic> json) {
  return Hypothesis(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    failureModeId: json['failureModeId'] as String,
    label: json['label'] as String,
    currentConfidence: (json['currentConfidence'] as num).toDouble(),
    status: HypothesisStatus.values.byName(json['status'] as String),
    schemaVersion: json['schemaVersion'] as String,
  );
}

Map<String, dynamic> _outcomeToJson(SessionOutcome value) {
  return {
    'sessionId': value.sessionId,
    'resolutionStatus': value.resolutionStatus.name,
    'closeKind': value.closeKind.name,
    'immediateCause': value.immediateCause,
    'rootCause': value.rootCause,
    'contributingFactors': value.contributingFactors,
    'preventiveActions': value.preventiveActions,
    'verified': value.verified,
    'schemaVersion': value.schemaVersion,
    'userNote': value.userNote,
    'rankingLeaderFailureModeId': value.rankingLeaderFailureModeId,
    'rankingLeaderLabel': value.rankingLeaderLabel,
    'startSymptom': value.startSymptom,
    'heatPathPolarity': value.heatPathPolarity,
    'summary': value.summary,
    'recordedAt': value.recordedAt?.toIso8601String(),
    'diyCostUsd': value.diyCostUsd,
    'sessionObjective': value.sessionObjective?.name,
    'basePackageId': value.basePackageId,
    'basePackageVersion': value.basePackageVersion,
    'overlayPackageId': value.overlayPackageId,
    'overlayPackageVersion': value.overlayPackageVersion,
    'usingGeneralGuide': value.usingGeneralGuide,
  };
}

SessionOutcome _outcomeFromJson(Map<String, dynamic> json) {
  return SessionOutcome(
    sessionId: json['sessionId'] as String,
    resolutionStatus: SessionResolutionStatus.values.byName(
      json['resolutionStatus'] as String,
    ),
    closeKind: json['closeKind'] is String
        ? SessionCloseKind.values.byName(json['closeKind'] as String)
        : null,
    immediateCause: json['immediateCause'] as String,
    rootCause: json['rootCause'] as String?,
    contributingFactors: List<String>.from(
      json['contributingFactors'] as List? ?? const [],
    ),
    preventiveActions: List<String>.from(
      json['preventiveActions'] as List? ?? const [],
    ),
    verified: json['verified'] as bool? ?? false,
    schemaVersion: json['schemaVersion'] as String,
    userNote: json['userNote'] as String?,
    rankingLeaderFailureModeId: json['rankingLeaderFailureModeId'] as String?,
    rankingLeaderLabel: json['rankingLeaderLabel'] as String?,
    startSymptom: json['startSymptom'] as String?,
    heatPathPolarity: json['heatPathPolarity'] as String?,
    summary: json['summary'] as String?,
    recordedAt: json['recordedAt'] is String
        ? DateTime.parse(json['recordedAt'] as String)
        : null,
    diyCostUsd: _diyCostFromJson(json['diyCostUsd']),
    sessionObjective: sessionObjectiveFromName(
      json['sessionObjective'] as String?,
    ),
    basePackageId: json['basePackageId'] as String?,
    basePackageVersion: json['basePackageVersion'] as String?,
    overlayPackageId: json['overlayPackageId'] as String?,
    overlayPackageVersion: json['overlayPackageVersion'] as String?,
    usingGeneralGuide: json['usingGeneralGuide'] as bool?,
  );
}

double? _diyCostFromJson(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return null;
}

/// Fast tools overlay. Generation ignores a stale empty list after a newer add.
class OwnedToolsOverlayRecord {
  const OwnedToolsOverlayRecord({
    required this.ids,
    required this.generation,
  });

  final List<String> ids;
  final int generation;
}

OwnedToolsOverlayRecord _ownedToolsOverlayRecordFromJson(Object? raw) {
  if (raw is List) {
    return OwnedToolsOverlayRecord(
      ids: List<String>.from(raw),
      generation: 0,
    );
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return OwnedToolsOverlayRecord(
      ids: List<String>.from(map['ids'] as List? ?? const []),
      generation: map['generation'] as int? ?? 0,
    );
  }
  return const OwnedToolsOverlayRecord(ids: [], generation: 0);
}
