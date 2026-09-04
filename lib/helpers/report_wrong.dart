import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../models/repair_session.dart';
import '../models/session_outcome.dart';
import '../models/session_ui_resume_state.dart';
import 'evidence_prompt_match.dart';
import 'safety_stop.dart';

/// In-app “this was wrong” reports. Local notes + optional mailto stub.
///
/// No third-party crash or product-measurement SDK. No auto-upload of
/// household chats or photos.
/// Groq is not used here and must not decide what was wrong.

/// Stub inbox only. RFC 2606 `.invalid` — not a telemetry product.
const String kReportWrongSupportEmail = 'reports@themodernbutlersbook.invalid';

const int kReportWrongNoteMaxChars = 500;
const int kReportWrongStoredCap = 20;

/// Override in tests. Production opens a mailto draft when the OS can.
Future<bool> Function(Uri mailto) reportWrongMailtoOpener =
    openReportWrongMailto;

/// Local, PII-minimal report. No photos, floor plans, or household names.
class ReportWrongNote {
  const ReportWrongNote({
    required this.id,
    required this.recordedAt,
    required this.userNote,
    required this.appVersionLabel,
    this.applianceCategory,
    this.packageId,
    this.packageVersion,
    this.stopReason,
    this.lastQuestionId,
    this.clueCount = 0,
  });

  final String id;
  final DateTime recordedAt;
  final String userNote;
  final String appVersionLabel;
  final String? applianceCategory;
  final String? packageId;
  final String? packageVersion;
  final String? stopReason;
  final String? lastQuestionId;
  final int clueCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordedAt': recordedAt.toIso8601String(),
      'userNote': userNote,
      'appVersionLabel': appVersionLabel,
      if (applianceCategory != null) 'applianceCategory': applianceCategory,
      if (packageId != null) 'packageId': packageId,
      if (packageVersion != null) 'packageVersion': packageVersion,
      if (stopReason != null) 'stopReason': stopReason,
      if (lastQuestionId != null) 'lastQuestionId': lastQuestionId,
      'clueCount': clueCount,
    };
  }

  factory ReportWrongNote.fromJson(Map<String, dynamic> json) {
    return ReportWrongNote(
      id: json['id'] as String? ?? '',
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userNote: json['userNote'] as String? ?? '',
      appVersionLabel: json['appVersionLabel'] as String? ?? kAppVersionLabel,
      applianceCategory: json['applianceCategory'] as String?,
      packageId: json['packageId'] as String?,
      packageVersion: json['packageVersion'] as String?,
      stopReason: json['stopReason'] as String?,
      lastQuestionId: json['lastQuestionId'] as String?,
      clueCount: json['clueCount'] as int? ?? 0,
    );
  }
}

/// Session context for a report. No photos, names, or floor plans.
class ReportWrongContext {
  const ReportWrongContext({
    this.applianceCategory,
    this.packageId,
    this.packageVersion,
    this.stopReason,
    this.lastQuestionId,
    this.clueCount = 0,
  });

  final String? applianceCategory;
  final String? packageId;
  final String? packageVersion;
  final String? stopReason;
  final String? lastQuestionId;
  final int clueCount;
}

ReportWrongContext buildReportWrongContext({
  Appliance? appliance,
  KnowledgePackage? package,
  RepairSession? session,
  SessionOutcome? outcome,
  SessionUiResumeState? uiResume,
  List<Evidence> evidence = const [],
}) {
  final clues = interviewObservationsInOrder(evidence);
  final stop = evaluateSafetyStop(
    evidence: evidence,
    primaryFailureModeId: outcome?.rankingLeaderFailureModeId,
  );
  String? lastQuestionId = uiResume?.pendingObservationTemplateId;
  lastQuestionId ??= uiResume?.revisingObservationTemplateId;
  if (lastQuestionId == null && clues.isNotEmpty) {
    lastQuestionId = clues.last.templateId;
  }

  String? stopReason = stop?.reason;
  if (stopReason == null || stopReason.trim().isEmpty) {
    if (outcome != null) {
      stopReason = sessionCloseKindLabel(outcome.closeKind);
    } else if (session != null) {
      stopReason = session.currentState.name;
    }
  }

  return ReportWrongContext(
    applianceCategory: appliance?.category,
    packageId: package?.id ?? outcome?.basePackageId,
    packageVersion: package?.version ?? outcome?.basePackageVersion,
    stopReason: stopReason,
    lastQuestionId: lastQuestionId,
    clueCount: clues.length,
  );
}

String formatReportWrongEmailSubject(ReportWrongNote note) {
  final category = (note.applianceCategory ?? 'session').trim();
  return 'This was wrong — $category — ${note.appVersionLabel}';
}

/// Prefill body. Field names stay stable for the mailto stub tests.
String formatReportWrongEmailBody(ReportWrongNote note) {
  final packageLine = [
    note.packageId,
    note.packageVersion,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
  return [
    'App: ${note.appVersionLabel}',
    'Appliance category: ${note.applianceCategory ?? '—'}',
    'Package: ${packageLine.isEmpty ? '—' : packageLine}',
    'Stop reason: ${note.stopReason ?? '—'}',
    'Last question id: ${note.lastQuestionId ?? '—'}',
    'Clue count: ${note.clueCount}',
    'Note: ${note.userNote.trim().isEmpty ? '—' : note.userNote.trim()}',
    '',
    'This note is saved on the device. It was not uploaded automatically.',
  ].join('\n');
}

Uri reportWrongMailtoUri(ReportWrongNote note) {
  return Uri(
    scheme: 'mailto',
    path: kReportWrongSupportEmail,
    query: _mailtoQuery({
      'subject': formatReportWrongEmailSubject(note),
      'body': formatReportWrongEmailBody(note),
    }),
  );
}

String _mailtoQuery(Map<String, String> fields) {
  return fields.entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');
}

/// Production mailto. Missing plugin or no mail app → false (note still saved).
Future<bool> openReportWrongMailto(Uri mailto) async {
  try {
    if (!await canLaunchUrl(mailto)) {
      return false;
    }
    return launchUrl(mailto, mode: LaunchMode.externalApplication);
  } on MissingPluginException {
    return false;
  } catch (_) {
    return false;
  }
}
