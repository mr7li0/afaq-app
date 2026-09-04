import 'package:flutter/material.dart';
import 'package:afaq/core/constants/color_constants.dart';
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
              _buildBtn('العربية', () async {
                await LocalStorageService().setLocale('ar');
                onComplete();
              }),
              const SizedBox(height: 16),
              _buildBtn('کوردی', () async {
                await LocalStorageService().setLocale('ckb');
                onComplete();
              }),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
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
