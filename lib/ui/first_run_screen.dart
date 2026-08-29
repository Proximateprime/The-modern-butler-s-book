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

/// First-launch intro. Skip and Done both complete it for good.
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
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
              ),
            ),
            Text(
              '${_page + 1} of ${_firstRunSlides.length}',
              key: const Key('first-run-progress'),
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (!last)
              FilledButton(
                key: const Key('first-run-next-button'),
                onPressed:
                    _busy
                        ? null
                        : () => setState(() => _page += 1),
                child: const Text('Next'),
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
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: text.headlineSmall),
          const SizedBox(height: 16),
          Text(body, style: text.bodyLarge?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}
