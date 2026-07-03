import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/design_system.dart';

/// Ссылки на политику конфиденциальности и условия использования.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({
    super.key,
    this.compact = false,
    this.center = true,
  });

  final bool compact;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final style = TextStyle(
      fontSize: compact ? 12 : 13,
      color: tokens.textTertiary,
      height: 1.4,
    );
    final linkStyle = style.copyWith(
      color: tokens.accent,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    final text = Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Продолжая, вы соглашаетесь с '),
          TextSpan(
            text: 'Политикой конфиденциальности',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal/privacy'),
          ),
          const TextSpan(text: ' и '),
          TextSpan(
            text: 'Условиями использования',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/legal/terms'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );

    return Semantics(
      label: 'Политика конфиденциальности и условия использования',
      child: text,
    );
  }
}
