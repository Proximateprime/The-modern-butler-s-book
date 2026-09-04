import 'package:flutter/material.dart';

import '../helpers/report_wrong.dart';
import '../helpers/user_facing_error.dart';
import 'app_dependencies.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';

Future<void> openReportWrongScreen({
  required BuildContext context,
  required AppDependencies dependencies,
  String? sessionId,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder:
          (context) => ReportWrongScreen(
            dependencies: dependencies,
            sessionId: sessionId,
          ),
    ),
  );
}

/// Short local note + optional mailto. Does not diagnose or upload photos.
class ReportWrongScreen extends StatefulWidget {
  const ReportWrongScreen({
    required this.dependencies,
    this.sessionId,
    super.key,
  });

  final AppDependencies dependencies;
  final String? sessionId;

  @override
  State<ReportWrongScreen> createState() => _ReportWrongScreenState();
}

class _ReportWrongScreenState extends State<ReportWrongScreen> {
  final TextEditingController _note = TextEditingController();
  late final ReportWrongContext _contextSnapshot;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _contextSnapshot = widget.dependencies.reportWrongContextFor(
      widget.sessionId,
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveAndMaybeEmail() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    final note = await widget.dependencies.saveWrongReport(
      userNote: _note.text,
      sessionId: widget.sessionId,
    );
    if (!mounted) {
      return;
    }
    final opened = await reportWrongMailtoOpener(reportWrongMailtoUri(note));
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _status = opened
          ? UserFacingCopy.reportWrongEmailOpened
          : UserFacingCopy.reportWrongEmailUnavailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final packageId = _contextSnapshot.packageId?.trim() ?? '';
    final packageVersion = _contextSnapshot.packageVersion?.trim() ?? '';
    final packageLine = [
      if (packageId.isNotEmpty) packageId,
      if (packageVersion.isNotEmpty) packageVersion,
    ].join(' ');

    return Scaffold(
      key: const Key('report-wrong-screen'),
      appBar: AppBar(title: const Text(UserFacingCopy.reportWrongTitle)),
      body: ButlerPageBody(
        child: ListView(
          children: [
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    UserFacingCopy.reportWrongLead,
                    key: const Key('report-wrong-lead'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UserFacingCopy.reportWrongPrivacy,
                    key: const Key('report-wrong-privacy'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('What we will include'),
            const SizedBox(height: 8),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appliance category: ${_contextSnapshot.applianceCategory ?? '—'}',
                    key: const Key('report-wrong-category'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Package: ${packageLine.isEmpty ? '—' : packageLine}',
                    key: const Key('report-wrong-package'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stop reason: ${_contextSnapshot.stopReason ?? '—'}',
                    key: const Key('report-wrong-stop-reason'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last question id: ${_contextSnapshot.lastQuestionId ?? '—'}',
                    key: const Key('report-wrong-last-question'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Clue count: ${_contextSnapshot.clueCount}',
                    key: const Key('report-wrong-clue-count'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('report-wrong-note-field'),
              controller: _note,
              minLines: 3,
              maxLines: 6,
              maxLength: kReportWrongNoteMaxChars,
              decoration: const InputDecoration(
                labelText: UserFacingCopy.reportWrongNoteLabel,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryCta(
              key: const Key('report-wrong-save-email'),
              label: UserFacingCopy.reportWrongSaveEmail,
              semanticLabel: UserFacingCopy.reportWrongSaveEmail,
              onPressed: _busy ? null : _saveAndMaybeEmail,
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(
                _status!,
                key: const Key('report-wrong-status'),
                style: text.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReportWrongEntryCta extends StatelessWidget {
  const ReportWrongEntryCta({
    required this.dependencies,
    this.sessionId,
    this.label = UserFacingCopy.reportWrongThisWasWrong,
    super.key,
  });

  final AppDependencies dependencies;
  final String? sessionId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PrimaryCta(
      key: const Key('report-wrong-entry'),
      label: label,
      semanticLabel: label,
      style: PrimaryCtaStyle.outlined,
      icon: Icons.flag_outlined,
      onPressed: () {
        openReportWrongScreen(
          context: context,
          dependencies: dependencies,
          sessionId: sessionId,
        );
      },
    );
  }
}
