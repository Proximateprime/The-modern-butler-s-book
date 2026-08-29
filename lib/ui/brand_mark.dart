import 'package:flutter/material.dart';

/// In-app brand mark. Uses the local app icon asset.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  static const assetPath = 'assets/brand/app_icon.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        assetPath,
        key: const Key('brand-mark'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            key: const Key('brand-mark'),
            width: size,
            height: size,
            child: Icon(Icons.menu_book_outlined, size: size * 0.72),
          );
        },
      ),
    );
  }
}
