import 'package:flutter/material.dart';

import 'app_theme.dart';

ButlerColors butlerColors(BuildContext context) {
  return Theme.of(context).extension<ButlerColors>() ??
      const ButlerColors(
        paper: Color(0xFFFAF6EF),
        ink: Color(0xFF2A241C),
        muted: Color(0xFF6E6256),
        rule: Color(0xFFDDD2C3),
        safetyCalm: Color(0xFF3E5C4E),
        safetyWatch: Color(0xFF6B4E0E),
        safetyCaution: Color(0xFFC45E1A),
        safetyStop: Color(0xFFB42318),
      );
}

/// Narrow, calm page column used on Home and Session.
class ButlerPageBody extends StatelessWidget {
  const ButlerPageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 32),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ButlerSpace.maxContentWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small caps-style section label.
class BookSectionLabel extends StatelessWidget {
  const BookSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

/// Soft paper panel used across home and session.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tint,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = butlerColors(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emphasized
              ? scheme.primary.withValues(alpha: 0.45)
              : colors.rule,
          width: emphasized ? 1.4 : 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Short empty-state copy, never a debug dump.
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    );
  }
}

enum SafetyLightKind { calm, watch, caution, stop }

/// Maps existing session signals onto the four safety colors. Presentation only.
SafetyLightKind safetyLightForSession({
  required bool safetyStop,
  required bool closePathActive,
  required String safetyLevel,
}) {
  if (safetyStop) {
    return SafetyLightKind.stop;
  }
  final level = safetyLevel.toLowerCase();
  if (level.contains('high') ||
      level.contains('hazard') ||
      level.contains('stop')) {
    return SafetyLightKind.stop;
  }
  if (closePathActive) {
    return SafetyLightKind.caution;
  }
  if (level.contains('caution') ||
      level.contains('medium') ||
      level.contains('watch')) {
    return SafetyLightKind.watch;
  }
  return SafetyLightKind.calm;
}

/// Subtle status lamp — not a dashboard gauge.
class SafetyStatusLight extends StatelessWidget {
  const SafetyStatusLight({super.key, required this.kind});

  final SafetyLightKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = butlerColors(context);
    final color = switch (kind) {
      SafetyLightKind.calm => colors.safetyCalm,
      SafetyLightKind.watch => colors.safetyWatch,
      SafetyLightKind.caution => colors.safetyCaution,
      SafetyLightKind.stop => colors.safetyStop,
    };
    final label = switch (kind) {
      SafetyLightKind.calm => 'Safe to continue',
      SafetyLightKind.watch => 'Stay alert',
      SafetyLightKind.caution => 'Check carefully',
      SafetyLightKind.stop => 'Stop',
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return Text(
      compact ? 'Butler’s Book' : 'The Modern Butler’s Book',
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: on,
        height: 1.2,
      ),
    );
  }
}

/// Fixed session header: appliance, safety, clues, Exit.
class SessionChromeBar extends StatelessWidget implements PreferredSizeWidget {
  const SessionChromeBar({
    super.key,
    required this.applianceName,
    required this.safetyKind,
    required this.clueSummary,
    required this.stateLabel,
    required this.onExit,
    this.memberLabel,
  });

  final String applianceName;
  final SafetyLightKind safetyKind;
  final String clueSummary;
  final String stateLabel;
  final VoidCallback onExit;
  final String? memberLabel;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 72);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppBar(
      title: Text(applianceName),
      actions: [
        TextButton(
          key: const Key('session-exit-button'),
          onPressed: onExit,
          child: const Text('Exit'),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(child: SafetyStatusLight(kind: safetyKind)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clueSummary,
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stateLabel,
                key: const Key('current-session-state'),
                style: text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
