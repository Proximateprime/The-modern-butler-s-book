import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_answer.dart';

/// Platform speech-to-text. Prefers on-device recognition when the OS allows.
///
/// Does not send audio to an LLM or any diagnostic service. If STT cannot
/// start (permission, missing engine, web without speech), it degrades.
class PlatformSpeechVoiceAnswer implements VoiceAnswerListener {
  PlatformSpeechVoiceAnswer({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  @override
  bool get isAvailable => !kIsWeb;

  @override
  Future<VoiceAnswerCapture> listen() async {
    try {
      final ready = await _speech.initialize();
      if (!ready) {
        return _mapError(_speech.lastError) ??
            VoiceAnswerCapture.permissionDenied;
      }

      var capture = await _listenOnce(onDevice: true);
      if (capture.kind == VoiceAnswerKind.unavailable) {
        capture = await _listenOnce(onDevice: false);
      }
      return capture;
    } catch (error) {
      return _mapThrown(error);
    }
  }

  Future<VoiceAnswerCapture> _listenOnce({required bool onDevice}) async {
    final completer = Completer<VoiceAnswerCapture>();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult || completer.isCompleted) {
            return;
          }
          final words = result.recognizedWords.trim();
          if (words.isEmpty) {
            completer.complete(VoiceAnswerCapture.cancelled);
            return;
          }
          completer.complete(VoiceAnswerCapture.heard(words));
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          partialResults: false,
          onDevice: onDevice,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => VoiceAnswerCapture.cancelled,
      );
    } catch (error) {
      return _mapThrown(error);
    } finally {
      try {
        await _speech.stop();
      } catch (_) {}
    }
  }

  VoiceAnswerCapture? _mapError(SpeechRecognitionError? error) {
    if (error == null) {
      return null;
    }
    final message = error.errorMsg.toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return VoiceAnswerCapture.permissionDenied;
    }
    return VoiceAnswerCapture.unavailable;
  }

  VoiceAnswerCapture _mapThrown(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return VoiceAnswerCapture.permissionDenied;
    }
    return VoiceAnswerCapture.unavailable;
  }
}
