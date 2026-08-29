import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'rating_plate_ocr.dart';

RatingPlateOcr createRatingPlateOcr() => MlKitRatingPlateOcr();

/// Android/iOS ML Kit OCR. Other platforms report unavailable.
class MlKitRatingPlateOcr implements RatingPlateOcr {
  MlKitRatingPlateOcr({TextRecognizer Function()? recognizerFactory})
    : _recognizerFactory =
          recognizerFactory ??
          (() => TextRecognizer(script: TextRecognitionScript.latin));

  final TextRecognizer Function() _recognizerFactory;

  @override
  bool get isAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<String?> recognizeFile(String imagePath) async {
    if (!isAvailable) {
      return null;
    }
    final path = imagePath.trim();
    if (path.isEmpty) {
      return null;
    }
    final recognizer = _recognizerFactory();
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
