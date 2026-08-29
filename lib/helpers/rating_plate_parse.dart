/// Parsed rating-plate fields. Empty strings / null mean "not found".
class RatingPlateFields {
  const RatingPlateFields({
    this.manufacturer = '',
    this.modelNumber = '',
    this.serialNumber = '',
    this.installationDate,
  });

  final String manufacturer;
  final String modelNumber;
  final String serialNumber;

  /// Install or purchase date when labeled on the plate or barcode payload.
  final DateTime? installationDate;

  bool get isEmpty =>
      manufacturer.isEmpty &&
      modelNumber.isEmpty &&
      serialNumber.isEmpty &&
      installationDate == null;
}

const _knownBrands = [
  'Whirlpool',
  'Maytag',
  'Kenmore',
  'KitchenAid',
  'Amana',
  'Samsung',
  'LG',
  'GE',
  'General Electric',
  'Hotpoint',
  'Frigidaire',
  'Electrolux',
  'Bosch',
  'Speed Queen',
  'Huebsch',
  'Crosley',
  'Roper',
  'Estate',
  'Inglis',
  'Admiral',
  'Magic Chef',
  'Haier',
  'Midea',
  'GE Profile',
];

final _modelLabel = RegExp(
  r'(?:model(?:\s*(?:no\.?|number|#))?|mod(?:el)?\.?)\s*[:.#]?\s*([A-Z0-9][A-Z0-9\-]{3,})',
  caseSensitive: false,
);

final _serialLabel = RegExp(
  r'(?:serial(?:\s*(?:no\.?|number|#))?|ser(?:ial)?\.?|s\/n|sn)\s*[:.#]?\s*([A-Z0-9][A-Z0-9\-]{4,})',
  caseSensitive: false,
);

final _brandLabel = RegExp(
  r'(?:brand|mfr|mfg|manufacturer)\s*[:.#]?\s*([A-Za-z][A-Za-z0-9 \-]{1,30})',
  caseSensitive: false,
);

/// Deterministic rating-plate parse. No ranking, no LLM.
RatingPlateFields parseRatingPlateText(String raw) {
  final text = raw.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) {
    return const RatingPlateFields();
  }

  var manufacturer = _firstGroup(_brandLabel, text);
  manufacturer = _cleanBrand(manufacturer);
  if (manufacturer.isEmpty) {
    manufacturer = _brandFromKnownList(text);
  }

  var model = _firstGroup(_modelLabel, text);
  model = _cleanToken(model);
  if (model.isEmpty) {
    model = _guessModelToken(text);
  }

  var serial = _firstGroup(_serialLabel, text);
  serial = _cleanToken(serial);
  if (serial.isNotEmpty &&
      model.isNotEmpty &&
      serial.toUpperCase() == model.toUpperCase()) {
    serial = '';
  }

  return RatingPlateFields(
    manufacturer: manufacturer,
    modelNumber: model,
    serialNumber: serial,
    installationDate: parseInstallOrPurchaseDate(text),
  );
}

/// Reads a labeled install/purchase date only. Manufacture dates are ignored.
DateTime? parseInstallOrPurchaseDate(String raw) {
  final match = _installPurchaseLabel.firstMatch(raw);
  if (match == null) {
    return null;
  }
  return parseInstallOrPurchaseDateValue(match.group(1) ?? '');
}

final _installPurchaseLabel = RegExp(
  r'(?:date\s+of\s+)?'
  r'(?:install(?:ed|ation)?|purchas(?:e|ed))'
  r'(?:\s*date)?'
  r'\s*[:.#]?\s*'
  r'([0-9]{4}[-/.][0-9]{1,2}[-/.][0-9]{1,2}|'
  r'[0-9]{1,2}[-/.][0-9]{1,2}[-/.][0-9]{2,4})',
  caseSensitive: false,
);

DateTime? parseInstallOrPurchaseDateValue(String raw) {
  final cleaned = raw.trim().replaceAll('.', '-').replaceAll('/', '-');
  final parts = cleaned.split('-').where((part) => part.isNotEmpty).toList();
  if (parts.length != 3) {
    return DateTime.tryParse(raw.trim())?.toUtc();
  }
  final a = int.tryParse(parts[0]);
  final b = int.tryParse(parts[1]);
  final c = int.tryParse(parts[2]);
  if (a == null || b == null || c == null) {
    return null;
  }
  try {
    if (parts[0].length == 4) {
      return DateTime.utc(a, b, c);
    }
    final year = c < 100 ? 2000 + c : c;
    return DateTime.utc(year, a, b);
  } catch (_) {
    return null;
  }
}

String _firstGroup(RegExp pattern, String text) {
  final match = pattern.firstMatch(text);
  return match?.group(1)?.trim() ?? '';
}

String _cleanToken(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '').trim();
}

String _cleanBrand(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final known = _brandFromKnownList(trimmed);
  if (known.isNotEmpty) {
    return known;
  }
  return trimmed
      .split(RegExp(r'\s+'))
      .take(3)
      .join(' ')
      .replaceAll(RegExp(r'[^A-Za-z0-9 \-]'), '')
      .trim();
}

String _brandFromKnownList(String text) {
  final lower = text.toLowerCase();
  var best = '';
  for (final brand in _knownBrands) {
    if (lower.contains(brand.toLowerCase()) && brand.length > best.length) {
      best = brand;
    }
  }
  return best;
}

String _guessModelToken(String text) {
  final tokens = RegExp(r'\b[A-Z]{2,}[A-Z0-9\-]{3,}\b').allMatches(text);
  for (final match in tokens) {
    final token = match.group(0) ?? '';
    if (_looksLikeSerialKeyword(token)) {
      continue;
    }
    if (_brandFromKnownList(token).isNotEmpty) {
      continue;
    }
    return token;
  }
  return '';
}

bool _looksLikeSerialKeyword(String token) {
  final upper = token.toUpperCase();
  return upper == 'SERIAL' ||
      upper == 'MODEL' ||
      upper == 'BRAND' ||
      upper.startsWith('MFG');
}
