import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// Тонкий декоративный орнамент — делегирует вайнахскому паттерну Figma.
class OrnamentAccent extends StatelessWidget {
  const OrnamentAccent({super.key, this.opacity = 0.05});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: OverflowBox(
        maxHeight: 200,
        alignment: Alignment.topCenter,
        child: NokhchiinOrnament(opacity: opacity),
      ),
    );
  }
}
