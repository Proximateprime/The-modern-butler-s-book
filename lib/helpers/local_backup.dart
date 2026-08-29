import 'dart:convert';

import '../services/local_domain_store.dart';

const householdBackupKind = 'modern-butler-household-backup';
const householdBackupSchemaVersion = '1.0';

class BackupFileInvalidException implements Exception {
  const BackupFileInvalidException();
}

/// Local JSON envelope. No cloud.
String encodeHouseholdBackup(
  DomainSnapshot snapshot, {
  DateTime? exportedAt,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'kind': householdBackupKind,
    'schemaVersion': householdBackupSchemaVersion,
    'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
    'snapshot': snapshot.toJson(),
  });
}

/// Parses a backup file. Throws [BackupFileInvalidException] on garbage.
DomainSnapshot decodeHouseholdBackup(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw const BackupFileInvalidException();
  }
  if (decoded is! Map) {
    throw const BackupFileInvalidException();
  }
  final map = Map<String, dynamic>.from(decoded);
  if (map['kind'] != householdBackupKind) {
    throw const BackupFileInvalidException();
  }
  final snapshotRaw = map['snapshot'];
  if (snapshotRaw is! Map) {
    throw const BackupFileInvalidException();
  }
  try {
    return DomainSnapshot.fromJson(Map<String, dynamic>.from(snapshotRaw));
  } catch (_) {
    throw const BackupFileInvalidException();
  }
}
