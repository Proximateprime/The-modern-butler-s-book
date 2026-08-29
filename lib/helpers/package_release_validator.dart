import 'dart:convert';
import 'dart:io';

import '../models/knowledge_package.dart';
import '../services/knowledge_package_repository.dart';
import 'dryer_close_path.dart';

/// Mechanical knowledge-package gates. Does **not** publish. A human still
/// signs `docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md`.
const List<String> knowledgePackageFamilyFolders = [
  'dryer',
  'washer',
  'dishwasher',
];

/// Modes that must not read as beginner DIY on live/heater/gas/electrical work.
const List<String> riskyVerificationModeIds = [
  'heating-element-failed',
  'thermal-fuse-open',
  'high-limit-thermostat-open',
  'electric-supply-connection-fault',
  'electrical-burning-smell-hazard',
  'motor-failure',
  'gas-dryer-no-ignition-professional-only',
];

class PackageReleaseFinding {
  const PackageReleaseFinding({
    required this.packageId,
    required this.checkId,
    required this.message,
  });

  final String packageId;
  final String checkId;
  final String message;

  @override
  String toString() => '[$packageId] $checkId: $message';
}

class PackageReleaseReport {
  PackageReleaseReport({
    required this.errors,
    required this.notes,
  });

  final List<PackageReleaseFinding> errors;
  final List<String> notes;

  bool get ok => errors.isEmpty;
}

class ClaimedPackagePaths {
  const ClaimedPackagePaths({
    required this.packageId,
    required this.expectedVersion,
    required this.regressionDocs,
    required this.paths,
  });

  final String packageId;
  final String? expectedVersion;
  final List<String> regressionDocs;
  final List<ClaimedSymptomPath> paths;

  factory ClaimedPackagePaths.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['paths'];
    if (rawPaths is! List) {
      throw const FormatException('claimed_paths.json missing paths array');
    }
    return ClaimedPackagePaths(
      packageId: json['packageId'] as String? ?? '',
      expectedVersion: json['expectedVersion'] as String?,
      regressionDocs: [
        for (final item in json['regressionDocs'] as List? ?? const [])
          item.toString(),
      ],
      paths: [
        for (final item in rawPaths)
          ClaimedSymptomPath.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}

class ClaimedSymptomPath {
  const ClaimedSymptomPath({
    required this.symptomId,
    required this.modeIds,
  });

  final String symptomId;
  final List<String> modeIds;

  factory ClaimedSymptomPath.fromJson(Map<String, dynamic> json) {
    final modes = json['modeIds'];
    return ClaimedSymptomPath(
      symptomId: json['symptomId'] as String? ?? '',
      modeIds: [
        for (final item in modes as List? ?? const []) item.toString(),
      ],
    );
  }
}

String findRepoRoot({Directory? start}) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 10; i++) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    final repo = File(
      '${dir.path}/lib/services/knowledge_package_repository.dart',
    );
    if (pubspec.existsSync() && repo.existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not find repo root (pubspec.yaml + knowledge_package_repository).',
  );
}

/// True when a user-facing line looks like an unsafe *instruction* (not a stop).
bool lineLooksLikeUnsafeInstruction(String line) {
  final text = line.toLowerCase();
  if (RegExp(
    r"\b(do not|don't|does not|never|not a beginner|"
    r'professional|technician|qualified|'
    r'no live|no gas|not for gas|call a)\b',
  ).hasMatch(text)) {
    return false;
  }
  const needles = [
    'bypass the',
    'bypass a',
    'jumper the',
    'jump the',
    'measure live',
    'probe live',
    'test live voltage',
    'live voltage',
    'recover refrigerant',
    'pierce the line',
    'pierce lines',
    'light the gas',
    'open the sealed',
    'split a sealed',
  ];
  return needles.any(text.contains);
}

