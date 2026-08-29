import 'package:flutter/material.dart';

import '../helpers/degraded_mode.dart';
import '../helpers/knowledge_package_catalog.dart';
import '../helpers/user_facing_error.dart';
import 'app_dependencies.dart';
import 'error_banner.dart';
import 'guide_loading.dart';
import 'product_chrome.dart';

/// Install a bundled appliance guide from this device. No cloud download.
class PackageInstallScreen extends StatefulWidget {
  const PackageInstallScreen({
    required this.dependencies,
    required this.category,
    super.key,
  });

  final AppDependencies dependencies;
  final String category;

  @override
  State<PackageInstallScreen> createState() => _PackageInstallScreenState();
}

class _PackageInstallScreenState extends State<PackageInstallScreen> {
  bool _loading = false;

  BundledKnowledgePackage? get _spec =>
      BundledKnowledgePackageCatalog.forCategory(widget.category);

  Future<void> _install() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final installed = widget.dependencies.installBundledPackage(
      widget.category,
    );
    if (!mounted) {
      return;
    }
    if (!installed) {
      setState(() => _loading = false);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final name = spec?.displayName ?? 'Appliance guide';
    final online = widget.dependencies.isOnline;
    return Scaffold(
      key: const Key('package-install-screen'),
      appBar: AppBar(title: const Text('Install guide')),
      body: ButlerPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!online) ...[
              const DegradedModeBanner(
                kind: DegradedModeKind.offline,
                bannerKey: Key('package-install-offline'),
              ),
              const SizedBox(height: 16),
            ],
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const DegradedModeBanner(
              kind: DegradedModeKind.packageMissing,
              messageKey: Key('package-install-unavailable'),
            ),
            const SizedBox(height: 8),
            const Text(UserFacingCopy.packageInstallHint),
            const SizedBox(height: 24),
            if (_loading)
              const GuideLoadingIndicator()
            else
              FilledButton(
                key: const Key('package-install-local-button'),
                onPressed: spec == null ? null : _install,
                child: const Text(UserFacingCopy.packageInstallButton),
              ),
          ],
        ),
      ),
    );
  }
}
