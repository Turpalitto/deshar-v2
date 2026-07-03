import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/mastery_progress_bar.dart';
import '../../core/widgets/word_illustration.dart';
import '../../domain/entities/word_entity.dart';

class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unitId});
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(learningUnitsProvider);
    return units.when(
      data: (list) {
        final unit = list.firstWhere((u) => u.id == unitId);
        return Scaffold(
          appBar: AppBar(title: Text(unit.titleRu)),
          body: FutureBuilder<List<WordEntity>>(
            future: ref.read(dictionaryRepoProvider).getWordsByCategory(unitId),
            builder: (context, snap) {
              final words = snap.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(child: WordIllustration(category: unitId, emoji: null, size: 100)),
                  const SizedBox(height: 12),
                  Text(unit.titleCe, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
                  MasteryProgressBar(percent: unit.masteryPercent),
                  Text('${unit.masteryPercent}% · ${words.length} слов', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/lesson/$unitId'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Начать урок', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GameButton(iconAsset: AppIcons.gameBoss, title: 'Босс мира', subtitle: 'Кульминация темы', onTap: () => context.push('/boss/$unitId')),
                  _GameButton(iconAsset: AppIcons.gamePuzzle, title: 'Найди пару', onTap: () => context.push('/match/$unitId')),
                  _GameButton(iconAsset: AppIcons.navDictionary, title: 'Карточки', subtitle: 'Свайп и запоминай', onTap: () => context.push('/flashcards/$unitId')),
                  _GameButton(iconAsset: AppIcons.actionReview, title: 'Квиз', subtitle: 'Проверь себя', onTap: () => context.push('/quiz/$unitId')),
                  _GameButton(iconAsset: AppIcons.actionTyping, title: 'Ввод', subtitle: 'Напиши по-чеченски', onTap: () => context.push('/typing/$unitId')),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({
    this.emoji,
    this.iconAsset,
    required this.title,
    this.subtitle,
    required this.onTap,
  }) : assert(emoji != null || iconAsset != null);

  final String? emoji;
  final String? iconAsset;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: iconAsset != null
              ? AppIconImage(asset: iconAsset!, size: 28)
              : Text(emoji!, style: const TextStyle(fontSize: 28)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
