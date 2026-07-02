import 'package:flutter/material.dart';
import '../design_system.dart';

/// Поле поиска из Figma Make (словарь).
class NokhchiinSearchField extends StatelessWidget {
  const NokhchiinSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Поиск на чеченском или русском...',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(fontSize: 15, color: tokens.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: tokens.textTertiary, fontSize: 15),
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        prefixIcon: Icon(Icons.search_rounded, color: tokens.textTertiary, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.accent.withValues(alpha: 0.5)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.separator),
        ),
      ),
    );
  }
}
