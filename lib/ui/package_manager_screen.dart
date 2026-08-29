import 'package:flutter/material.dart';

import '../helpers/degraded_mode.dart';
import '../helpers/knowledge_package_catalog.dart';
import 'app_dependencies.dart';
import 'error_banner.dart';
import 'package_install_screen.dart';
import 'product_chrome.dart';

/// Local guide catalog: versions, install, update stub. No cloud.
class PackageManagerScreen extends StatefulWidget {
  const PackageManagerScreen({
    required this.dependencies,
    this.preferCategory,
    super.key,
  });

  final AppDependencies dependencies;

  /// When set, that family tile is listed first so Install is obvious.
  final String? preferCategory;

  @override
  State<PackageManagerScreen> createState() => _PackageManagerScreenState();
}

class _PackageManagerScreenState extends State<PackageManagerScreen> {
  Future<void> _checkForUpdates() async {
    final message = packageUpdatesStubMessage(
      online: widget.dependencies.isOnline,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('settings-updates-snackbar'),
        content: Text(message),
      ),
    );
  }

  Future<void> _installPackage(String category) async {
    final installed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => PackageInstallScreen(
              dependencies: widget.dependencies,
              category: category,
            ),
      ),
    );
    if (installed == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.dependencies.isOnline;
    final prefer = widget.preferCategory;
    final specs = [
      ...BundledKnowledgePackageCatalog.all.where(
        (spec) => prefer != null && spec.category == prefer,
      ),
      ...BundledKnowledgePackageCatalog.all.where(
        (spec) => prefer == null || spec.category != prefer,
      ),
    ];

    return Scaffold(
      key: const Key('package-manager-screen'),
      appBar: AppBar(title: const Text('Guides')),
      body: ButlerPageBody(
        child: ListView(
          children: [
            const BookSectionLabel('Guides on this device'),
            const SizedBox(height: 8),
            if (!online)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: DegradedModeBanner(
                  kind: DegradedModeKind.offline,
                  bannerKey: Key('settings-offline-banner'),
                ),
              ),
            for (final spec in specs)
              PackageGuideTile(
                spec: spec,
                installed: widget.dependencies.hasInstalledPackageFor(
                  spec.category,
                ),
                version: () {
                  final installedPkgs = widget.dependencies
                      .knowledgePackageRepository
                      .loadByCategory(spec.category);
                  return installedPkgs.isEmpty
                      ? spec.version
                      : installedPkgs.first.version;
                }(),
                onInstall: () => _installPackage(spec.category),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('settings-check-updates'),
              onPressed: _checkForUpdates,
              child: const Text('Check for updates'),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageGuideTile extends StatelessWidget {
  const PackageGuideTile({
    required this.spec,
    required this.installed,
    required this.version,
    required this.onInstall,
    super.key,
  });

  final BundledKnowledgePackage spec;
  final bool installed;
  final String version;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('settings-package-${spec.category}'),
      leading: Icon(
        installed ? Icons.check_circle_outline : Icons.download_outlined,
      ),
      title: Text(spec.displayName),
      subtitle: Text(
        knowledgePackageStatusLine(
          id: spec.id,
          version: version,
          installed: installed,
        ),
        key: Key('package-id-${spec.category}'),
      ),
      trailing:
          installed
              ? Text(
                  version,
                  key: Key('package-version-${spec.category}'),
                )
              : TextButton(
                  key: Key('settings-package-install-${spec.category}'),
                  onPressed: onInstall,
                  child: const Text('Install'),
                ),
    );
  }
}
