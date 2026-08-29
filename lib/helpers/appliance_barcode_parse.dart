import 'dart:convert';

import 'rating_plate_parse.dart';

final _digitsOnly = RegExp(r'^\d{8,14}$');
final _modelLike = RegExp(r'^[A-Z]{1,6}[A-Z0-9\-]{3,20}$');

/// Maps a barcode/QR payload onto the same identity fields as rating-plate OCR.
///
/// UPC/EAN digits and unknown payloads stay empty so the household can type.
RatingPlateFields parseApplianceBarcodePayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const RatingPlateFields();
  }

  final fromJson = _fromJson(trimmed);
  if (fromJson != null && !fromJson.isEmpty) {
    return fromJson;
  }

  final fromUrl = _fromUrl(trimmed);
  if (fromUrl != null && !fromUrl.isEmpty) {
    return fromUrl;
  }

  if (_digitsOnly.hasMatch(trimmed.replaceAll(RegExp(r'\s'), ''))) {
    return const RatingPlateFields();
  }

  final plate = parseRatingPlateText(trimmed);
  if (!plate.isEmpty) {
    return plate;
  }

  final token = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '').toUpperCase();
  if (_modelLike.hasMatch(token) && _hasLetterAndDigit(token)) {
    return RatingPlateFields(modelNumber: token);
  }

  return const RatingPlateFields();
}

bool _hasLetterAndDigit(String value) {
  return RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[0-9]').hasMatch(value);
}

RatingPlateFields? _fromJson(String raw) {
  if (!raw.startsWith('{')) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(decoded);
    final dateRaw = _pick(map, const [
      'installDate',
      'installationDate',
      'purchaseDate',
      'purchasedAt',
      'installed',
    ]);
    return RatingPlateFields(
      manufacturer: _pick(map, const ['brand', 'manufacturer', 'mfr']),
      modelNumber: _pick(map, const [
        'model',
        'modelNumber',
        'model_number',
        'modelNo',
      ]),
      serialNumber: _pick(map, const [
        'serial',
        'serialNumber',
        'serial_number',
        'sn',
      ]),
      installationDate: parseInstallOrPurchaseDateValue(dateRaw),
    );
  } catch (_) {
    return null;
  }
}

RatingPlateFields? _fromUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
    return null;
  }
  final params = <String, String>{};
  uri.queryParameters.forEach((key, value) {
    params[key.toLowerCase()] = value;
  });
  var manufacturer = params['brand'] ?? params['manufacturer'] ?? params['mfr'] ?? '';
  var model =
      params['model'] ??
      params['modelnumber'] ??
      params['model_number'] ??
      params['modelno'] ??
      '';
  var serial =
      params['serial'] ??
      params['serialnumber'] ??
      params['serial_number'] ??
      params['sn'] ??
      '';

  if (model.isEmpty) {
    final segment = uri.pathSegments.where((part) => part.trim().isNotEmpty);
    if (segment.isNotEmpty) {
      final last = segment.last.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '').toUpperCase();
      if (_modelLike.hasMatch(last) && _hasLetterAndDigit(last)) {
        model = last;
      }
    }
  }

  manufacturer = manufacturer.trim();
  model = model.trim();
  serial = serial.trim();
  final dateRaw =
      params['installdate'] ??
      params['installationdate'] ??
      params['purchasedate'] ??
      params['purchasedat'] ??
      params['installed'] ??
      '';
  final installationDate = parseInstallOrPurchaseDateValue(dateRaw);
  if (manufacturer.isEmpty &&
      model.isEmpty &&
      serial.isEmpty &&
      installationDate == null) {
    return const RatingPlateFields();
  }
  return RatingPlateFields(
    manufacturer: manufacturer,
    modelNumber: model.toUpperCase(),
    serialNumber: serial.toUpperCase(),
    installationDate: installationDate,
  );
}

String _pick(Map<String, dynamic> map, List<String> keys) {
  final wanted = keys.map((key) => key.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (!wanted.contains(entry.key.toLowerCase())) {
      continue;
    }
    final value = entry.value;
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}
