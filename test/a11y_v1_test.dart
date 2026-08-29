import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/color_contrast.dart';
import 'package:modern_butlers_book/ui/app_theme.dart';
import 'package:modern_butlers_book/ui/primary_cta.dart';

void main() {
  group('A11Y v1 contrast', () {
    test('Butler’s Book body and primary CTAs meet WCAG AA', () {
      final theme = buildAppTheme();
      final scheme = theme.colorScheme;
      expect(
        contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
      expect(
        contrastRatio(scheme.onSurface, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
      expect(
        contrastRatio(scheme.onSurfaceVariant, scheme.surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
      expect(
        contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(wcagAaLargeOrUi),
      );
    });

    test('Dark theme body and primary CTAs meet WCAG AA', () {
      final theme = buildDarkAppTheme();
      final scheme = theme.colorScheme;
      expect(
        contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
      expect(
        contrastRatio(scheme.onSurface, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
      expect(
        contrastRatio(scheme.onSurfaceVariant, scheme.surface),
        greaterThanOrEqualTo(wcagAaNormalText),
      );
      expect(
        contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(wcagAaLargeOrUi),
      );
    });
  });

  group('A11Y v1 primary CTAs', () {
    testWidgets('Start, Continue, Fixed, and Back expose semantic labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Column(
              children: [
                PrimaryCta(
                  key: const Key('cta-start'),
                  label: 'Start repair',
                  semanticLabel: PrimaryCtaSemantics.start,
                  onPressed: () {},
                ),
                PrimaryCta(
                  key: const Key('cta-continue'),
                  label: 'Continue repair',
                  semanticLabel: PrimaryCtaSemantics.continueAction,
                  onPressed: () {},
                ),
                PrimaryCta(
                  key: const Key('cta-fixed'),
                  label: 'Fixed — problem resolved',
                  semanticLabel: PrimaryCtaSemantics.fixed,
                  onPressed: () {},
                ),
                PrimaryCta(
                  key: const Key('cta-back'),
                  style: PrimaryCtaStyle.outlined,
                  icon: Icons.arrow_back,
                  label: 'Back',
                  semanticLabel: PrimaryCtaSemantics.back,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(PrimaryCtaSemantics.start), findsOneWidget);
      expect(
        find.bySemanticsLabel(PrimaryCtaSemantics.continueAction),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(PrimaryCtaSemantics.fixed), findsOneWidget);
      expect(find.bySemanticsLabel(PrimaryCtaSemantics.back), findsOneWidget);
    });

    testWidgets('large text scale does not clip primary CTAs', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  PrimaryCta(
                    label: 'Start repair',
                    semanticLabel: PrimaryCtaSemantics.start,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  PrimaryCta(
                    label: 'Continue repair',
                    semanticLabel: PrimaryCtaSemantics.continueAction,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  PrimaryCta(
                    label: 'Fixed — problem resolved',
                    semanticLabel: PrimaryCtaSemantics.fixed,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  PrimaryCta(
                    style: PrimaryCtaStyle.outlined,
                    icon: Icons.arrow_back,
                    label: 'Back',
                    semanticLabel: PrimaryCtaSemantics.back,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Start repair'), findsOneWidget);
      expect(find.text('Continue repair'), findsOneWidget);
      expect(find.text('Fixed — problem resolved'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      for (final label in [
        'Start repair',
        'Continue repair',
        'Fixed — problem resolved',
        'Back',
      ]) {
        final size = tester.getSize(find.text(label));
        expect(size.height, greaterThan(0));
        expect(size.width, greaterThan(0));
      }
    });
  });
}
