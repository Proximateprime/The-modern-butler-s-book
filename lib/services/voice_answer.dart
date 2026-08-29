/// Result of one speech-to-text capture. Never used for ranking or diagnosis.
enum VoiceAnswerKind { heard, permissionDenied, unavailable, cancelled }

class VoiceAnswerCapture {
  const VoiceAnswerCapture._(this.kind, this.transcript);

  final VoiceAnswerKind kind;
  final String transcript;

  bool get hasTranscript =>
      kind == VoiceAnswerKind.heard && transcript.trim().isNotEmpty;

  static const permissionDenied = VoiceAnswerCapture._(
    VoiceAnswerKind.permissionDenied,
    '',
  );
  static const unavailable = VoiceAnswerCapture._(
    VoiceAnswerKind.unavailable,
    '',
  );
  static const cancelled = VoiceAnswerCapture._(VoiceAnswerKind.cancelled, '');

  factory VoiceAnswerCapture.heard(String transcript) {
    return VoiceAnswerCapture._(VoiceAnswerKind.heard, transcript.trim());
  }
}

/// Speech → text only. Implementations must not send audio to a reasoning model.
abstract class VoiceAnswerListener {
  bool get isAvailable;
  Future<VoiceAnswerCapture> listen();
}

/// Default for tests and platforms where STT is not wired.
class SilentVoiceAnswerListener implements VoiceAnswerListener {
  const SilentVoiceAnswerListener();

  @override
  bool get isAvailable => false;

  @override
  Future<VoiceAnswerCapture> listen() async => VoiceAnswerCapture.unavailable;
}

/// Test double that returns a scripted capture and never touches the mic.
class ScriptedVoiceAnswerListener implements VoiceAnswerListener {
  ScriptedVoiceAnswerListener(this.capture, {this.available = true});

  final VoiceAnswerCapture capture;
  final bool available;

  @override
  bool get isAvailable => available;

  @override
  Future<VoiceAnswerCapture> listen() async => capture;
}
