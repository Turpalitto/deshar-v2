import 'dart:math';
import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Защита от случайного доступа ребёнка к настройкам взрослого.
abstract final class ParentalGate {
  /// Возвращает `true`, если взрослый прошёл проверку.
  static Future<bool> requestUnlock(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ParentalGateSheet(),
    );
    return result ?? false;
  }
}

class _ParentalGateSheet extends StatefulWidget {
  const _ParentalGateSheet();

  @override
  State<_ParentalGateSheet> createState() => _ParentalGateSheetState();
}

class _ParentalGateSheetState extends State<_ParentalGateSheet> {
  late final int _a;
  late final int _b;
  late final int _answer;
  late final List<int> _options;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _a = 4 + rnd.nextInt(6);
    _b = 3 + rnd.nextInt(6);
    _answer = _a + _b;
    final opts = <int>{_answer};
    while (opts.length < 4) {
      opts.add(_answer + rnd.nextInt(5) - 2);
    }
    _options = opts.toList()..shuffle(rnd);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Только для родителей',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Решите пример, чтобы открыть настройки',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              '$_a + $_b = ?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: tokens.accent,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _options.map((opt) {
                return SizedBox(
                  width: 72,
                  height: 56,
                  child: NokhchiinButton(
                    label: '$opt',
                    color: tokens.surfaceMuted,
                    textColor: tokens.textPrimary,
                    onPressed: () => Navigator.pop(context, opt == _answer),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
