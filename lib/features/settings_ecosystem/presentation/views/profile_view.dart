import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../controllers/settings_controller.dart';

/// Profile & Settings screen with language switching.
///
/// Sections:
/// - Header (avatar, app name, tagline)
/// - Language selector (AR / EN / CKB)
/// - Notifications toggle
/// - Theme settings (appearance, font size, clear cache)
/// - About section
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _athanNotificationsEnabled = true;
  double _fontSizeMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsController>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer2<SettingsController, LocalizationProvider>(
          builder: (context, controller, l10n, _) {
            return ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                _buildHeader(l10n),
                const SizedBox(height: 28),
                _buildLanguageCard(l10n, controller),
                const SizedBox(height: 16),
                _buildNotificationsCard(l10n),
                const SizedBox(height: 16),
                _buildPrayerSettingsCard(l10n),
                const SizedBox(height: 16),
                _buildThemeCard(l10n, controller),
                const SizedBox(height: 16),
                _buildAboutCard(l10n),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────
  Widget _buildHeader(LocalizationProvider l10n) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.glassFill,
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('app_name'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('app_tagline'),
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Language Selector Card ─────────────────────────
  Widget _buildLanguageCard(LocalizationProvider l10n, SettingsController controller) {
    final currentCode = l10n.locale.languageCode;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                l10n.t('common.language'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3-option segmented selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildLanguageOption(
                  label: 'العربية',
                  isActive: currentCode == 'ar',
                  onTap: () => _switchLanguage(controller, l10n, 'ar'),
                ),
                _buildLanguageOption(
                  label: 'English',
                  isActive: currentCode == 'en',
                  onTap: () => _switchLanguage(controller, l10n, 'en'),
                ),
                _buildLanguageOption(
                  label: 'کوردی (سۆرانی)',
                  isActive: currentCode == 'ckb',
                  onTap: () => _switchLanguage(controller, l10n, 'ckb'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.goldAccent.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.goldAccent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.goldAccent : AppColors.textHint,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _switchLanguage(SettingsController controller, LocalizationProvider l10n, String code) {
    final locale = Locale(code);
    controller.setLocale(locale);
    l10n.setLocale(locale);
  }

  // ── Notifications Toggle ───────────────────────────
  Widget _buildNotificationsCard(LocalizationProvider l10n) {
    return _buildGlassCard(
      child: Row(
        children: [
          const Icon(Icons.notifications, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.t('settings_screen.athan_notifications'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _athanNotificationsEnabled,
            onChanged: (v) => setState(() => _athanNotificationsEnabled = v),
            activeThumbColor: AppColors.textPrimary,
            activeTrackColor: AppColors.textPrimary.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.glassFill,
          ),
        ],
      ),
    );
  }

  // ── Prayer Time Settings ──────────────────────────
  Widget _buildPrayerSettingsCard(LocalizationProvider l10n) {
    final storage = LocalStorageService();
    final currentMethod = storage.calculationMethod;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                'إعدادات مواقيت الصلاة',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Calculation Method
          Text(
            'طريقة الحساب',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentMethod,
                isExpanded: true,
                dropdownColor: AppColors.cardElevated,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: PrayerTimeUtils.calculationMethods.keys.map((name) {
                  final arName = PrayerTimeUtils.methodNamesAr[name] ?? name;
                  return DropdownMenuItem(value: name, child: Text(arName));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    storage.setCalculationMethod(value);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Madhab
          Text(
            'المذهب',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: storage.prefs.getString(AppConstants.keyMadhab) ?? 'Shafi\'i',
                isExpanded: true,
                dropdownColor: AppColors.cardElevated,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: PrayerTimeUtils.madhabOptions.keys.map((name) {
                  final arName = PrayerTimeUtils.madhabNamesAr[name] ?? name;
                  return DropdownMenuItem(value: name, child: Text(arName));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    storage.prefs.setString(AppConstants.keyMadhab, value);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Location info
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'خط العرض: ${storage.latitude.toStringAsFixed(4)} | خط الطول: ${storage.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Theme Settings Card ────────────────────────────
  Widget _buildThemeCard(LocalizationProvider l10n, SettingsController controller) {
    return _buildGlassCard(
      child: Column(
        children: [
          // Appearance
          _buildSettingsTile(
            icon: Icons.palette,
            title: l10n.t('settings_screen.appearance'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.t('settings_screen.appearance_placeholder')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(color: AppColors.glassBorder),
          // Font Size
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_fields, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.t('settings_screen.font_size'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(_fontSizeMultiplier * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _fontSizeMultiplier,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                onChanged: (v) => setState(() => _fontSizeMultiplier = v),
                activeColor: AppColors.textPrimary,
                inactiveColor: AppColors.glassFill,
              ),
            ],
          ),
          const Divider(color: AppColors.glassBorder),
          // Clear Cache
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: l10n.t('settings_screen.clear_cache'),
            subtitle: controller.formattedCacheSize,
            trailing: controller.isClearingCache
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            onTap: controller.isClearingCache
                ? null
                : () async {
                    await controller.clearCache();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.t('settings_screen.cache_cleared')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  // ── About Card ─────────────────────────────────────
  Widget _buildAboutCard(LocalizationProvider l10n) {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: l10n.t('settings_screen.about_app'),
            subtitle: '${l10n.t('settings_screen.version')} 1.0.0',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.t('settings_screen.about_placeholder')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(color: AppColors.glassBorder),
          _buildSettingsTile(
            icon: Icons.star_outline,
            title: l10n.t('settings_screen.rate_app'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.t('settings_screen.rate_placeholder')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ─────────────────────────────────
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusCards),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_left, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
