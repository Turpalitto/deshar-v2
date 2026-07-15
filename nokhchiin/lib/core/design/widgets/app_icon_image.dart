import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_icons.dart';

/// Брендовая иконка из assets/icons (SVG/PNG). Поддерживает tint для неактивных состояний.
class AppIconImage extends StatelessWidget {
  const AppIconImage({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final filter = color != null
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null;

    if (asset.endsWith('.svg')) {
      return Semantics(
        label: semanticLabel,
        child: SvgPicture.asset(
          asset,
          width: size,
          height: size,
          colorFilter: filter,
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
      ),
    );
  }
}

/// Иконка таб-бара по индексу.
class AppTabIcon extends StatelessWidget {
  const AppTabIcon({
    super.key,
    required this.index,
    required this.color,
    this.size = 24,
  });

  final int index;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= AppIcons.tabBar.length) {
      return SizedBox(width: size, height: size);
    }
    return AppIconImage(
      asset: AppIcons.tabBar[index],
      size: size,
      color: color,
    );
  }
}
