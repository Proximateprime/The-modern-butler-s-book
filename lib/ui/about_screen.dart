import 'package:flutter/material.dart';

import '../app_info.dart';
import '../helpers/knowledge_package_catalog.dart';
import '../helpers/user_facing_error.dart';
import 'app_dependencies.dart';
import 'product_chrome.dart';

/// App version, installed guides, Deterministic Core, and OSS licenses stub.
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    required this.dependencies,
    super.key,
  });

  final AppDependencies dependencies;

  String _installedVersion(BundledKnowledgePackage spec) {
    final installed = dependencies.knowledgePackageRepository.loadByCategory(
      spec.category,
    );
    if (installed.isEmpty) {
      return spec.version;
    }
    return installed.first.version;
  }

  String _installedId(BundledKnowledgePackage spec) {
    final installed = dependencies.knowledgePackageRepository.loadByCategory(
      spec.category,
    );
    if (installed.isEmpty) {
      return spec.id;
    }
    return installed.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      key: const Key('about-screen'),
      appBar: AppBar(title: const Text(UserFacingCopy.aboutTitle)),
      body: ButlerPageBody(
        child: ListView(
          children: [
            ListTile(
              key: const Key('about-app-version'),
              leading: const Icon(Icons.info_outline),
              title: Text('App $kAppVersionLabel'),
              subtitle: const Text(
                'Feature freeze $kFeatureFreezeDate — bugfixes only',
              ),
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('Deterministic Core'),
            const SizedBox(height: 8),
            PaperCard(
              child: Text(
                kDeterministicCoreOneLiner,
                key: const Key('about-deterministic-core'),
                style: text.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 16),
            const BookSectionLabel('Guides installed'),
            const SizedBox(height: 8),
            for (final spec in BundledKnowledgePackageCatalog.all)
              ListTile(
                key: Key('about-package-version-${spec.category}'),
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(spec.displayName),
                subtitle: Text(
                  knowledgePackageStatusLine(
                    id: _installedId(spec),
                    version: _installedVersion(spec),
                    installed: dependencies.hasInstalledPackageFor(
                      spec.category,
                    ),
                  ),
                  key: Key('about-package-id-${spec.category}'),
                ),
              ),
            const SizedBox(height: 16),
            const BookSectionLabel('Open source'),
            const SizedBox(height: 8),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    UserFacingCopy.aboutLicensesStub,
                    key: const Key('about-licenses-stub'),
                    style: text.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('about-licenses-button'),
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: "The Modern Butler's Book",
                        applicationVersion: kAppVersionLabel,
                      );
                    },
                    child: const Text(UserFacingCopy.aboutViewLicenses),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
