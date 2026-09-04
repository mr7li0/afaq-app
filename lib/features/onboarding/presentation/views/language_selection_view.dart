import 'package:flutter/material.dart';
import 'package:afaq/core/constants/color_constants.dart';

class LanguageSelectionView extends StatelessWidget {
  final Function(String code) onLanguageSelected;

  const LanguageSelectionView({super.key, required this.onLanguageSelected});

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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onLanguageSelected('ar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ivory,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('العربية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onLanguageSelected('ckb'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ivory,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('کوردی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
