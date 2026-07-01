import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MasteryProgressBar extends StatelessWidget {
  const MasteryProgressBar({super.key, required this.percent, this.height = 6});
  final int percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: percent / 100,
        minHeight: height,
        backgroundColor: AppColors.mastery0,
        valueColor: AlwaysStoppedAnimation(
          percent >= 80
              ? AppColors.mastery5
              : percent >= 40
                  ? AppColors.mastery3
                  : AppColors.primary,
        ),
      ),
    );
  }
}
