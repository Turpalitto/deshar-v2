import 'package:flutter/material.dart';
import 'app_button.dart';

Future<void> showChestRewardDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('🎁 Сундук!'),
      content: const Text('+25 монет · +30 XP'),
      actions: [
        AppButton(
          label: 'Забрать',
          expanded: false,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}
