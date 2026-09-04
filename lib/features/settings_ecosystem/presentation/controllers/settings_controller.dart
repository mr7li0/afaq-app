import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../data/json_backup_service.dart';

/// Settings & Ecosystem controller managing:
/// - Language switching (AR/EN with RTL/LTR)
/// - Font & theme options (blur intensity)
/// - Cache & storage management
/// - Ecosystem directory data
/// - Feedback submission via Telegram Bot API
class SettingsController extends ChangeNotifier {
  // ── Language ───────────────────────────────────────
  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  // ── Theme ──────────────────────────────────────────
  double _blurIntensity = 10.0;
  double get blurIntensity => _blurIntensity;

  bool _useFrostedGlass = true;
  bool get useFrostedGlass => _useFrostedGlass;

  Color _accentColor = AppColors.textPrimary;
  Color get accentColor => _accentColor;

  double _textSizeMultiplier = 1.0;
  double get textSizeMultiplier => _textSizeMultiplier;

  // ── Cache ──────────────────────────────────────────
  int _cacheSize = 0;
  int get cacheSize => _cacheSize;

  bool _isClearingCache = false;
  bool get isClearingCache => _isClearingCache;

  // ── Loading ────────────────────────────────────────
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ── Ecosystem Accordion State ─────────────────────
  int _expandedEcosystemIndex = -1;
  int get expandedEcosystemIndex => _expandedEcosystemIndex;

  void toggleEcosystemExpansion(int index) {
    _expandedEcosystemIndex = _expandedEcosystemIndex == index ? -1 : index;
    notifyListeners();
  }

  // ── Ecosystem Directory ────────────────────────────
  final List<EcosystemItem> _ecosystemItems = [
    const EcosystemItem(
      type: EcosystemType.channel,
      titleAr: 'قنوات تيليجرام',
      titleEn: 'Telegram Channels',
      descriptionAr: 'تابع آخر أخبار آفاق وتحديثاتها',
      descriptionEn: 'Follow latest Afaq news and updates',
      url: 'https://t.me/afaq0t',
      icon: Icons.telegram,
      followerCount: '10K+',
    ),
    const EcosystemItem(
      type: EcosystemType.bot,
      titleAr: 'بوتات تيليجرام',
      titleEn: 'Telegram Bots',
      descriptionAr: 'بوتات مساعدة للقرآن والأذكار',
      descriptionEn: 'Helper bots for Quran and Athkar',
      url: 'https://t.me/afaq_bot',
      icon: Icons.smart_toy,
      followerCount: '5K+',
    ),
    const EcosystemItem(
      type: EcosystemType.group,
      titleAr: 'مجموعات تيليجرام',
      titleEn: 'Telegram Groups',
      descriptionAr: 'مجموعات نقاش ومشاركة',
      descriptionEn: 'Discussion and sharing groups',
      url: 'https://t.me/afaq_group',
      icon: Icons.group,
      followerCount: '8K+',
    ),
    const EcosystemItem(
      type: EcosystemType.resource,
      titleAr: 'خطوط آفاق',
      titleEn: 'Afaq Fonts',
      descriptionAr: 'خطوط Milan و Uthmani للتحميل',
      descriptionEn: 'Milan and Uthmani fonts for download',
      url: 'https://afaq.app/fonts',
      icon: Icons.font_download,
      followerCount: '',
    ),
  ];

  List<EcosystemItem> get ecosystemItems => _ecosystemItems;

