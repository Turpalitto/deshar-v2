import 'package:flutter/material.dart';
import '../design/tokens/nokhchiin_colors.dart';

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
        backgroundColor: NokhchiinColors.masteryLow,
        valueColor: AlwaysStoppedAnimation(
          percent >= 80
              ? NokhchiinColors.masteryHigh
              : percent >= 40
                  ? NokhchiinColors.masteryMid
                  : NokhchiinColors.meadow,
        ),
      ),
    );
  }
}
