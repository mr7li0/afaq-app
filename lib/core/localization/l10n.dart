import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Provides the full localization pipeline:
/// 1. Load saved locale from SharedPreferences (default: Arabic)
/// 2. Load matching JSON from assets/lang/
/// 3. Build a map of nested keys flattened with dot notation
class LocalizationProvider extends ChangeNotifier {
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('ckb'),
  ];

  Locale _locale = const Locale('ar');
  Map<String, String> _strings = {};
  bool _isReady = false;

  Locale get locale => _locale;
  Map<String, String> get strings => _strings;
  bool get isReady => _isReady;

  void forceReady() {
    _isReady = true;
    notifyListeners();
  }

  // ── Initialization ─────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(AppConstants.keyLocale) ?? 'ar';
    _locale = Locale(code);
    await _loadStrings(code);
    _isReady = true;
    notifyListeners();
  }

  Future<void> _loadStrings(String languageCode) async {
    try {
      final String path;
      switch (languageCode) {
        case 'en':
          path = AppConstants.langEnPath;
          break;
        case 'ckb':
          path = 'assets/lang/ckb.json';
          break;
        default:
          path = AppConstants.langArPath;
      }
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _strings = _flatten(jsonMap);
    } catch (e) {
      _strings = {};
    }
  }

  // ── Locale Switching ───────────────────────────────
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _loadStrings(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale.languageCode);
    notifyListeners();
  }

  Future<void> setLocaleByCode(String code) async {
    await setLocale(Locale(code));
  }

  // ── String Access ──────────────────────────────────
  /// Get a string by dot-notation key: t('dashboard.next_prayer')
  String t(String key) => _strings[key] ?? key;

  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isKurdish => _locale.languageCode == 'ckb';
  TextDirection get textDirection =>
      isArabic || isKurdish ? TextDirection.rtl : TextDirection.ltr;

  // ── Helpers ────────────────────────────────────────
  /// Flatten nested JSON map to dot-notation keys.
  Map<String, String> _flatten(Map<String, dynamic> map, [String prefix = '']) {
    final result = <String, String>{};
    map.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        result.addAll(_flatten(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });
    return result;
  }
}
