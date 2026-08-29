/// Reads text from a rating-plate photo. Local only — never sent for diagnosis.
abstract class RatingPlateOcr {
  bool get isAvailable;

  Future<String?> recognizeFile(String imagePath);
}

/// Used when ML Kit is not linked (web / tests without a fake).
class UnavailableRatingPlateOcr implements RatingPlateOcr {
  const UnavailableRatingPlateOcr();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> recognizeFile(String imagePath) async => null;
}
