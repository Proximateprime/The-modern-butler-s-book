import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/package_resolve.dart';
import 'package:modern_butlers_book/helpers/visual_guide.dart';
import 'package:modern_butlers_book/knowledge/dryer_brand_overlays.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  late KnowledgePackageRepository repository;

  setUp(() {
    repository = KnowledgePackageRepository();
  });

  test('unknown dryer model falls back to universal base without crashing', () {
    final resolution = resolveKnowledgePackage(
      repository: repository,
      category: 'dryer',
      manufacturer: 'Demo Manufacturer',
      modelNumber: 'DEMO-DRYER-1',
    );

    expect(resolution.basePackage.id, 'dryer-core');
    expect(resolution.overlay, isNull);
    expect(resolution.usingGeneralGuide, isTrue);
    expect(resolution.coverageNotice, generalDryerGuideNotice);
    expect(resolution.package.id, 'dryer-core');
  });

  test('Whirlpool model prefix resolves whirlpool/maytag/kenmore overlay', () {
    final resolution = resolveKnowledgePackage(
      repository: repository,
      category: 'dryer',
      manufacturer: 'Whirlpool',
      modelNumber: 'WED5000DW',
    );

    expect(resolution.overlayId, 'dryer-overlay-whirlpool-maytag-kenmore');
    expect(resolution.usingGeneralGuide, isFalse);
    expect(resolution.accessNotes, isNotEmpty);
    expect(
      resolution.package.failureModes
          .firstWhere((mode) => mode.id == 'clogged-lint-pathway')
          .commonality,
      FailureModeCommonality.veryHigh,
    );
  });

  test('GE and Samsung prefixes pick distinct overlays', () {
    final ge = resolveKnowledgePackage(
      repository: repository,
      category: 'dryer',
      modelNumber: 'GTD45EASJWS',
    );
    final samsung = resolveKnowledgePackage(
      repository: repository,
      category: 'dryer',
      modelNumber: 'DVE45T6000W',
    );

    expect(ge.overlayId, 'dryer-overlay-ge-hotpoint');
    expect(samsung.overlayId, 'dryer-overlay-samsung');
    expect(ge.accessNotes.first, isNot(equals(samsung.accessNotes.first)));
    expect(
      visualGuidesForOverlay(
        guides: const [lintFilterGuide, accessPanelGuide],
        overlay: ge.overlay,
      ).firstWhere((guide) => guide.targetId == 'access-panel').imageAsset,
      'diagram:dryer-rear',
    );
  });

  test('missing overlay still returns the universal package', () {
    expect(overlaysForCategory('dryer'), hasLength(5));
    final resolution = resolveKnowledgePackage(
      repository: repository,
      category: 'dryer',
      manufacturer: 'Unknown Brand Co',
      modelNumber: 'ZZZ-NOPE-9',
    );
    expect(resolution.package, same(resolution.basePackage));
  });

  test('washer and dishwasher resolver returns thin universal, no brand tree', () {
    final washer = resolveKnowledgePackageForAppliance(
      repository: repository,
      appliance: Appliance(
        id: 'a1',
        householdId: 'h1',
        name: 'Washer',
        category: 'washer',
        manufacturer: 'LG',
        modelNumber: 'WM4000HWA',
        location: 'Laundry',
        status: ApplianceStatus.active,
        schemaVersion: '1.0',
        createdAt: DateTime.utc(2026, 8, 17),
        updatedAt: DateTime.utc(2026, 8, 17),
      ),
    );
    expect(washer.overlay, isNull);
    expect(washer.usingGeneralGuide, isTrue);
    expect(washer.basePackage.category, 'washer');

    final dw = resolveKnowledgePackage(
      repository: repository,
      category: 'dishwasher',
      manufacturer: 'Bosch',
      modelNumber: 'SHP78CM5N',
    );
    expect(dw.overlay, isNull);
    expect(dw.basePackage.category, 'dishwasher');
  });
}
