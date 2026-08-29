import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../helpers/degraded_mode.dart';
import '../helpers/evidence_prompt_match.dart';
import '../helpers/inspect_steps.dart';
import '../helpers/user_facing_error.dart';
import '../helpers/why_ask_this.dart';
import 'error_banner.dart';
import 'why_ask_this_tile.dart';

/// Inspect overlay: LOOK FOR, OK / Not OK, confirmation chips.
/// Optional camera is flashlight only — never diagnoses.
/// Location pictures are parked ([locationVisualAidsEnabled]).
class InspectStepCard extends StatefulWidget {
  const InspectStepCard({
    required this.step,
    required this.onChip,
    this.selectedAnswer,
    this.cameraStartDenied = false,
    this.offerLiveCamera,
    this.progressCurrent,
    this.progressTotal,
    this.whyAskBody,
    super.key,
  });

  final InspectStep step;
  final String? selectedAnswer;
  final ValueChanged<String> onChip;

  /// 1-based index and chain length. Shown as `Inspect 2 of 4`.
  final int? progressCurrent;
  final int? progressTotal;

  /// True when camera was already denied or Settings simulates deny.
  final bool cameraStartDenied;

  /// Optional flashlight-only camera. Null/false: no camera chrome.
  /// Production inspect never sets this — LOOK FOR + chips only.
  final bool? offerLiveCamera;

  /// Optional “Why ask this?” from package maps. Empty uses inspect fallback.
  final String? whyAskBody;

  @override
  State<InspectStepCard> createState() => _InspectStepCardState();
}

class _InspectStepCardState extends State<InspectStepCard> {
  CameraController? _controller;
  var _cameraDenied = false;
  var _cameraUnavailable = false;
  var _startingCamera = false;
  var _wantedCamera = false;

  InspectStep get _step => widget.step;

  bool get _viewOnly => _step.cameraMode == InspectCameraMode.viewOnly;

  bool get _explicitFlashlightCamera => widget.offerLiveCamera == true;

  bool get _offerLive =>
      _viewOnly &&
      _explicitFlashlightCamera &&
      !_cameraUnavailable &&
      !_cameraDenied &&
      !widget.cameraStartDenied;

  bool get _live =>
      _wantedCamera &&
      _controller != null &&
      _controller!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    _cameraDenied = widget.cameraStartDenied;
  }

  @override
  void didUpdateWidget(InspectStepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      _resetCamera();
      _cameraDenied = widget.cameraStartDenied;
      _cameraUnavailable = false;
      _wantedCamera = false;
    }
  }

  void _resetCamera() {
    _controller?.dispose();
    _controller = null;
    _startingCamera = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_startingCamera || !_viewOnly) {
      return;
    }
    setState(() {
      _startingCamera = true;
      _cameraDenied = false;
      _wantedCamera = true;
    });
    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 2),
      );
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _startingCamera = false;
            _cameraUnavailable = true;
            _wantedCamera = false;
          });
        }
        return;
      }
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      try {
        await controller.initialize().timeout(const Duration(seconds: 3));
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {
          _controller = controller;
          _startingCamera = false;
          _wantedCamera = true;
        });
      } catch (error) {
        await controller.dispose();
        rethrow;
      }
    } catch (error) {
      await _controller?.dispose();
      if (mounted) {
        setState(() {
          _controller = null;
          _startingCamera = false;
          _cameraDenied = _inspectCameraAccessDenied(error);
          _cameraUnavailable = !_cameraDenied;
          _wantedCamera = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = inspectStepChipLabels(_step);
    final normalizedSelected = normalizeObservationAnswer(widget.selectedAnswer);
    final showDenied = _viewOnly &&
        (_cameraDenied || widget.cameraStartDenied) &&
        _wantedCamera;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: Key('inspect-step-card-${_step.id}'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.progressCurrent != null &&
                widget.progressTotal != null &&
                widget.progressTotal! > 0) ...[
              Text(
                inspectProgressLabel(
                  current: widget.progressCurrent!,
                  total: widget.progressTotal!,
                ),
                key: const Key('inspect-progress'),
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(_step.title, style: textTheme.titleLarge),
            if (_step.safetyPreamble.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _step.safetyPreamble,
                key: const Key('inspect-safety-preamble'),
                style: textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              UserFacingCopy.inspectLookForHeading,
              key: const Key('inspect-look-for-heading'),
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _step.lookFor,
              key: const Key('inspect-look-for'),
              style: textTheme.bodyLarge,
            ),
            WhyAskThisTile(
              body: widget.whyAskBody ??
                  whyAskThisQuestion(inspectStep: _step).body,
            ),
            const SizedBox(height: 10),
            Text(
              UserFacingCopy.inspectOkLooksLike,
              style: textTheme.labelLarge,
            ),
            Text(
              _step.okMeans,
              key: const Key('inspect-ok-means'),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              UserFacingCopy.inspectNotOkLooksLike,
              style: textTheme.labelLarge,
            ),
            Text(
              _step.notOkMeans,
              key: const Key('inspect-not-ok-means'),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_viewOnly &&
                (_explicitFlashlightCamera || _live || showDenied)) ...[
              if (showDenied) ...[
                const SizedBox(height: 8),
                const DegradedModeBanner(
                  kind: DegradedModeKind.cameraDenied,
                ),
              ],
              if (_live) ...[
                const SizedBox(height: 8),
                Text(
                  UserFacingCopy.inspectCameraDoesNotDiagnose,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  key: const Key('inspect-camera-preview'),
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                _controller!.value.previewSize?.height ?? 720,
                            height:
                                _controller!.value.previewSize?.width ?? 1280,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Material(
                            color: const Color(0xCC1B2430),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${UserFacingCopy.inspectLookForHeading}: ${_step.lookFor}',
                                key: const Key('inspect-camera-overlay-copy'),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF4F7FA),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('inspect-hide-camera'),
                  onPressed: () {
                    _resetCamera();
                    setState(() => _wantedCamera = false);
                  },
                  child: const Text('Hide camera'),
                ),
              ] else if (!showDenied && _offerLive) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  key: const Key('inspect-use-camera'),
                  onPressed: _startingCamera ? null : _startCamera,
                  child: Text(
                    _startingCamera
                        ? 'Starting camera…'
                        : UserFacingCopy.inspectUseCameraWhileILook,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chips)
                  _InspectChipButton(
                    choice: chip,
                    isSelected:
                        normalizedSelected != null &&
                        normalizedSelected ==
                            normalizeObservationAnswer(
                              _step.answerForChip(chip),
                            ),
                    onPressed: () => widget.onChip(chip),
                    keySuffix: inspectChipKeySuffix(chip),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _inspectCameraAccessDenied(Object error) {
  final raw = error.toString().toLowerCase();
  if (error is CameraException) {
    final code = error.code.toLowerCase();
    final description = (error.description ?? '').toLowerCase();
    if (code.contains('denied') ||
        code.contains('access') ||
        description.contains('denied')) {
      return true;
    }
  }
  return raw.contains('permission') && raw.contains('denied');
}

class _InspectChipButton extends StatelessWidget {
  const _InspectChipButton({
    required this.choice,
    required this.isSelected,
    required this.onPressed,
    required this.keySuffix,
  });

  final String choice;
  final bool isSelected;
  final VoidCallback onPressed;
  final String keySuffix;

  @override
  Widget build(BuildContext context) {
    final key = Key('inspect-chip-$keySuffix');
    final child = Text(choice);
    if (isSelected) {
      return FilledButton.tonal(
        key: key,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        onPressed: onPressed,
        child: child,
      );
    }
    return OutlinedButton(
      key: key,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
