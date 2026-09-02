import '../helpers/easy_airflow_checks.dart';
import '../helpers/package_authoring_index.dart';
import '../knowledge_factory/dryer_batch_01.dart';
import '../knowledge_factory/dryer_batch_02.dart';
import '../knowledge_factory/failure_mode_authoring_record.dart';
import '../knowledge_factory/failure_mode_batch_importer.dart';
import '../knowledge_factory/dryer_inspect_steps.dart';
import '../knowledge_factory/washer_mvp_v01.dart';
import '../knowledge_factory/fridge_mvp_v01.dart';
import '../knowledge_factory/dishwasher_mvp_v01.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../models/knowledge_package_ref.dart';

/// In-memory catalog of immutable Knowledge Packages.
///
/// This repository performs no file loading, network access, graph traversal,
/// diagnosis, ranking, or question selection.
class KnowledgePackageRepository {
  KnowledgePackageRepository({List<KnowledgePackage>? initialPackages}) {
    if (initialPackages != null) {
      for (final package in initialPackages) {
        if (_packagesById.containsKey(package.id)) {
          throw StateError(
            'Knowledge package with id "${package.id}" already exists.',
          );
        }
        _registerPackage(package.id, package);
      }
      return;
    }
    _seedDryerPackage();
    _seedWasherPackage();
    _seedFridgePackage();
    _seedDishwasherPackage();
  }

  final Map<String, KnowledgePackage> _packagesById = {};
  final Map<String, List<String>> _authoringIdsByPackageId = {};
  final Map<String, PackageAuthoringIndex> _authoringIndexByPackageId = {};

  KnowledgePackage? installBundledCategory(String category) {
    final existing = loadByCategory(category);
    if (existing.isNotEmpty) {
      return existing.first;
    }
    switch (category) {
      case 'dryer':
        return _seedDryerPackage();
      case 'washer':
        return _seedWasherPackage();
      case 'fridge':
        return _seedFridgePackage();
      case 'dishwasher':
        return _seedDishwasherPackage();
      default:
        return null;
    }
  }

  bool get isEmpty => _packagesById.isEmpty;

  KnowledgePackage? loadById(String id) => _packagesById[id];

  /// Runtime Batch 01/02 authoring index for ranking and interview preference.
  PackageAuthoringIndex? authoringIndexFor(String packageId) {
    return _authoringIndexByPackageId[packageId];
  }

  List<KnowledgePackage> loadByCategory(String category) {
    return List.unmodifiable(
      _packagesById.values.where((package) => package.category == category),
    );
  }

  List<KnowledgePackage> listAvailable() {
    return List.unmodifiable(_packagesById.values);
  }

  KnowledgePackage? loadByRef(KnowledgePackageRef reference) {
    final package = loadById(reference.id);
    if (package == null ||
        package.category != reference.applianceCategory ||
        package.version != reference.version) {
      return null;
    }
    return package;
  }

  /// Resume-safe resolve: exact ref, then same id after a version bump, then
  /// a known family alias. Does not invent a guide when the catalog is empty.
  KnowledgePackage? resolveCompatible(KnowledgePackageRef reference) {
    final exact = loadByRef(reference);
    if (exact != null) {
      return exact;
    }
    final aliasedId = _canonicalPackageId(reference.id);
    final byId = loadById(aliasedId) ?? loadById(reference.id);
    if (byId != null &&
        (byId.category == reference.applianceCategory ||
            reference.applianceCategory.trim().isEmpty)) {
      return byId;
    }
    return null;
  }

  /// Like [resolveCompatible], then the bundled package for the appliance
  /// family so an upgraded app can resume a 0.1.0 session. Empty catalog → null.
  KnowledgePackage? resolveForResume(
    KnowledgePackageRef reference, {
    String? applianceCategory,
  }) {
    final compatible = resolveCompatible(reference);
    if (compatible != null) {
      return compatible;
    }
    final category =
        (applianceCategory ?? reference.applianceCategory).trim();
    if (category.isEmpty) {
      return null;
    }
    final byCategory = loadByCategory(category);
    if (byCategory.isNotEmpty) {
      return byCategory.first;
    }
    return null;
  }