PackageReleaseReport validateKnowledgePackages({
  String? repoRoot,
  KnowledgePackageRepository? repository,
}) {
  final root = repoRoot ?? findRepoRoot();
  final repo = repository ?? KnowledgePackageRepository();
  final errors = <PackageReleaseFinding>[];
  final notes = <String>[
    'VALIDATOR OK means mechanical gates passed only. A human must still '
        'sign docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md. This does not publish.',
  ];

  for (final family in knowledgePackageFamilyFolders) {
    final jsonPath = '$root/docs/knowledge/$family/claimed_paths.json';
    final file = File(jsonPath);
    if (!file.existsSync()) {
      errors.add(
        PackageReleaseFinding(
          packageId: family,
          checkId: 'claimed-paths-file',
          message: 'Missing $jsonPath',
        ),
      );
      continue;
    }

    late ClaimedPackagePaths claimed;
    try {
      claimed = ClaimedPackagePaths.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    } catch (error) {
      errors.add(
        PackageReleaseFinding(
          packageId: family,
          checkId: 'claimed-paths-file',
          message: 'Could not parse $jsonPath: $error',
        ),
      );
      continue;
    }

    _validateClaimed(
      claimed: claimed,
      package: repo.loadById(claimed.packageId),
      repoRoot: root,
      errors: errors,
    );
  }

  return PackageReleaseReport(errors: errors, notes: notes);
}

void _validateClaimed({
  required ClaimedPackagePaths claimed,
  required KnowledgePackage? package,
  required String repoRoot,
  required List<PackageReleaseFinding> errors,
}) {
  final id = claimed.packageId;
  if (id.trim().isEmpty) {
    errors.add(
      PackageReleaseFinding(
        packageId: '(missing)',
        checkId: 'version',
        message: 'claimed_paths.json has empty packageId',
      ),
    );
    return;
  }
  if (package == null) {
    errors.add(
      PackageReleaseFinding(
        packageId: id,
        checkId: 'version',
        message: 'Package is not loaded in KnowledgePackageRepository',
      ),
    );
    return;
  }

  if (package.version.trim().isEmpty) {
    errors.add(
      PackageReleaseFinding(
        packageId: id,
        checkId: 'version',
        message: 'KnowledgePackage.version is empty',
      ),
    );
  }
  final expected = claimed.expectedVersion?.trim();
  if (expected != null && expected.isNotEmpty && package.version != expected) {
    errors.add(
      PackageReleaseFinding(
        packageId: id,
        checkId: 'version',
        message:
            'Version ${package.version} does not match claimed expectedVersion $expected',
      ),
    );
  }

  final modeIds = {for (final mode in package.failureModes) mode.id};
  final symptomsById = {for (final symptom in package.symptoms) symptom.id: symptom};
  final linkedModes = _linkedModeIds(package);

  for (final path in claimed.paths) {
    final symptom = symptomsById[path.symptomId];
    if (symptom == null) {
      errors.add(
        PackageReleaseFinding(
          packageId: id,
          checkId: 'symptom-mode-links',
          message: 'Claimed symptom ${path.symptomId} is not in the package',
        ),
      );
      continue;
    }
    for (final modeId in path.modeIds) {
      if (!modeIds.contains(modeId)) {
        errors.add(
          PackageReleaseFinding(
            packageId: id,
            checkId: 'symptom-mode-links',
            message: 'Claimed mode $modeId for ${path.symptomId} is not in the package',
          ),
        );
        continue;
      }
      if (!linkedModes.contains(modeId)) {
        errors.add(
          PackageReleaseFinding(
            packageId: id,
            checkId: 'symptom-mode-links',
            message:
                'Mode $modeId is claimed for ${path.symptomId} but is not linked '
                'from any evidence template (relatedFailureModeIds / supportByAnswer)',
          ),
        );
      }
    }
    _validateComplaintAnswer(
      package: package,
      claimed: path,
      symptomLabel: symptom.label,
      errors: errors,
    );
  }

  _validateRiskyVerifications(package: package, errors: errors);
  _validateStopSafeChecks(package: package, errors: errors);
  _validateUnsafeStrings(package: package, errors: errors);

  if (claimed.regressionDocs.isEmpty) {
    errors.add(
      PackageReleaseFinding(
        packageId: id,
        checkId: 'regression-docs',
        message: 'claimed_paths.json has no regressionDocs',
      ),
    );
  }
  for (final relative in claimed.regressionDocs) {
    final file = File('$repoRoot/$relative');
    if (!file.existsSync()) {
      errors.add(
        PackageReleaseFinding(
          packageId: id,
          checkId: 'regression-docs',
          message: 'Missing regression doc $relative',
        ),
      );
      continue;
    }
    final text = file.readAsStringSync();
    if (!text.contains(id)) {
      errors.add(
        PackageReleaseFinding(
          packageId: id,
          checkId: 'regression-docs',
          message: '$relative does not mention package id $id',
        ),
      );
    }
  }
}

