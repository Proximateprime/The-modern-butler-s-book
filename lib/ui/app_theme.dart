import 'package:flutter/material.dart';

/// Cream-paper “Butler’s Book” light theme and a simple dark companion.
///
/// Visual only — no diagnostic behavior.
class ButlerColors extends ThemeExtension<ButlerColors> {
  const ButlerColors({
    required this.paper,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.safetyCalm,
    required this.safetyWatch,
    required this.safetyCaution,
    required this.safetyStop,
  });

  final Color paper;
  final Color ink;
  final Color muted;
  final Color rule;
  final Color safetyCalm;
  final Color safetyWatch;
  final Color safetyCaution;
  final Color safetyStop;

  @override
  ButlerColors copyWith({
    Color? paper,
    Color? ink,
    Color? muted,
    Color? rule,
    Color? safetyCalm,
    Color? safetyWatch,
    Color? safetyCaution,
    Color? safetyStop,
  }) {
    return ButlerColors(
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      rule: rule ?? this.rule,
      safetyCalm: safetyCalm ?? this.safetyCalm,
      safetyWatch: safetyWatch ?? this.safetyWatch,
      safetyCaution: safetyCaution ?? this.safetyCaution,
      safetyStop: safetyStop ?? this.safetyStop,
    );
  }

  @override
  ButlerColors lerp(ThemeExtension<ButlerColors>? other, double t) {
    if (other is! ButlerColors) {
      return this;
    }
    return ButlerColors(
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      rule: Color.lerp(rule, other.rule, t) ?? rule,
      safetyCalm: Color.lerp(safetyCalm, other.safetyCalm, t) ?? safetyCalm,
      safetyWatch: Color.lerp(safetyWatch, other.safetyWatch, t) ?? safetyWatch,
      safetyCaution:
          Color.lerp(safetyCaution, other.safetyCaution, t) ?? safetyCaution,
      safetyStop: Color.lerp(safetyStop, other.safetyStop, t) ?? safetyStop,
    );
  }
}

/// Spacing scale used across Home, Session, and Guidance.
abstract final class ButlerSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20;
  static const double maxContentWidth = 640;
}

/// Persisted appearance. Default is the cream-paper Butler’s Book look.
enum AppThemeChoice {
  modern,
  butlersBook,
  dark;

  static AppThemeChoice parse(String? raw) {
    for (final value in AppThemeChoice.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return AppThemeChoice.butlersBook;
  }

  String get label => switch (this) {
    AppThemeChoice.modern => 'Modern',
    AppThemeChoice.butlersBook => "Butler’s Book",
    AppThemeChoice.dark => 'Dark',
  };

  bool get isDark => this == AppThemeChoice.dark;
}

ThemeData buildAppTheme() => _buildTheme(_ThemePalette.butlersBook);

ThemeData buildModernTheme() => _buildTheme(_ThemePalette.modern);

ThemeData buildDarkAppTheme() => _buildTheme(_ThemePalette.dark);

enum _ThemePalette { modern, butlersBook, dark }

ThemeData _buildTheme(_ThemePalette palette) {
  final isDark = palette == _ThemePalette.dark;
  final isModern = palette == _ThemePalette.modern;
  const cream = Color(0xFFF3EDE3);
  const paper = Color(0xFFFAF6EF);
  const ink = Color(0xFF2A241C);
  const muted = Color(0xFF6E6256);
  const rule = Color(0xFFDDD2C3);
  const accent = Color(0xFF3E5C4E);
  const modernCanvas = Color(0xFFF4F6F8);
  const modernPaper = Color(0xFFFFFFFF);
  const modernInk = Color(0xFF1B1F24);
  const modernMuted = Color(0xFF5C6670);
  const modernRule = Color(0xFFD5DCE3);
  const modernAccent = Color(0xFF2F6FED);
  const darkCanvas = Color(0xFF141618);
  const darkPaper = Color(0xFF1C2022);
  const darkInk = Color(0xFFE6E2DB);
  const darkMuted = Color(0xFFA39A90);
  const darkRule = Color(0xFF3A4144);
  const darkAccent = Color(0xFF8FB4A4);

  final Color canvas;
  final Color panel;
  final Color on;
  final Color faint;
  final Color line;
  final Color brand;
  if (isDark) {
    canvas = darkCanvas;
    panel = darkPaper;
    on = darkInk;
    faint = darkMuted;
    line = darkRule;
    brand = darkAccent;
  } else if (isModern) {
    canvas = modernCanvas;
    panel = modernPaper;
    on = modernInk;
    faint = modernMuted;
    line = modernRule;
    brand = modernAccent;
  } else {
    canvas = cream;
    panel = paper;
    on = ink;
    faint = muted;
    line = rule;
    brand = accent;
  }

  final brightness = isDark ? Brightness.dark : Brightness.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: brand,
    onPrimary: isDark ? const Color(0xFF102018) : Colors.white,
    secondary: isDark ? const Color(0xFF9AA7A0) : const Color(0xFF5A6B62),
    onSecondary: isDark ? darkCanvas : Colors.white,
    secondaryContainer:
        isDark ? const Color(0xFF2A3330) : const Color(0xFFE7EFE9),
    onSecondaryContainer: on,
    primaryContainer:
        isDark ? const Color(0xFF24332C) : const Color(0xFFDCE8E1),
    onPrimaryContainer: on,
    surface: panel,
    onSurface: on,
    onSurfaceVariant: faint,
    outline: line,
    error: const Color(0xFFB42318),
    onError: Colors.white,
    errorContainer:
        isDark ? const Color(0xFF3A1C18) : const Color(0xFFF8E6E2),
    onErrorContainer:
        isDark ? const Color(0xFFF0C7C0) : const Color(0xFF7A271A),
  );

  final textTheme = Typography.material2021(platform: TargetPlatform.android)
      .black
      .apply(bodyColor: on, displayColor: on)
      .copyWith(
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: on,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: on,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: on,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: faint,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: on,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: on,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: faint,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: on,
        ),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    textTheme: textTheme,
    extensions: [
      ButlerColors(
        paper: panel,
        ink: on,
        muted: faint,
        rule: line,
        safetyCalm: brand,
        safetyWatch: const Color(0xFF6B4E0E),
        safetyCaution: const Color(0xFFC45E1A),
        safetyStop: const Color(0xFFB42318),
      ),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: on,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: on,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.standard,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        foregroundColor: on,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        visualDensity: VisualDensity.standard,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 40),
        foregroundColor: faint,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        visualDensity: VisualDensity.standard,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: panel,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(color: on, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: canvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: brand, width: 1.4),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      iconColor: faint,
      collapsedIconColor: faint,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      iconColor: faint,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
