import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class PrayerMiniWidget extends StatelessWidget {
  final String name;
  final String time;

  const PrayerMiniWidget({
    super.key,
    required this.name,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ivory,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
