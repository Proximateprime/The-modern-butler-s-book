import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Override in tests. Production uses the system share sheet, then clipboard.
Future<void> Function(String text) repairLogShareHandler = shareRepairLogViaSystem;

/// Override in tests. Production copies plain text to the clipboard.
Future<void> Function(String text) repairLogCopyHandler =
    copyRepairLogToClipboard;

String repairLogShareSubject = 'Repair log';

Future<void> shareRepairLogText(
  String text, {
  String subject = 'Repair log',
}) {
  repairLogShareSubject = subject;
  return repairLogShareHandler(text);
}

Future<void> copyRepairLogText(String text) {
  return repairLogCopyHandler(text);
}

Future<void> copyRepairLogToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// System share sheet of plain text. No cloud upload.
Future<void> shareRepairLogViaSystem(String text) async {
  try {
    await Share.share(text, subject: repairLogShareSubject);
  } on MissingPluginException {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
