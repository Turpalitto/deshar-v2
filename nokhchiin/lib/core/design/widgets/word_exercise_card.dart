import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../theme/nokhchiin_theme.dart';
import '../../widgets/word_illustration.dart';
import '../../../domain/entities/word_entity.dart';

/// Специальные символы чеченского для режима ввода CE→RU.
abstract final class ChechenInputChars {
  static const palochka = 'Ӏ';
  static const digraphs = ['къ', 'гӏ', 'хь', 'аь'];
  static const allSpecial = [palochka, ...digraphs];
}

/// Карточка слова: иллюстрация, чеченский, транскрипция всегда видна.
class WordExerciseCard extends StatelessWidget {
  const WordExerciseCard({
    super.key,
    required this.word,
    required this.categoryId,
    this.showRussian = false,
    this.russianOverride,
  });

  final WordEntity word;
  final String categoryId;
  final bool showRussian;
  final String? russianOverride;

  @override
  Widget build(BuildContext context) {
    final skin = NokhchiinSkin.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WordIllustration(
          category: categoryId,
          emoji: word.emoji,
          size: skin.isKids ? 200 : 160,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          word.chechen,
          style: AppTypography.chechenWord(context, large: true),
          textAlign: TextAlign.center,
        ),
        if (word.pronunciation != null && word.pronunciation!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            word.pronunciation!,
            style: AppTypography.pronunciation(context),
            textAlign: TextAlign.center,
          ),
        ],
        if (showRussian) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            russianOverride ?? word.russian,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Кастомная панель ввода: Ӏ и диграфы.
class ChechenKeyboard extends StatelessWidget {
  const ChechenKeyboard({
    super.key,
    required this.controller,
    this.onSubmit,
    this.hintText = 'Введите по-чеченски',
  });

  final TextEditingController controller;
  final VoidCallback? onSubmit;
  final String hintText;

  void _insert(String text) {
    final sel = controller.selection;
    final value = controller.text;
    final start = sel.start >= 0 ? sel.start : value.length;
    final end = sel.end >= 0 ? sel.end : value.length;
    final next = value.replaceRange(start, end, text);
    controller.text = next;
    controller.selection = TextSelection.collapsed(offset: start + text.length);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final skin = NokhchiinSkin.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
          decoration: InputDecoration(hintText: hintText),
          onSubmitted: (_) => onSubmit?.call(),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: ChechenInputChars.allSpecial.map((k) {
            return Material(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                onTap: () => _insert(k),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: skin.isKids ? AppSpacing.lg : AppSpacing.md,
                    vertical: skin.isKids ? AppSpacing.md : AppSpacing.sm,
                  ),
                  child: Text(
                    k,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
