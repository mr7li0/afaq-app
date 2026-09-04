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
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'features/onboarding/presentation/views/language_selection_view.dart';
import 'features/main_navigation/presentation/views/main_navigation_view.dart';

late LocalizationProvider gL10n;

void main() {
  runZonedGuarded(() async {
    await AppInitialization.initialize();
    gL10n = LocalizationProvider()..init();
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
    return ChangeNotifierProvider<LocalizationProvider>.value(
      value: gL10n,
      child: Consumer<LocalizationProvider>(
        builder: (context, l10n, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: l10n.locale,
            supportedLocales: const [Locale('ar'), Locale('en'), Locale('ckb')],
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
            home: const AppRoot(),
          );
        },
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
  bool _showPermissionScreen = false;

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
    if (_showPermissionScreen) {
      return _PermissionScreen(onComplete: () {
        setState(() => _showPermissionScreen = false);
      });
    }
    if (!_isLanguageSet) {
      return LanguageSelectionView(onComplete: () {
        setState(() => _showPermissionScreen = true);
      });
    }
    final firstLaunch = LocalStorageService().isFirstLaunch;
    if (firstLaunch) {
      LocalStorageService().setFirstLaunchDone();
      return _PermissionScreen(onComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationView()),
        );
      });
    }
    return const MainNavigationView();
  }
}

class _PermissionScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const _PermissionScreen({required this.onComplete});

  @override
  State<_PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<_PermissionScreen> {
  bool _isLoading = true;
  bool _locationGranted = false;
  bool _notificationGranted = false;
  String _loadingText = 'جاري طلب الأذونات...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _loadingText = 'جاري طلب إذن الموقع...';
    });

    try {
      final loc = LocationService();
      final position = await loc.getCurrentPosition();
      _locationGranted = position != null;
      if (_locationGranted && position != null) {
        await LocalStorageService().setLocation(position.latitude, position.longitude);
      }
    } catch (_) {
      _locationGranted = false;
    }

    setState(() => _loadingText = 'جاري طلب إذن الإشعارات...');

    try {
      _notificationGranted = await NotificationService().requestNotificationPermission();
    } catch (_) {
      _notificationGranted = false;
    }

    setState(() {
      _isLoading = false;
      _loadingText = '';
    });

    if (_locationGranted && _notificationGranted) {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'آفاق',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.ivory),
              ),
              const SizedBox(height: 16),
              const Text('التطبيق الإسلامي الشامل', style: TextStyle(fontSize: 16, color: AppColors.textHint)),
              const Spacer(flex: 2),
              if (_isLoading) ...[
                const CircularProgressIndicator(color: AppColors.ivory, strokeWidth: 2),
                const SizedBox(height: 20),
                Text(_loadingText, style: const TextStyle(fontSize: 16, color: AppColors.ivory)),
              ] else ...[
                _buildPermissionStatus('إذن الموقع', _locationGranted),
                const SizedBox(height: 12),
                _buildPermissionStatus('إذن الإشعارات', _notificationGranted),
                const SizedBox(height: 32),
                if (!_locationGranted || !_notificationGranted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ivory,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (_locationGranted && _notificationGranted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ivory,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('ابدأ الاستخدام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatus(String label, bool granted) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? AppColors.accentGreen : AppColors.starRed,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16, color: AppColors.ivory)),
        const Spacer(),
        Text(
          granted ? 'تم' : 'غير ممنوح',
          style: TextStyle(fontSize: 14, color: granted ? AppColors.accentGreen : AppColors.starRed),
        ),
      ],
    );
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
