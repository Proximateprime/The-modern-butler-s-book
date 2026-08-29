import 'package:flutter/material.dart';

import '../helpers/user_facing_error.dart';
import 'primary_cta.dart';
import 'product_chrome.dart';

class _FirstRunSlide {
  const _FirstRunSlide({
    required this.pageKey,
    required this.title,
    required this.body,
  });

  final Key pageKey;
  final String title;
  final String body;
}

const List<_FirstRunSlide> _firstRunSlides = [
  _FirstRunSlide(
    pageKey: Key('first-run-page-what'),
    title: UserFacingCopy.firstRunDoesTitle,
    body: UserFacingCopy.firstRunDoesBody,
  ),
  _FirstRunSlide(
    pageKey: Key('first-run-page-not'),
    title: UserFacingCopy.firstRunDoesNotTitle,
    body: UserFacingCopy.firstRunDoesNotBody,
  ),
  _FirstRunSlide(
    pageKey: Key('first-run-page-privacy'),
    title: UserFacingCopy.firstRunPrivacyTitle,
    body: UserFacingCopy.firstRunPrivacyBody,
  ),
];

/// First-launch greeting. Skip and the last page both complete it for good.
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({required this.onFinished, super.key});

  final Future<void> Function() onFinished;

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  int _page = 0;
  bool _busy = false;
  final FocusNode _skipFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // First tap after splash must land. Autofocus + explicit post-frame
    // focus so the Skip control is the first-frame gesture target.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _skipFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _skipFocus.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onFinished();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page >= _firstRunSlides.length - 1;
    final slide = _firstRunSlides[_page];

    return Scaffold(
      key: const Key('first-run-screen'),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Wordmark(compact: true),
        ),
        actions: [
          TextButton(
            key: const Key('first-run-skip-button'),
            focusNode: _skipFocus,
            autofocus: true,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: _busy ? null : _finish,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: ButlerPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _FirstRunPage(
                key: slide.pageKey,
                title: slide.title,
                body: slide.body,
                showGreeting: _page == 0,
              ),
            ),
            if (!last)
              PrimaryCta(
                key: const Key('first-run-next-button'),
                label: UserFacingCopy.firstRunContinue,
                semanticLabel: PrimaryCtaSemantics.continueAction,
                style: PrimaryCtaStyle.outlined,
                onPressed: _busy ? null : () => setState(() => _page += 1),
              )
            else
              PrimaryCta(
                key: const Key('first-run-done-button'),
                label: 'Get started',
                semanticLabel: PrimaryCtaSemantics.start,
                onPressed: _busy ? null : _finish,
              ),
          ],
        ),
      ),
    );
  }
}

class _FirstRunPage extends StatelessWidget {
  const _FirstRunPage({
    required this.title,
    required this.body,
    required this.showGreeting,
    super.key,
  });

  final String title;
  final String body;
  final bool showGreeting;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showGreeting) ...[
            Text(
              UserFacingCopy.firstRunGreeting,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
          ],
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge),
                const SizedBox(height: 12),
                Text(body, style: text.bodyLarge?.copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
