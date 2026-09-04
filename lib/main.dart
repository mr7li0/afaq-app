import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/localization/l10n.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/color_constants.dart';
import 'core/services/app_initialization.dart';
import 'core/services/local_storage_service.dart';
import 'features/onboarding/presentation/views/language_selection_view.dart';
import 'features/main_navigation/presentation/views/main_navigation_view.dart';

late LocalizationProvider gL10n;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  gL10n = LocalizationProvider();

  try {
    await AppInitialization.initialize();
  } catch (_) {}

  try {
    await gL10n.init();
  } catch (_) {
    gL10n.forceReady();
  }

  runApp(const AfaqApp());

  unawaited(Future.delayed(const Duration(seconds: 5), () {
    try {
      AppInitialization.scheduleAlarms();
    } catch (_) {}
  }));
}

class AfaqApp extends StatelessWidget {
  const AfaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocalizationProvider>.value(
      value: gL10n,
      child: Consumer<LocalizationProvider>(
        builder: (context, l10n, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: l10n.locale,
            supportedLocales: const [Locale('ar'), Locale('ckb')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('ar');
            },
            builder: (context, child) {
              final l10n = context.watch<LocalizationProvider>();
              return Directionality(
                textDirection: l10n.textDirection,
                child: child!,
              );
            },
            home: const AppEntry(),
          );
        },
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry();
  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Wait for splash
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check what screen to show
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();

    final l10n = context.watch<LocalizationProvider>();
    if (!l10n.isReady) return const _SplashScreen();

    // 1. Check language from Hive
    final langSet = _checkLanguageSet();
    if (!langSet) {
      return LanguageSelectionView(onLanguageSelected: (code) async {
        // Save language to Hive
        await LocalStorageService().setLocale(code);
        // Reload l10n from Hive
        await gL10n.init();
        // Trigger rebuild
        if (mounted) setState(() {});
      });
    }

    // 2. All done → main app
    return const MainNavigationView();
  }

  bool _checkLanguageSet() {
    try {
      final box = Hive.box(AppConstants.boxSettings);
      final lang = box.get(AppConstants.keyLocale, defaultValue: '');
      return lang != null && lang.toString().isNotEmpty;
    } catch (_) {
      return false;
    }
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
