import 'package:flutter/material.dart';

import 'services/butler_supabase.dart';
import 'ui/app_dependencies.dart';
import 'ui/app_theme.dart';
import 'ui/first_run_screen.dart';
import 'ui/home_screen.dart';
import 'ui/safety_disclaimer_screen.dart';
import 'ui/product_chrome.dart';
import 'ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ensureButlerSupabase();
  } catch (_) {
    // Backend init must never block runApp. Packaged copy if it fails.
  }
  final dependencies = await AppDependencies.createPersisted();
  runApp(ModernButlerApp(dependencies: dependencies));
}

/// Product shell for the dryer diagnostic demo.
class ModernButlerApp extends StatefulWidget {
  ModernButlerApp({
    AppDependencies? dependencies,
    this.forceBrandSplash = false,
    super.key,
  }) : dependencies = dependencies ?? AppDependencies();

  final AppDependencies dependencies;

  /// Widget tests skip the splash unless this is true.
  final bool forceBrandSplash;

  @override
  State<ModernButlerApp> createState() => _ModernButlerAppState();
}

class _ModernButlerAppState extends State<ModernButlerApp>
    with WidgetsBindingObserver {
  bool _showSplash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.dependencies.onlineListenable?.addListener(_onOnlineChanged);
    final inWidgetTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    _showSplash = widget.forceBrandSplash || !inWidgetTest;
    if (_showSplash) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() => _showSplash = false);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.dependencies.onlineListenable?.removeListener(_onOnlineChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onOnlineChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.dependencies.flushPersist();
    }
  }

  ThemeMode get _themeMode =>
      widget.dependencies.themeChoice.isDark
          ? ThemeMode.dark
          : ThemeMode.light;

  ThemeData get _lightTheme =>
      widget.dependencies.themeChoice == AppThemeChoice.modern
          ? buildModernTheme()
          : buildAppTheme();

  Future<void> _toggleTheme() async {
    final current = widget.dependencies.themeChoice;
    final next =
        current.isDark
            ? widget.dependencies.lastLightTheme
            : AppThemeChoice.dark;
    await widget.dependencies.applyThemeChoice(next);
    if (mounted) {
      setState(() {});
    }
  }

  void _onAppearanceChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Modern Butler’s Book',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ButlerScrollBehavior(),
      theme: _lightTheme,
      darkTheme: buildDarkAppTheme(),
      themeMode: _themeMode,
      home: _showSplash
          ? const SplashScreen()
          : !widget.dependencies.firstRunComplete
          ? FirstRunScreen(
              onFinished: () async {
                await widget.dependencies.completeFirstRun();
                if (mounted) {
                  setState(() {});
                }
              },
            )
          : !widget.dependencies.disclaimerAcknowledged
          ? SafetyDisclaimerScreen(
              onAcknowledged: () async {
                await widget.dependencies.acknowledgeDisclaimer();
                if (mounted) {
                  setState(() {});
                }
              },
            )
          : HomeScreen(
              dependencies: widget.dependencies,
              themeMode: _themeMode,
              onToggleTheme: _toggleTheme,
              onAppearanceChanged: _onAppearanceChanged,
            ),
    );
  }
}
