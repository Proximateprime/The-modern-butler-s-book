import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Override in tests. Production shares backup JSON through the system sheet.
Future<void> Function(String json) householdBackupExportHandler =
    exportHouseholdBackupViaSystem;

/// Override in tests. Production opens a local file picker. Null = cancelled.
Future<String?> Function() householdBackupPickHandler =
    pickHouseholdBackupViaSystem;

Future<void> exportHouseholdBackupFile(String json) {
  return householdBackupExportHandler(json);
}

Future<String?> pickHouseholdBackupFile() {
  return householdBackupPickHandler();
}

Future<void> exportHouseholdBackupViaSystem(String json) async {
  try {
    await Share.share(json, subject: 'Household backup');
  } on MissingPluginException {
    await Clipboard.setData(ClipboardData(text: json));
  }
}

Future<String?> pickHouseholdBackupViaSystem() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return utf8.decode(file.bytes!);
    }
    return null;
  } on MissingPluginException {
    return null;
  }
}