  static String _canonicalPackageId(String id) {
    return switch (id.trim()) {
      'dryer' || 'dryer-v1' => 'dryer-core',
      'washer' || 'washer-v1' => 'washer-core',
      'fridge' || 'fridge-v1' => 'fridge-core',
      'dishwasher' || 'dishwasher-v1' => 'dishwasher-core',
      final other => other,
    };
  }

  /// Failure-mode ids last imported into [packageId] via the Knowledge Factory.
  List<String> importedAuthoringIds(String packageId) {
    return List.unmodifiable(_authoringIdsByPackageId[packageId] ?? const []);
  }

  /// Merges a Knowledge Factory JSON batch into an existing package in-place.
  FailureModeBatchImportResult importFailureModeBatchJson({
    required String packageId,
    required String rawJson,
  }) {
    final existing = _packagesById[packageId];
    if (existing == null) {
      throw StateError('Knowledge package "$packageId" was not found.');
    }
    const importer = FailureModeBatchImporter();
    final importedRecords = importer.parseBatchJson(rawJson);
    final result = importer.mergeJsonIntoPackage(
      base: existing,
      rawJson: rawJson,
    );
    _packagesById[packageId] = result.package;
    _authoringIdsByPackageId[packageId] = result.importedIds;
    final records = packageId == 'dryer-core'
        ? _mergedAuthoringRecords(
          baseRecords: _allDryerAuthoringRecords(importer),
          extraRecords: importedRecords,
        )
        : importedRecords;
    _authoringIndexByPackageId[packageId] = PackageAuthoringIndex.fromPackage(
      result.package,
      records: records,
    );
    return result;
  }

  static List<FailureModeAuthoringRecord> _mergedAuthoringRecords({
    required List<FailureModeAuthoringRecord> baseRecords,
    required List<FailureModeAuthoringRecord> extraRecords,
  }) {
    final byId = {
      for (final record in baseRecords) record.id: record,
    };
    for (final record in extraRecords) {
      byId[record.id] = record;
    }
    return byId.values.toList(growable: false);
  }

  void _registerPackage(String packageId, KnowledgePackage package) {
    _packagesById[packageId] = package;
    if (package.category == 'dryer') {
      _authoringIndexByPackageId[packageId] = _buildDryerAuthoringIndex(package);
    } else {
      _authoringIndexByPackageId[packageId] =
          PackageAuthoringIndex.fromPackage(package);
    }
  }

  static PackageAuthoringIndex _buildDryerAuthoringIndex(
    KnowledgePackage package,
  ) {
    const importer = FailureModeBatchImporter();
    return PackageAuthoringIndex.fromPackage(
      package,
      records: _allDryerAuthoringRecords(importer),
    );
  }

  static List<FailureModeAuthoringRecord> _allDryerAuthoringRecords(
    FailureModeBatchImporter importer,
  ) {
    return [
      ...importer.parseBatchJson(dryerBatch01Json),
      ...importer.parseBatchJson(dryerBatch02Json),
    ];
  }

  static KnowledgePackage _buildDryerPackage() {
    final base = _buildDryerPackageCore();
    const importer = FailureModeBatchImporter();
    final withGolden = importer.mergeDryerGoldenExample(base).package;
    final withBatch01 = importer.mergeDryerBatch01(withGolden).package;
    return importer.mergeDryerBatch02(withBatch01).package;
  }

  KnowledgePackage _seedDryerPackage() {
    final package = _buildDryerPackage();
    _registerPackage(package.id, package);
    const importer = FailureModeBatchImporter();
    _authoringIdsByPackageId[package.id] =
        _allDryerAuthoringRecords(importer).map((r) => r.id).toList();
    return package;
  }

  KnowledgePackage _seedWasherPackage() {
    final package = buildWasherMvpPackage();
    _registerPackage(package.id, package);
    return package;
  }

  KnowledgePackage _seedFridgePackage() {
    final package = buildFridgeMvpPackage();
    _registerPackage(package.id, package);
    return package;
  }

  KnowledgePackage _seedDishwasherPackage() {
    final package = buildDishwasherMvpPackage();
    _registerPackage(package.id, package);
    return package;
  }