  // ── Initialization ────────────────────────────────
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _loadSettings();
    await _loadCacheSize();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(AppConstants.keyLocale) ?? 'ar';
    _locale = Locale(localeCode);
    _blurIntensity = prefs.getDouble('blur_intensity') ?? 10.0;
    _useFrostedGlass = prefs.getBool('use_frosted_glass') ?? true;
    _textSizeMultiplier = prefs.getDouble('text_size_multiplier') ?? 1.0;
  }

  // ── Language Switching ────────────────────────────
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale.languageCode);
    
    notifyListeners();
  }

  // ── Theme Options ─────────────────────────────────
  Future<void> setBlurIntensity(double value) async {
    _blurIntensity = value.clamp(0.0, 30.0);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blur_intensity', _blurIntensity);
    
    notifyListeners();
  }

  Future<void> toggleFrostedGlass() async {
    _useFrostedGlass = !_useFrostedGlass;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_frosted_glass', _useFrostedGlass);
    
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.toARGB32());
    
    notifyListeners();
  }

  Future<void> setTextSizeMultiplier(double multiplier) async {
    _textSizeMultiplier = multiplier.clamp(0.8, 1.5);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_size_multiplier', _textSizeMultiplier);
    
    notifyListeners();
  }

  // ── Cache Management ──────────────────────────────
  Future<void> _loadCacheSize() async {
    final backupService = JsonBackupService();
    _cacheSize = await backupService.getCacheSize();
    notifyListeners();
  }

  String get formattedCacheSize {
    if (_cacheSize < 1024) return '$_cacheSize B';
    if (_cacheSize < 1024 * 1024) return '${(_cacheSize / 1024).toStringAsFixed(1)} KB';
    return '${(_cacheSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> clearCache() async {
    _isClearingCache = true;
    notifyListeners();

    final backupService = JsonBackupService();
    await backupService.clearCache();
    await _loadCacheSize();

    _isClearingCache = false;
    notifyListeners();
  }

  // ── Backup Operations ─────────────────────────────
  Future<bool> exportData() async {
    final backupService = JsonBackupService();
    return await backupService.exportData();
  }

  Future<BackupResult> importData(String filePath) async {
    final backupService = JsonBackupService();
    final result = await backupService.importData(filePath);
    
    if (result.success) {
      // Refresh settings after import
      await _loadSettings();
    }
    
    return result;
  }

  // ── Ecosystem Actions ─────────────────────────────
  Future<void> openEcosystemLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Feedback Submission ───────────────────────────
  Future<bool> submitFeedback({
    required FeedbackCategory category,
    required String message,
    required int rating,
  }) async {
    try {
      // Build Telegram message
      final categoryLabel = _getCategoryLabel(category);
      final telegramMessage = '''
🐛 *New Feedback from Afaq App*

📋 Category: $categoryLabel
⭐ Rating: $rating/5

💬 Message:
$message

📱 App Version: 1.0.0
📅 Date: ${DateTime.now().toIso8601String()}
''';

      // Send via Telegram Bot API (HTTPS POST)
      final botToken = 'YOUR_BOT_TOKEN'; // Replace with actual bot token
      final chatId = 'YOUR_CHAT_ID'; // Replace with actual chat ID
      
      final uri = Uri.parse(
        'https://api.telegram.org/bot$botToken/sendMessage',
      );

      final request = await HttpClient().postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(json.encode({
        'chat_id': chatId,
        'text': telegramMessage,
        'parse_mode': 'Markdown',
      }));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final jsonData = json.decode(responseBody) as Map<String, dynamic>;
      
      return jsonData['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  String _getCategoryLabel(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.bugReport:
        return '🐛 Bug Report / تقرير خلل';
      case FeedbackCategory.featureSuggestion:
        return '💡 Feature Suggestion / اقتراح ميزة';
      case FeedbackCategory.generalFeedback:
        return '💬 General Feedback / ملاحظات عامة';
    }
  }
}

/// Ecosystem item types
enum EcosystemType {
  channel,
  bot,
  group,
  resource,
}

/// Ecosystem directory item
class EcosystemItem {
  final EcosystemType type;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String url;
  final IconData icon;
  final String followerCount;

  const EcosystemItem({
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.url,
    required this.icon,
    required this.followerCount,
  });
}

/// Feedback categories
enum FeedbackCategory {
  bugReport,
  featureSuggestion,
  generalFeedback,
}
