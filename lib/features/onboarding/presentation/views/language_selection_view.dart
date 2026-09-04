import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:afaq/core/constants/color_constants.dart';
import 'package:afaq/core/localization/l10n.dart';
import 'package:afaq/core/services/local_storage_service.dart';

class LanguageSelectionView extends StatelessWidget {
  final VoidCallback onComplete;

  const LanguageSelectionView({super.key, required this.onComplete});

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
              const Text('اختر لغتك', style: TextStyle(fontSize: 18, color: AppColors.textHint)),
              const Spacer(flex: 2),
              _buildLanguageButton(context, label: 'العربية', code: 'ar'),
              const SizedBox(height: 16),
              _buildLanguageButton(context, label: 'کوردی', code: 'ckb'),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, {required String label, required String code}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final l10n = context.read<LocalizationProvider>();
          await l10n.setLocaleByCode(code);
          // Save to Hive so _isLanguageSet in AppRoot detects it
          await LocalStorageService().setLocale(code);
          onComplete();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ivory,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
