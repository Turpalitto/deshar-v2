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
  /// Возвращает true, если пользователь нажал "Продолжить" (капсулу можно
  /// отмечать увиденной навсегда), false — если просто закрыл (аудит §3:
  /// раньше обе кнопки вели себя одинаково).
  static Future<bool> show(BuildContext context, CultureCapsule capsule) async {
    final continued = await showCupertinoModalPopup<bool>(
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
                onContinue: () => Navigator.of(ctx).pop(true),
                onClose: () => Navigator.of(ctx).pop(false),
              ),
            ),
          ),
        );
      },
    );
    return continued ?? false;
  }
}
