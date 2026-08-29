import 'package:flutter_test/flutter_test.dart';

import '../lib/models/knowledge_package.dart';
import '../lib/models/knowledge_package_ref.dart';
import '../lib/services/knowledge_package_repository.dart';

void main() {
  group('KnowledgePackageRepository', () {
    test('loads the seeded Dryer package by id and category', () {
      final repository = KnowledgePackageRepository();

      final byId = repository.loadById('dryer-core');
      final byCategory = repository.loadByCategory('dryer');

      expect(byId, isNotNull);
      expect(byId!.displayName, 'Dryer Knowledge Package');
      expect(byId.version, '1.4.2');
      expect(byId.status, KnowledgePackageStatus.production);
      expect(byCategory, hasLength(1));
      expect(byCategory.single, same(byId));
      expect(repository.listAvailable(), hasLength(4));
      expect(
        repository.loadByCategory('washer').single.id,
        'washer-core',
      );
      expect(
        repository.loadByCategory('fridge').single.id,
        'fridge-core',
      );
      expect(
        repository.loadByCategory('dishwasher').single.id,
        'dishwasher-core',
      );
    });

    test('Dryer package contains Batch 01+02 failure-mode depth', () {
      final package =
          KnowledgePackageRepository().loadById('dryer-core')!;

      expect(package.failureModes, hasLength(41));
      expect(package.symptoms, hasLength(8));
      expect(package.evidenceTemplates.length, greaterThanOrEqualTo(17));
      expect(package.safeChecks, hasLength(7));
      expect(
        package.failureModes.map((mode) => mode.id),
        containsAll([
          'restricted-exhaust-airflow',
          'thermal-fuse-open',
          'heating-element-failed',
          'broken-drive-belt',
          'door-switch-failure',
          'air-fluff-cycle-selected',
          'electrical-burning-smell-hazard',
          'gas-dryer-no-ignition-professional-only',
        ]),
      );
      expect(
        package.symptoms.map((symptom) => symptom.id),
        containsAll([
          'no-heat',
          'long-dry-time',
          'weak-exterior-airflow',
          'will-not-start',
        ]),
      );
      final failureModeIds =
          package.failureModes.map((mode) => mode.id).toSet();
      for (final template in package.evidenceTemplates) {
        expect(
          template.relatedFailureModeIds.every(failureModeIds.contains),
          isTrue,
        );
      }
      expect(
        () => package.failureModes.add(package.failureModes.first),
        throwsUnsupportedError,
      );
    });

    test('KnowledgePackageRef resolves to the real seeded package', () {
      final repository = KnowledgePackageRepository();
      final package = repository.loadById('dryer-core')!;
      final reference = KnowledgePackageRef.fromPackage(package);

      expect(repository.loadByRef(reference), same(package));
      expect(reference.id, package.id);
      expect(reference.applianceCategory, package.category);
      expect(reference.version, package.version);
    });
  });
}
