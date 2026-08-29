/// Camera treatment for one inspect step. Live CV is out of scope.
enum InspectCameraMode {
  none,
  viewOnly,
}

/// Guide rectangle on a **diagram** only. Never live tracking or diagnosis.
///
/// Coordinates are 0–1 fractions of the diagram viewport.
class InspectFrameHint {
  const InspectFrameHint({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.label = '',
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// Caption drawn with the rectangle (e.g. `Lint filter`).
  final String label;
}

/// Chip labels for inspect answers. Stored evidence uses [evidenceAnswerByChip].
const String inspectMatchesOkChip = 'Matches / OK';
const String inspectDoesntMatchChip = "Doesn't match / Not OK";
const String inspectCantSeeChip = "Can't see";

/// Ordered visual check authored in package / close-path data.
///
/// Answers are recorded as normal structured evidence against
/// [evidenceTemplateId] so ranking and easy-check gates stay on one path.
class InspectStep {
  const InspectStep({
    required this.id,
    required this.title,
    required this.safetyPreamble,
    required this.lookFor,
    required this.okMeans,
    required this.notOkMeans,
    required this.diagramAsset,
    required this.cameraMode,
    required this.appliesTo,
    required this.evidenceTemplateId,
    required this.evidenceAnswerByChip,
    this.failureModeIds = const [],
    this.relatedEasyCheckTemplateId,
    this.beginnerSafe = true,
    this.noLiveElectrical = true,
    this.frameHint,
  });

  final String id;
  final String title;
  final String safetyPreamble;
  final String lookFor;
  final String okMeans;
  final String notOkMeans;
  final String diagramAsset;
  final InspectCameraMode cameraMode;
  final String appliesTo;
  final String evidenceTemplateId;
  final Map<String, String> evidenceAnswerByChip;
  final List<String> failureModeIds;
  final String? relatedEasyCheckTemplateId;
  final bool beginnerSafe;
  final bool noLiveElectrical;

  /// Optional typical-area rectangle. Drawn on diagram assets only.
  final InspectFrameHint? frameHint;

  String? answerForChip(String chip) => evidenceAnswerByChip[chip];
}
