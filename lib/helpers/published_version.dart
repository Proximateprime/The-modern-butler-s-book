import '../app_info.dart';

/// Parse Flutter `version.json` (`version` + `build_number`).
({String? version, String? buildNumber}) parsePublishedVersionJson(
  String raw,
) {
  final versionMatch = RegExp(r'"version"\s*:\s*"([^"]*)"').firstMatch(raw);
  final buildMatch =
      RegExp(r'"build_number"\s*:\s*"([^"]*)"').firstMatch(raw);
  return (
    version: versionMatch?.group(1),
    buildNumber: buildMatch?.group(1),
  );
}

/// Settings warning when the running binary and hosted `version.json` differ.
String? publishedBuildMismatchLine({
  required String appVersion,
  required String appBuildNumber,
  required String? publishedVersion,
  required String? publishedBuildNumber,
}) {
  if (publishedVersion == null ||
      publishedBuildNumber == null ||
      publishedVersion.isEmpty ||
      publishedBuildNumber.isEmpty) {
    return null;
  }
  if (publishedVersion == appVersion && publishedBuildNumber == appBuildNumber) {
    return null;
  }
  return 'This copy is $appVersion+$appBuildNumber. The hosted book reports '
      '$publishedVersion+$publishedBuildNumber. Refresh if this looks stale.';
}

String publishedVersionCacheBustQuery() => 'v=$kAppVersionLabel';
