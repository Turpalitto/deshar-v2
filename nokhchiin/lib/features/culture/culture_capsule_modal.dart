import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/culture_capsule.dart';
import 'widgets/culture_capsule_card.dart';

/// Показать культурную капсулу как полноэкранную модальную интерлюдию.
///
/// Ручной вызов для тестирования:
/// ```dart
/// CultureCapsuleModal.show(context, CultureCapsuleSamples.adatAfterFamily);
/// ```
abstract final class CultureCapsuleModal {
  static Future<void> show(BuildContext context, CultureCapsule capsule) {
    return showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height,
              width: MediaQuery.sizeOf(ctx).width,
              child: CultureCapsuleCard(
                capsule: capsule,
                onContinue: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    );
  }
}
