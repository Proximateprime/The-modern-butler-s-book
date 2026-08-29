import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import 'brand_mark.dart';
import 'product_chrome.dart';

/// Brief brand moment before Home or first-run. Presentation only.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const Key('splash-screen'),
      body: ButlerPageBody(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 96),
              const SizedBox(height: 24),
              const Wordmark(),
              const SizedBox(height: 8),
              Text(
                UserFacingCopy.brandTagline,
                key: const Key('splash-tagline'),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