  static KnowledgePackage _buildDryerPackageCore() {
    return KnowledgePackage(
      id: 'dryer-core',
      category: 'dryer',
      // Release: docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md (human still signs).
      version: '1.4.2',
      displayName: 'Dryer Knowledge Package',
      schemaVersion: '1.0',
      createdAt: DateTime.utc(2026, 7, 24),
      source:
          'Dryer Knowledge Package V1.4.2 — Batch 01+02 plus accessible '
          'thermal reset path (41 modes) and easy-airflow inspect steps',
      status: KnowledgePackageStatus.production,
      inspectSteps: dryerPackageInspectSteps,
      failureModes: const [
        FailureMode(
          id: 'restricted-exhaust-airflow',
          label: 'Restricted vent or exhaust airflow',
          description:
              'Air cannot leave the dryer effectively, causing slow drying '
              'and possible overheating.',
          commonality: FailureModeCommonality.veryHigh,
          safetyNotes:
              'Use exterior observations only; do not ignore overheating.',
        ),
        FailureMode(
          id: 'clogged-lint-pathway',
          label: 'Clogged lint filter housing or pathway',
          description:
              'Lint restricts airflow beyond the removable filter screen.',
          commonality: FailureModeCommonality.high,
          safetyNotes: 'Inspect only safely accessible lint areas.',
        ),
        FailureMode(
          id: 'thermal-fuse-open',
          label: 'Thermal fuse open',
          description:
              'A protective fuse has opened after an overheating condition.',
          commonality: FailureModeCommonality.veryHigh,
          safetyNotes:
              'Never bypass a thermal fuse; replace only with power isolated.',
        ),
        FailureMode(
          id: 'heating-element-failed',
          label: 'Heating element open or failed',
          description:
              'The electric heating element no longer produces heat.',
          commonality: FailureModeCommonality.high,
          safetyNotes:
              'Do not guide beginners through live electrical testing.',
        ),
        FailureMode(
          id: 'broken-drive-belt',
          label: 'Broken drive belt',
          description:
              'The motor may run while the belt no longer turns the drum.',
          commonality: FailureModeCommonality.high,
          safetyNotes: 'Inspect internally only after safe isolation.',
        ),
        FailureMode(
          id: 'door-switch-failure',
          label: 'Door switch failure',
          description:
              'The dryer does not detect a securely closed door.',
          commonality: FailureModeCommonality.common,
          safetyNotes: 'Never bypass the door switch or safety interlock.',
        ),
        FailureMode(
          id: 'worn-drum-rollers',
          label: 'Worn drum rollers',
          description:
              'Worn drum supports create squealing or thumping while running.',
          commonality: FailureModeCommonality.common,
          safetyNotes: 'Limit checks to sound and safely isolated inspection.',
        ),
        FailureMode(
          id: 'idler-pulley-wear',
          label: 'Idler pulley wear',
          description:
              'A worn belt-tension pulley creates a recurring squeak.',
          commonality: FailureModeCommonality.common,
          safetyNotes: 'Internal inspection requires safe isolation.',
        ),
        FailureMode(
          id: 'motor-failure',
          label: 'Motor failure or inability to take load',
          description:
              'The motor hums or struggles without turning the drum normally.',
          commonality: FailureModeCommonality.moderate,
          safetyNotes:
              'Escalate rather than guide unsafe internal electrical work.',
        ),
        FailureMode(
          id: 'electric-supply-connection-fault',
          label: 'Loose or faulty electric supply connection',
          description:
              'The dryer may tumble without receiving the supply needed for '
              'heat.',
          commonality: FailureModeCommonality.moderate,
          safetyNotes:
              'High voltage: do not provide live measurement instructions.',
        ),
        FailureMode(
          id: 'accessible-thermal-reset',
          label: 'Resettable thermal cutoff',
          description:
              'A user-accessible reset or auto-reset thermal protector opened. '
              'Heat can return after cooldown or a visible reset if the vent '
              'and lint path are cleared. This is not a behind-panel fuse swap.',
          commonality: FailureModeCommonality.common,
          safetyNotes:
              'Never jumper a protector. Do not open heater panels or probe '
              'live wiring. Repeated trips need a technician.',
        ),
      ],
      symptoms: const [
        Symptom(
          id: 'no-heat',
          label: 'No heat',
          description: 'The drum turns but no warmth is observed.',
        ),
        Symptom(
          id: 'long-dry-time',
          label: 'Long dry time',
          description: 'Clothes require much longer than normal to dry.',
        ),
        Symptom(
          id: 'clothes-hot-but-damp',
          label: 'Clothes hot but damp',
          description: 'Clothes become hot but remain noticeably wet.',
        ),
        Symptom(
          id: 'weak-exterior-airflow',
          label: 'Weak exterior airflow',
          description: 'Little airflow is observed at the exterior vent.',
        ),
        Symptom(
          id: 'will-not-start',
          label: 'Will not start',
          description: 'The dryer does not begin when Start is pressed.',
        ),
        Symptom(
          id: 'motor-runs-drum-still',
          label: 'Motor runs but drum does not turn',
          description: 'Motor sound is present without drum movement.',
        ),
        Symptom(
          id: 'squealing-or-thumping',
          label: 'Squealing or thumping',
          description: 'A repeating mechanical noise occurs while tumbling.',
        ),
        Symptom(
          id: 'dryer-very-hot',
          label: 'Dryer becomes very hot',
          description: 'The machine feels much hotter than during normal use.',
        ),
      ],
      // Order matters for auto-next when top-mode overlap is empty or tied:
      // start → drum/heat branch → no-heat discriminators → won't-start → vent.
      evidenceTemplates: [
        EvidenceTemplate(
          id: 'dryer-response',
          promptText: 'What happens when you press Start?',
          expectedEvidenceType: EvidenceType.textObservation,
          relatedFailureModeIds: const [
            'door-switch-failure',
            'motor-failure',
            'electric-supply-connection-fault',
            'broken-drive-belt',
          ],
          answerChoices: const [
            'Nothing happens',
            'Starts normally',
            'Hums but does not start',
            'Starts then stops',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Nothing happens': ['door-switch-failure'],
            'Hums but does not start': ['motor-failure'],
            'Starts then stops': [
              'door-switch-failure',
              'motor-failure',
              'accessible-thermal-reset',
              'motor-overheat-protector-open',
            ],
          },
          excludeByAnswer: const {
            'Starts normally': [
              'door-switch-failure',
              'motor-failure',
              'electric-supply-connection-fault',
              'no-power-at-outlet',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'drum-turns',
          promptText: 'Does the drum turn during the cycle?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'broken-drive-belt',
            'motor-failure',
            'heating-element-failed',
          ],
          answerChoices: const [
            'Turns normally',
            'Does not turn',
            'Motor runs, drum still',
            'Turns briefly then stops',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Does not turn': ['broken-drive-belt', 'motor-failure'],
            'Motor runs, drum still': [
              'broken-drive-belt',
            ],
            'Turns briefly then stops': ['broken-drive-belt', 'motor-failure'],
          },
          excludeByAnswer: const {
            'Turns normally': [
              'broken-drive-belt',
              'motor-failure',
              'no-power-at-outlet',
              'missing-leg-240v-supply',
            ],
            'Motor runs, drum still': ['motor-failure'],
          },
        ),
        EvidenceTemplate(
          id: 'heat-observed',
          promptText: 'Is there any warmth after the dryer has run briefly?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'thermal-fuse-open',
            'heating-element-failed',
            'electric-supply-connection-fault',
          ],
          answerChoices: const [
            'No warmth',
            'Slight warmth',
            'Normal heat',
            'Very hot',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'No warmth': [
              'thermal-fuse-open',
              'heating-element-failed',
              'electric-supply-connection-fault',
            ],
            'Slight warmth': ['heating-element-failed'],
          },
          excludeByAnswer: const {
            'Normal heat': [
              'thermal-fuse-open',
              'heating-element-failed',
              'electric-supply-connection-fault',
            ],
            'Very hot': [
              'thermal-fuse-open',
              'heating-element-failed',
              'electric-supply-connection-fault',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'cycle-heat-setting',
          promptText:
              'Is the dryer set to a heat cycle rather than air-only / fluff?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'heating-element-failed',
            'thermal-fuse-open',
          ],
          answerChoices: const [
            'Yes, heat cycle',
            'No, air-only / fluff',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Yes, heat cycle': ['heating-element-failed', 'thermal-fuse-open'],
          },
          excludeByAnswer: const {
            'No, air-only / fluff': [
              'heating-element-failed',
              'thermal-fuse-open',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'recent-overheat',
          promptText:
              'On a recent run, did the dryer feel unusually hot or stop early '
              'because of heat?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'thermal-fuse-open',
            'heating-element-failed',
            'restricted-exhaust-airflow',
            'motor-overheat-protector-open',
          ],
          answerChoices: const [
            'Yes, very hot or shut off from heat',
            'No',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Yes, very hot or shut off from heat': [
              'thermal-fuse-open',
              'restricted-exhaust-airflow',
              'motor-overheat-protector-open',
            ],
          },
          excludeByAnswer: const {
            'No': ['thermal-fuse-open'],
          },
        ),
        EvidenceTemplate(
          id: 'thermal-reset-control',
          promptText:
              'Did this dryer start again after cooling, or is there a visible '
              'reset (button or marked reset you can reach without opening '
              'internal panels)?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'accessible-thermal-reset',
            'motor-overheat-protector-open',
            'thermal-fuse-open',
            'heating-element-failed',
          ],
          answerChoices: const [
            'Has a reset button / I reset it',
            'Started again after cooling 30+ minutes',
            'No visible reset, still fully cold after cooling',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Has a reset button / I reset it': [
              'accessible-thermal-reset',
            ],
            'Started again after cooling 30+ minutes': [
              'accessible-thermal-reset',
              'motor-overheat-protector-open',
            ],
            'No visible reset, still fully cold after cooling': [
              'thermal-fuse-open',
              'heating-element-failed',
            ],
          },
          excludeByAnswer: const {
            'Has a reset button / I reset it': [
              'thermal-fuse-open',
            ],
            'Started again after cooling 30+ minutes': [
              'thermal-fuse-open',
            ],
            'No visible reset, still fully cold after cooling': [
              'accessible-thermal-reset',
              'motor-overheat-protector-open',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'wall-plug-seated',
          promptText:
              'Is the dryer wall plug fully pushed in (no looseness; cord and '
              'plug look normal)?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'electric-supply-connection-fault',
            'heating-element-failed',
          ],
          answerChoices: const [
            'Fully seated, looks normal',
            'Loose or only partly seated',
            'Plug or cord looks damaged / discolored',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Loose or only partly seated': [
              'electric-supply-connection-fault',
              'electric-supply-connection-fault',
            ],
            'Plug or cord looks damaged / discolored': [
              'electric-supply-connection-fault',
              'electric-supply-connection-fault',
            ],
            // Safe external check clears supply as the likely no-heat cause.
            'Fully seated, looks normal': ['heating-element-failed'],
          },
          excludeByAnswer: const {
            'Fully seated, looks normal': [
              'electric-supply-connection-fault',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'motor-audible',
          promptText:
              'While the dryer tries to run, do you hear the motor humming '
              'or whirring?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'broken-drive-belt',
            'motor-failure',
            'door-switch-failure',
          ],
          answerChoices: const [
            'Yes, clear motor sound',
            'Hum / struggle only',
            'Silent — no motor sound',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Yes, clear motor sound': ['broken-drive-belt'],
            'Hum / struggle only': ['motor-failure', 'motor-failure'],
            'Silent — no motor sound': [
              'door-switch-failure',
              'motor-failure',
            ],
          },
          excludeByAnswer: const {
            'Yes, clear motor sound': ['motor-failure', 'door-switch-failure'],
            'Hum / struggle only': ['broken-drive-belt'],
            'Silent — no motor sound': ['broken-drive-belt'],
          },
        ),
        EvidenceTemplate(
          id: 'panel-lights',
          promptText:
              'Do any lights, display, or control-panel indicators respond '
              'when you try to start?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'door-switch-failure',
            'electric-supply-connection-fault',
          ],
          answerChoices: const [
            'Yes, panel responds',
            'No lights at all',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Yes, panel responds': ['door-switch-failure'],
            'No lights at all': ['electric-supply-connection-fault'],
          },
          excludeByAnswer: const {
            'Yes, panel responds': [
              'electric-supply-connection-fault',
              'no-power-at-outlet',
            ],
            'No lights at all': ['door-switch-failure'],
          },
        ),
        EvidenceTemplate(
          id: 'heat-pattern',
          promptText:
              'After the dryer has run on a heat cycle, how does the load feel?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'cycling-thermostat-failed',
            'thermistor-fault-electronic',
            'high-limit-thermostat-open',
          ],
          answerChoices: const [
            'No heat',
            'Some heat but clothes stay damp',
            'Too hot / overheating',
            'Heat seems normal',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'No heat': ['heating-element-failed', 'thermal-fuse-open'],
            'Some heat but clothes stay damp': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
            'Too hot / overheating': ['high-limit-thermostat-open'],
          },
          excludeByAnswer: const {
            'Heat seems normal': [
              'heating-element-failed',
              'thermal-fuse-open',
              'restricted-exhaust-airflow',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'door-closed-firmly',
          promptText: 'Does the door click firmly shut and stay closed?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'door-switch-failure',
          ],
          answerChoices: const [
            'Clicks shut firmly',
            'Soft close / no click',
            'Will not stay closed',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Soft close / no click': [
              'door-switch-failure',
              'door-switch-failure',
            ],
            'Will not stay closed': [
              'door-switch-failure',
              'door-switch-failure',
            ],
          },
          excludeByAnswer: const {
            // A firm click does not prove the door switch is working.
          },
        ),
        EvidenceTemplate(
          id: 'clothes-feel-after-cycle',
          promptText:
              'When you took the clothes out after a full cycle, how did they feel?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'heating-element-failed',
            'restricted-exhaust-airflow',
            'clogged-lint-pathway',
            'cycling-thermostat-stuck-closed',
          ],
          answerChoices: const [
            'Cold and still damp',
            'Warm or hot but still damp',
            'Dry but unusually hot',
            'Dry and normal',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Cold and still damp': [
              'heating-element-failed',
              'thermal-fuse-open',
              'electric-supply-connection-fault',
            ],
            'Warm or hot but still damp': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
            'Dry but unusually hot': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
              'cycling-thermostat-stuck-closed',
            ],
          },
          excludeByAnswer: const {
            'Cold and still damp': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
            'Warm or hot but still damp': [
              'heating-element-failed',
              'thermal-fuse-open',
              'electric-supply-connection-fault',
            ],
            'Dry but unusually hot': [
              'heating-element-failed',
              'thermal-fuse-open',
              'electric-supply-connection-fault',
            ],
            'Dry and normal': [
              'heating-element-failed',
              'thermal-fuse-open',
              'electric-supply-connection-fault',
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'clothes-remain-damp',
          promptText:
              'When you took the clothes out after a full cycle, were they still damp?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'restricted-exhaust-airflow',
            'clogged-lint-pathway',
          ],
          answerChoices: const [
            'Still damp',
            'Mostly dry',
            'Fully dry',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Still damp': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
          },
          excludeByAnswer: const {
            'Mostly dry': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
            'Fully dry': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'lint-filter-condition',
          promptText: lintFilterEasyPrompt,
          expectedEvidenceType: EvidenceType.textObservation,
          relatedFailureModeIds: const [
            'clogged-lint-pathway',
            'restricted-exhaust-airflow',
            'thermal-fuse-open',
          ],
          answerChoices: const [
            'Clean',
            'Light lint',
            'Heavily clogged',
            'Missing / damaged',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Heavily clogged': [
              'clogged-lint-pathway',
              'clogged-lint-pathway',
              'restricted-exhaust-airflow',
              'thermal-fuse-open',
            ],
            'Missing / damaged': ['clogged-lint-pathway'],
          },
          excludeByAnswer: const {
            // A clean screen does not clear a packed lint housing.
          },
        ),
        EvidenceTemplate(
          id: 'exterior-airflow',
          promptText: exteriorAirflowEasyPrompt,
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'restricted-exhaust-airflow',
            'clogged-lint-pathway',
            'thermal-fuse-open',
            'heating-element-failed',
          ],
          answerChoices: const [
            'Weak',
            'Almost none',
            'Normal',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            // Exterior weakness is primarily vent/exhaust; also a common
            // overheat contributor that precedes an open thermal fuse.
            'Weak': [
              'restricted-exhaust-airflow',
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
              'thermal-fuse-open',
            ],
            'Almost none': [
              'restricted-exhaust-airflow',
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
              'thermal-fuse-open',
            ],
            // Clear exterior airflow on a no-heat path favors element over fuse.
            'Normal': ['heating-element-failed'],
          },
          excludeByAnswer: const {
            // Strong exterior airflow argues against vent restriction and
            // against a fuse opened by prior airflow overheating.
            'Normal': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
              'thermal-fuse-open',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'vent-hose-condition',
          promptText: ventHoseEasyPrompt,
          expectedEvidenceType: EvidenceType.textObservation,
          relatedFailureModeIds: const [
            'restricted-exhaust-airflow',
            'clogged-lint-pathway',
          ],
          answerChoices: const [
            'Yes, restricted',
            'Looks clear',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Yes, restricted': [
              'restricted-exhaust-airflow',
              'restricted-exhaust-airflow',
            ],
          },
          excludeByAnswer: const {
            'Looks clear': ['restricted-exhaust-airflow'],
          },
        ),
        EvidenceTemplate(
          id: 'dry-time-change',
          promptText: 'How does the current drying time compare with normal?',
          expectedEvidenceType: EvidenceType.textObservation,
          relatedFailureModeIds: const [
            'restricted-exhaust-airflow',
            'clogged-lint-pathway',
          ],
          answerChoices: const [
            'Much longer',
            'Somewhat longer',
            'About normal',
            'Shorter than normal',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Much longer': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
            'Somewhat longer': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
          },
          excludeByAnswer: const {
            'About normal': [
              'restricted-exhaust-airflow',
              'clogged-lint-pathway',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'running-noise',
          promptText:
              'Do you hear a squeal, thump, grind, hum, or another sound?',
          expectedEvidenceType: EvidenceType.textObservation,
          relatedFailureModeIds: const [
            'worn-drum-rollers',
            'idler-pulley-wear',
            'motor-failure',
            'broken-drive-belt',
          ],
          answerChoices: const [
            'No unusual sound',
            'Squeal',
            'Thump',
            'Grind',
            'Hum',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            // Recurring squeal while tumbling is classically the idler.
            'Squeal': [
              'idler-pulley-wear',
              'idler-pulley-wear',
              'worn-drum-rollers',
            ],
            'Thump': ['worn-drum-rollers', 'worn-drum-rollers'],
            'Grind': ['idler-pulley-wear', 'motor-failure'],
            'Hum': ['motor-failure'],
          },
          excludeByAnswer: const {
            'No unusual sound': [
              'worn-drum-rollers',
              'idler-pulley-wear',
              'motor-failure',
            ],
            // Noise while tumbling is not the classic broken-belt pattern.
            'Squeal': ['broken-drive-belt'],
            'Thump': ['broken-drive-belt'],
          },
        ),
        EvidenceTemplate(
          id: 'hazard-observation',
          promptText:
              'Do you observe a burning smell, smoke, or repeated stopping?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'restricted-exhaust-airflow',
            'motor-failure',
            'electric-supply-connection-fault',
          ],
          answerChoices: const [
            'Yes',
            'No',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Yes': [
              'restricted-exhaust-airflow',
              'motor-failure',
              'electric-supply-connection-fault',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'lint-housing-slot',
          promptText:
              'With the lint filter pulled out, is the slot or housing packed '
              'with lint?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'clogged-lint-pathway',
            'restricted-exhaust-airflow',
            'thermal-fuse-open',
          ],
          answerChoices: const [
            'Packed with lint',
            'Light lint',
            'Looks clear',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Packed with lint': [
              'clogged-lint-pathway',
              'clogged-lint-pathway',
              'restricted-exhaust-airflow',
              'thermal-fuse-open',
            ],
            'Light lint': ['clogged-lint-pathway'],
          },
          excludeByAnswer: const {
            'Looks clear': ['clogged-lint-pathway'],
          },
        ),
        EvidenceTemplate(
          id: 'noise-timing',
          promptText:
              'Does the noise follow each drum turn, or is it a squeal that '
              'starts after a few minutes of tumbling?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'worn-drum-rollers',
            'idler-pulley-wear',
          ],
          answerChoices: const [
            'Repeats with each drum turn (thump/rumble)',
            'Sharp squeal after a few minutes',
            'Other / mixed',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Repeats with each drum turn (thump/rumble)': [
              'worn-drum-rollers',
              'worn-drum-rollers',
            ],
            'Sharp squeal after a few minutes': [
              'idler-pulley-wear',
              'idler-pulley-wear',
            ],
          },
          excludeByAnswer: const {
            'Repeats with each drum turn (thump/rumble)': [
              'idler-pulley-wear',
            ],
            'Sharp squeal after a few minutes': ['worn-drum-rollers'],
          },
        ),
        EvidenceTemplate(
          id: 'heat-before-failure',
          promptText:
              'Before this no-heat problem, did the dryer still heat on a '
              'heat cycle?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'heating-element-failed',
            'thermal-fuse-open',
          ],
          answerChoices: const [
            'Never heated on this complaint / always cold',
            'Heated, then went cold after a very hot run or vent issue',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Never heated on this complaint / always cold': [
              'heating-element-failed',
              'heating-element-failed',
            ],
            'Heated, then went cold after a very hot run or vent issue': [
              'thermal-fuse-open',
              'thermal-fuse-open',
            ],
          },
          excludeByAnswer: const {
            'Never heated on this complaint / always cold': [
              'thermal-fuse-open',
            ],
            'Heated, then went cold after a very hot run or vent issue': [
              'heating-element-failed',
            ],
          },
        ),
        EvidenceTemplate(
          id: 'door-held-closed-start',
          promptText:
              'If you hold the door firmly closed and press Start, what happens?',
          expectedEvidenceType: EvidenceType.structuredAnswer,
          relatedFailureModeIds: const [
            'door-switch-failure',
          ],
          answerChoices: const [
            'Starts only while I hold the door closed',
            'Still does nothing',
            'Starts normally without holding the door',
            'Not sure',
            'Other / describe',
          ],
          supportByAnswer: const {
            'Starts only while I hold the door closed': [
              'door-switch-failure',
              'door-switch-failure',
            ],
            'Still does nothing': ['door-switch-failure'],
          },
          excludeByAnswer: const {
            'Starts normally without holding the door': [
              'door-switch-failure',
            ],
          },
        ),
      ],
      safeChecks: [
        SafeCheck(
          id: 'confirm-machine-response',
          label: 'Confirm machine response',
          description:
              'Observe lights, sounds, and movement after a normal start.',
          requiredTools: const [],
          safetyLevel: 'low',
        ),
        SafeCheck(
          id: 'confirm-drum-movement',
          label: 'Confirm drum movement',
          description: 'Observe whether the drum turns during normal operation.',
          requiredTools: const [],
          safetyLevel: 'low',
        ),
        SafeCheck(
          id: 'inspect-lint-filter',
          label: 'Inspect lint filter',
          description:
              'Remove the lint filter normally and observe its condition.',
          requiredTools: const [],
          safetyLevel: 'low',
        ),
        SafeCheck(
          id: 'inspect-visible-vent-hose',
          label: 'Inspect visible vent hose',
          description:
              'Observe whether the accessible hose is crushed or kinked.',
          requiredTools: const ['flashlight'],
          safetyLevel: 'low',
        ),
        SafeCheck(
          id: 'observe-exterior-airflow',
          label: 'Observe exterior vent airflow',
          description:
              'Observe exterior airflow while the dryer runs normally.',
          requiredTools: const [],
          safetyLevel: 'caution',
        ),
        SafeCheck(
          id: 'confirm-cycle-setting',
          label: 'Confirm cycle setting',
          description:
              'Observe whether air-only, low-heat, or another cycle is selected.',
          requiredTools: const [],
          safetyLevel: 'low',
        ),
        SafeCheck(
          id: 'confirm-wall-plug',
          label: 'Confirm wall plug seating',
          description:
              'With dry hands, confirm the plug is fully seated; do not open '
              'the cord or measure voltage.',
          requiredTools: const [],
          safetyLevel: 'low',
        ),
      ],
    );
  }
}
