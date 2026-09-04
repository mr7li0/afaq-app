import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:afaq/core/constants/color_constants.dart';
import 'package:afaq/core/localization/l10n.dart';

class LanguageSelectionView extends StatelessWidget {
  final VoidCallback onComplete;

  const LanguageSelectionView({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'آفاق',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.ivory),
              ),
              const SizedBox(height: 16),
              Text('اختر لغتك', style: TextStyle(fontSize: 18, color: AppColors.textHint)),
              const SizedBox(height: 40),
              _buildLanguageButton(context, label: 'العربية', code: 'ar'),
              const SizedBox(height: 16),
              _buildLanguageButton(context, label: 'کوردی', code: 'ckb'),
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
        onPressed: () {
          final l10n = context.read<LocalizationProvider>();
          l10n.setLocaleByCode(code);
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
