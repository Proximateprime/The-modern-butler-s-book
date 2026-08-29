import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../helpers/add_appliance_scan_copy.dart';
import '../helpers/appliance_barcode_parse.dart';
import '../helpers/rating_plate_parse.dart';
import '../helpers/degraded_mode.dart';
import '../helpers/user_facing_error.dart';
import '../models/appliance.dart';
import '../services/evidence_photo_picker.dart';
import 'app_dependencies.dart';
import 'error_banner.dart';
import 'evidence_photo_thumb.dart';
import 'permissions_help.dart';
import 'product_chrome.dart';

/// Add or edit dryer/washer/fridge/dishwasher: rating-plate scan or manual identity.
class AddApplianceScreen extends StatefulWidget {
  const AddApplianceScreen({
    required this.dependencies,
    required this.category,
    this.existing,
    super.key,
  });

  final AppDependencies dependencies;
  final String category;
  final Appliance? existing;

  @override
  State<AddApplianceScreen> createState() => _AddApplianceScreenState();
}

class _AddApplianceScreenState extends State<AddApplianceScreen> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _serial;
  late final TextEditingController _location;
  late final TextEditingController _ageYears;
  DateTime? _installationDate;
  String? _ratingLabelPhotoPath;
  ApplianceEnergySource _energySource = ApplianceEnergySource.unknown;
  WasherLoadStyle _washerLoadStyle = WasherLoadStyle.unknown;
  bool _busy = false;
  bool _cameraDenied = false;

  bool get _isWasher => widget.category == 'washer';

  bool get _isFridge => widget.category == 'fridge';

  bool get _isDishwasher => widget.category == 'dishwasher';

  String get _kindNoun => switch (widget.category) {
    'fridge' => 'fridge',
    'washer' => 'washer',
    'dishwasher' => 'dishwasher',
    _ => 'dryer',
  };

  bool get _isEdit => widget.existing != null;

  bool get _scanAvailable => addApplianceShowsScanAction(
    isWeb: kIsWeb,
    ocrAvailable: widget.dependencies.ratingPlateOcr.isAvailable,
    barcodeAvailable: widget.dependencies.barcodeScanner.isAvailable,
    cameraOff: _cameraOff,
  );

  bool get _cameraOff =>
      _cameraDenied || widget.dependencies.simulateMediaDenied;

  bool get _showScan => _scanAvailable && !_cameraOff;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _name = TextEditingController(text: existing.name);
      _brand = TextEditingController(text: existing.manufacturer);
      _model = TextEditingController(text: existing.modelNumber);
      _serial = TextEditingController(text: existing.serialNumber ?? '');
      _location = TextEditingController(text: existing.location);
      _ageYears = TextEditingController(
        text: existing.estimatedAgeYears?.toString() ?? '',
      );
      _installationDate = existing.installationDate;
      _ratingLabelPhotoPath = existing.ratingLabelPhotoPath;
      _energySource = existing.energySource;
      _washerLoadStyle = existing.washerLoadStyle;
      return;
    }
    final count =
        widget.dependencies
            .appliancesForCurrentHousehold()
            .where((item) => item.category == widget.category)
            .length +
        1;
    final defaultName = switch (widget.category) {
      'fridge' => count == 1 ? 'Kitchen Fridge' : 'Fridge $count',
      'washer' => count == 1 ? 'Laundry Room Washer' : 'Washer $count',
      'dishwasher' =>
        count == 1 ? 'Kitchen Dishwasher' : 'Dishwasher $count',
      _ => count == 1 ? 'Laundry Room Dryer' : 'Dryer $count',
    };
    _name = TextEditingController(text: defaultName);
    _brand = TextEditingController();
    _model = TextEditingController();
    _serial = TextEditingController();
    _location = TextEditingController(
      text:
          (_isFridge || _isDishwasher) ? 'Kitchen' : 'Laundry Room',
    );
    _ageYears = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _serial.dispose();
    _location.dispose();
    _ageYears.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await widget.dependencies.photoPicker.pick(
        origin: EvidencePhotoOrigin.camera,
      );
      if (!mounted || path == null) {
        return;
      }
      setState(() => _ratingLabelPhotoPath = path);
      final ocrText = await widget.dependencies.ratingPlateOcr.recognizeFile(
        path,
      );
      final barcodePayload = await widget.dependencies.barcodeScanner
          .decodeFile(path);
      if (!mounted) {
        return;
      }

      final fromOcr =
          ocrText == null || ocrText.trim().isEmpty
              ? const RatingPlateFields()
              : parseRatingPlateText(ocrText);
      final fromBarcode =
          barcodePayload == null || barcodePayload.trim().isEmpty
              ? const RatingPlateFields()
              : parseApplianceBarcodePayload(barcodePayload);

      final merged = _mergeIdentityFields(
        primary: fromOcr,
        fallback: fromBarcode,
      );

      if (merged.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.dependencies.ratingPlateOcr.isAvailable
                  ? UserFacingCopy.ratingPlateOcrEmpty
                  : widget.dependencies.barcodeScanner.isAvailable
                  ? UserFacingCopy.barcodeScanEmpty
                  : UserFacingCopy.ratingPlateOcrUnavailable,
            ),
          ),
        );
        return;
      }
      _applyIdentityFields(merged);
    } on PhotoPermissionDeniedException {
      if (!mounted) {
        return;
      }
      setState(() => _cameraDenied = true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _applyIdentityFields(RatingPlateFields parsed) {
    setState(() {
      if (parsed.manufacturer.isNotEmpty) {
        _brand.text = parsed.manufacturer;
      }
      if (parsed.modelNumber.isNotEmpty) {
        _model.text = parsed.modelNumber;
      }
      if (parsed.serialNumber.isNotEmpty) {
        _serial.text = parsed.serialNumber;
      }
      if (parsed.installationDate != null) {
        _installationDate = parsed.installationDate;
      }
    });
  }

  Future<void> _keepRatingPhoto() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await widget.dependencies.photoPicker.pick(
        origin: EvidencePhotoOrigin.camera,
      );
      if (!mounted || path == null) {
        return;
      }
      setState(() => _ratingLabelPhotoPath = path);
    } on PhotoPermissionDeniedException {
      if (!mounted) {
        return;
      }
      setState(() => _cameraDenied = true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  int? get _parsedAgeYears {
    final raw = _ageYears.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  void _save() {
    final existing = widget.existing;
    if (existing != null) {
      widget.dependencies.updateAppliance(
        appliance: existing,
        name: _name.text,
        manufacturer: _brand.text,
        modelNumber: _model.text,
        serialNumber: _serial.text,
        location: _location.text,
        installationDate: _installationDate,
        estimatedAgeYears: _parsedAgeYears,
        ratingLabelPhotoPath: _ratingLabelPhotoPath,
        energySource: _energySource,
        washerLoadStyle: _washerLoadStyle,
      );
    } else if (_isFridge) {
      widget.dependencies.addFridge(
        name: _name.text,
        manufacturer: _brand.text,
        modelNumber: _model.text,
        serialNumber: _serial.text,
        location: _location.text,
        installationDate: _installationDate,
        estimatedAgeYears: _parsedAgeYears,
        ratingLabelPhotoPath: _ratingLabelPhotoPath,
      );
    } else if (_isDishwasher) {
      widget.dependencies.addDishwasher(
        name: _name.text,
        manufacturer: _brand.text,
        modelNumber: _model.text,
        serialNumber: _serial.text,
        location: _location.text,
        installationDate: _installationDate,
        estimatedAgeYears: _parsedAgeYears,
        ratingLabelPhotoPath: _ratingLabelPhotoPath,
      );
    } else if (_isWasher) {
      widget.dependencies.addWasher(
        name: _name.text,
        manufacturer: _brand.text,
        modelNumber: _model.text,
        serialNumber: _serial.text,
        location: _location.text,
        installationDate: _installationDate,
        estimatedAgeYears: _parsedAgeYears,
        ratingLabelPhotoPath: _ratingLabelPhotoPath,
        washerLoadStyle: _washerLoadStyle,
      );
    } else {
      widget.dependencies.addDryer(
        name: _name.text,
        manufacturer: _brand.text,
        modelNumber: _model.text,
        serialNumber: _serial.text,
        location: _location.text,
        installationDate: _installationDate,
        estimatedAgeYears: _parsedAgeYears,
        ratingLabelPhotoPath: _ratingLabelPhotoPath,
        energySource: _energySource,
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickInstallDate() async {
    final now = widget.dependencies.nextTimestamp();
    final picked = await showDatePicker(
      context: context,
      initialDate: _installationDate ?? now,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _installationDate = DateTime.utc(picked.year, picked.month, picked.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit $_kindNoun' : 'Add $_kindNoun';
    return Scaffold(
      key: Key(_isEdit ? 'edit-appliance-screen' : 'add-appliance-screen'),
      appBar: AppBar(title: Text(title)),
      body: ButlerPageBody(
        child: ListView(
          children: [
            if (_cameraOff) ...[
              const DegradedModeBanner(
                kind: DegradedModeKind.cameraDenied,
              ),
              const SizedBox(height: 16),
            ],
            const BookSectionLabel('Rating plate'),
            const SizedBox(height: 8),
            if (_showScan) ...[
              const PermissionsHelpCard(
                compact: true,
                key: Key('add-appliance-permissions-help'),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              addApplianceIdentityHint(
                isWeb: kIsWeb,
                scanAvailable: _showScan,
              ),
              key: const Key('add-appliance-ocr-fallback'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_showScan) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('add-appliance-scan-rating-plate'),
                onPressed: _busy ? null : _scan,
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: const Text('Scan rating plate'),
              ),
            ] else if (!kIsWeb && !_cameraOff) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('add-appliance-keep-rating-photo'),
                onPressed: _busy ? null : _keepRatingPhoto,
                icon: const Icon(Icons.photo_outlined, size: 18),
                label: const Text(UserFacingCopy.addApplianceKeepRatingPhoto),
              ),
            ],
            if (_ratingLabelPhotoPath != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  EvidencePhotoThumb(
                    key: const Key('add-appliance-rating-photo'),
                    path: _ratingLabelPhotoPath!,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      UserFacingCopy.addApplianceRatingPhotoStaysLocal,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('add-appliance-clear-rating-photo'),
                    tooltip: 'Remove photo',
                    onPressed:
                        _busy
                            ? null
                            : () => setState(() => _ratingLabelPhotoPath = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const BookSectionLabel('Details'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('add-appliance-name-field'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('add-appliance-brand-field'),
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('add-appliance-model-field'),
              controller: _model,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('add-appliance-serial-field'),
              controller: _serial,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Serial',
                helperText: UserFacingCopy.addApplianceSerialHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('add-appliance-location-field'),
              controller: _location,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Location',
                helperText: UserFacingCopy.addApplianceLocationHint,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('add-appliance-install-date'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Install or purchase date'),
              subtitle: Text(
                _installationDate == null
                    ? 'Optional'
                    : _formatInstallDate(_installationDate!),
              ),
              trailing:
                  _installationDate == null
                      ? const Icon(Icons.event_outlined)
                      : IconButton(
                        key: const Key('add-appliance-install-date-clear'),
                        tooltip: 'Clear date',
                        onPressed:
                            _busy
                                ? null
                                : () => setState(() => _installationDate = null),
                        icon: const Icon(Icons.close),
                      ),
              onTap: _busy ? null : _pickInstallDate,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('add-appliance-age-field'),
              controller: _ageYears,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Approx. age (years)',
                helperText: UserFacingCopy.addApplianceAgeHint,
              ),
            ),
            if (widget.category == 'dryer') ...[
              const SizedBox(height: 16),
              const BookSectionLabel('Energy source'),
              const SizedBox(height: 8),
              Text(
                'Electric, gas, or not sure. Needed before heat-component checks.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in ApplianceEnergySource.values)
                    ChoiceChip(
                      key: Key('add-appliance-energy-${source.name}'),
                      label: Text(switch (source) {
                        ApplianceEnergySource.electric => 'Electric',
                        ApplianceEnergySource.gas => 'Gas',
                        ApplianceEnergySource.unknown => 'Not sure',
                      }),
                      selected: _energySource == source,
                      onSelected:
                          _busy
                              ? null
                              : (selected) {
                                if (selected) {
                                  setState(() => _energySource = source);
                                }
                              },
                    ),
                ],
              ),
            ],
            if (_isWasher) ...[
              const SizedBox(height: 16),
              const BookSectionLabel('Lid or door'),
              const SizedBox(height: 8),
              Text(
                'Top-load washers use a lid. Front-load washers use a door.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in WasherLoadStyle.values)
                    ChoiceChip(
                      key: Key('add-washer-load-${style.name}'),
                      label: Text(switch (style) {
                        WasherLoadStyle.topLoad => 'Top-load (lid)',
                        WasherLoadStyle.frontLoad => 'Front-load (door)',
                        WasherLoadStyle.unknown => 'Not sure',
                      }),
                      selected: _washerLoadStyle == style,
                      onSelected:
                          _busy
                              ? null
                              : (selected) {
                                if (selected) {
                                  setState(() => _washerLoadStyle = style);
                                }
                              },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('add-appliance-save-button'),
              onPressed: _busy ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Save appliance'),
            ),
          ],
        ),
      ),
    );
  }
}

RatingPlateFields _mergeIdentityFields({
  required RatingPlateFields primary,
  required RatingPlateFields fallback,
}) {
  return RatingPlateFields(
    manufacturer:
        primary.manufacturer.isNotEmpty
            ? primary.manufacturer
            : fallback.manufacturer,
    modelNumber:
        primary.modelNumber.isNotEmpty
            ? primary.modelNumber
            : fallback.modelNumber,
    serialNumber:
        primary.serialNumber.isNotEmpty
            ? primary.serialNumber
            : fallback.serialNumber,
    installationDate: primary.installationDate ?? fallback.installationDate,
  );
}

String _formatInstallDate(DateTime time) {
  final y = time.year.toString().padLeft(4, '0');
  final m = time.month.toString().padLeft(2, '0');
  final d = time.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
