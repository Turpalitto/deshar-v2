import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../data/culture_capsule_samples.dart';
import 'culture_capsule_modal.dart';

/// Показ культурных интерлюдий в флоу обучения.
abstract final class CultureCapsuleFlow {
  /// Интерлюдия перед уроком юнита (один раз на капсулу).
  static Future<void> maybeShowBeforeUnit(
    BuildContext context,
    WidgetRef ref,
    String unitId,
  ) async {
    final capsule = CultureCapsuleSamples.forUnit(unitId);
    if (capsule == null) return;

    final profile = ref.read(userProfileProvider).value;
    if (profile?.seenCultureCapsules.contains(capsule.id) ?? false) return;

    await CultureCapsuleModal.show(context, capsule);
    if (!context.mounted) return;

    await ref.read(userProfileProvider.notifier).markCultureCapsuleSeen(capsule.id);
  }
}
