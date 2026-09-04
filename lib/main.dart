import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/localization/l10n.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/color_constants.dart';
import 'core/services/app_initialization.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/presentation/views/language_selection_view.dart';
import 'features/main_navigation/presentation/views/main_navigation_view.dart';

void main() {
  runZonedGuarded(() async {
    await AppInitialization.initialize();
    runApp(const AfaqApp());

    try {
      await AppInitialization.scheduleAlarms();
    } catch (_) {}
  }, (error, stack) {
    debugPrint('=== UNHANDLED ERROR ===');
    debugPrint('$error');
  });
}

class AfaqApp extends StatefulWidget {
  const AfaqApp({super.key});
  @override
  State<AfaqApp> createState() => _AfaqAppState();
}

class _AfaqAppState extends State<AfaqApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        AppInitialization.scheduleAlarms();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationProvider()..init();
    return ChangeNotifierProvider<LocalizationProvider>.value(
      value: l10n,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot();
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  bool get _isLanguageSet {
    try {
      final box = Hive.box(AppConstants.boxSettings);
      final lang = box.get(AppConstants.keyLocale, defaultValue: '');
      return lang != null && lang.toString().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const _SplashScreen();
    final l10n = context.watch<LocalizationProvider>();
    if (!l10n.isReady) return const _SplashScreen();
    if (!_isLanguageSet) {
      return LanguageSelectionView(onComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationView()),
        );
      });
    }
    return const MainNavigationView();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('آفاق', style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: AppColors.ivory)),
            SizedBox(height: 32),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ivory)),
          ],
        ),
      ),
    );
  }
}
