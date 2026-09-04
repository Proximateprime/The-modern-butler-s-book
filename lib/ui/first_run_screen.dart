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
/// Skip never acknowledges the separate Safety disclaimer ("I understand").
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({required this.onFinished, super.key});

  final Future<void> Function() onFinished;

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  int _page = 0;
  bool _busy = false;

  bool get _last => _page >= _firstRunSlides.length - 1;

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

  void _advance() {
    if (_busy) {
      return;
    }
    if (_last) {
      _finish();
      return;
    }
    setState(() => _page += 1);
  }

  @override
  Widget build(BuildContext context) {
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
          // First pointer-down must complete Skip on page 1. Do not autofocus
          // Skip — that ate the first Pages click (focus, then activate).
          // Pack #13 class: 48px target, no Transform, view keeps focus.
          Listener(
            key: const Key('first-run-skip-button'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) {
              if (!_busy) {
                _finish();
              }
            },
            child: InkWell(
              canRequestFocus: false,
              onTap: _busy ? null : _finish,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: Text('Skip')),
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom inset only — AppBar already clears the status bar. No Transform:
      // Flutter web pointer mapping must stay 1:1 with the painted surface.
      body: SafeArea(
        top: false,
        child: Semantics(
          key: _last
              ? const Key('first-run-done-button')
              : const Key('first-run-next-button'),
          button: true,
          label: _last
              ? PrimaryCtaSemantics.start
              : PrimaryCtaSemantics.continueAction,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _busy ? null : _advance,
            child: SizedBox.expand(
              child: ButlerPageBody(
                child: _FirstRunPage(
                  key: slide.pageKey,
                  title: slide.title,
                  body: slide.body,
                  showGreeting: _page == 0,
                ),
              ),
            ),
          ),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showGreeting) ...[
            Text(
              UserFacingCopy.firstRunGreeting,
              style: text.headlineSmall,
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
