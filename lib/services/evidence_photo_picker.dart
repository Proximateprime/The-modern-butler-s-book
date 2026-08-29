import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/user_facing_error.dart';

/// Where a household photo is chosen from. Local capture only.
enum EvidencePhotoOrigin { gallery, camera }

/// Picks a local image path. Does not diagnose, rank, or send to an LLM.
abstract class EvidencePhotoPicker {
  Future<String?> pick({required EvidencePhotoOrigin origin});
}

/// Production picker using the device gallery or camera.
class ImagePickerEvidencePhotoPicker implements EvidencePhotoPicker {
  ImagePickerEvidencePhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick({required EvidencePhotoOrigin origin}) async {
    try {
      final file = await _picker.pickImage(
        source:
            origin == EvidencePhotoOrigin.camera
                ? ImageSource.camera
                : ImageSource.gallery,
        requestFullMetadata: false,
      );
      final path = file?.path.trim();
      if (path == null || path.isEmpty) {
        return null;
      }
      return path;
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      if (code.contains('denied') ||
          code.contains('permission') ||
          message.contains('denied') ||
          message.contains('permission')) {
        throw const PhotoPermissionDeniedException();
      }
      throw StateError(UserFacingCopy.genericError);
    }
  }
}