Set<String> _linkedModeIds(KnowledgePackage package) {
  final ids = <String>{};
  for (final template in package.evidenceTemplates) {
    ids.addAll(template.relatedFailureModeIds);
    for (final modes in template.supportByAnswer.values) {
      ids.addAll(modes);
    }
  }
  return ids;
}

void _validateComplaintAnswer({
  required KnowledgePackage package,
  required ClaimedSymptomPath claimed,
  required String symptomLabel,
  required List<PackageReleaseFinding> errors,
}) {
  for (final template in package.evidenceTemplates) {
    if (!template.id.contains('complaint')) continue;
    final answers = template.supportByAnswer;
    if (!answers.containsKey(symptomLabel)) continue;
    final listed = answers[symptomLabel]!.toSet();
    for (final modeId in claimed.modeIds) {
      if (!listed.contains(modeId)) {
        errors.add(
          PackageReleaseFinding(
            packageId: package.id,
            checkId: 'symptom-mode-links',
            message:
                'Complaint answer "$symptomLabel" on ${template.id} does not '
                'list claimed mode $modeId',
          ),
        );
      }
    }
  }
}

void _validateRiskyVerifications({
  required KnowledgePackage package,
  required List<PackageReleaseFinding> errors,
}) {
  final present = {
    for (final mode in package.failureModes) mode.id,
  };
  for (final modeId in riskyVerificationModeIds) {
    if (!present.contains(modeId)) continue;
    final path = closePathForFailureMode(modeId);
    if (path == null) {
      errors.add(
        PackageReleaseFinding(
          packageId: package.id,
          checkId: 'risky-verification',
          message: 'Risky mode $modeId has no close path',
        ),
      );
      continue;
    }
    if (path.allowResolvedWhenConfirmed &&
        !path.preferProfessionalWhenNotConfirmed) {
      errors.add(
        PackageReleaseFinding(
          packageId: package.id,
          checkId: 'risky-verification',
          message:
              'Risky mode $modeId allows Resolved on confirm without a '
              'professional-prefer flag',
        ),
      );
    }
  }
}

void _validateStopSafeChecks({
  required KnowledgePackage package,
  required List<PackageReleaseFinding> errors,
}) {
  if (package.category == 'dryer') return;
  final stops = package.safeChecks
      .where((check) => check.safetyLevel.toLowerCase() == 'stop')
      .toList();
  bool covers(String needle) {
    return stops.any((check) {
      final blob = '${check.id} ${check.label} ${check.description}'.toLowerCase();
      return blob.contains(needle);
    });
  }

  for (final needle in ['sealed', 'live', 'gas']) {
    if (!covers(needle)) {
      errors.add(
        PackageReleaseFinding(
          packageId: package.id,
          checkId: 'risky-verification',
          message:
              'No safetyLevel=stop SafeCheck covering "$needle" '
              '(sealed / live electrical / gas)',
        ),
      );
    }
  }
}

void _validateUnsafeStrings({
  required KnowledgePackage package,
  required List<PackageReleaseFinding> errors,
}) {
  final lines = <String>[];
  for (final mode in package.failureModes) {
    lines.add(mode.description);
    lines.add(mode.safetyNotes);
  }
  for (final template in package.evidenceTemplates) {
    lines.add(template.promptText);
  }
  for (final check in package.safeChecks) {
    lines.add(check.label);
    lines.add(check.description);
  }
  for (final step in package.inspectSteps) {
    lines.add(step.safetyPreamble);
    lines.add(step.lookFor);
    lines.add(step.okMeans);
    lines.add(step.notOkMeans);
  }
  for (final mode in package.failureModes) {
    final path = closePathForFailureMode(mode.id);
    if (path == null) continue;
    lines.add(path.verificationAsk);
    lines.add(path.verificationWhy);
    lines.addAll(path.safeGuidanceSteps);
    lines.addAll(path.expertOkSteps);
  }

  for (final line in lines) {
    for (final piece in line.split(RegExp(r'[\n.]'))) {
      final trimmed = piece.trim();
      if (trimmed.isEmpty) continue;
      if (lineLooksLikeUnsafeInstruction(trimmed)) {
        errors.add(
          PackageReleaseFinding(
            packageId: package.id,
            checkId: 'unsafe-strings',
            message: 'User-facing line looks like an unsafe instruction: "$trimmed"',
          ),
        );
      }
    }
  }
}
