import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/learner_insights_service.dart';
import 'widgets/arc_progress_ring.dart';
import 'widgets/ios_streak_tile.dart';

/// Персональный dashboard взрослого трека (инсайты, не детский кабинет родителя).
class AdultInsightsDashboardScreen extends ConsumerWidget {
  const AdultInsightsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(learnerInsightsProvider);
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return CupertinoPageScaffold(
      backgroundColor: tokens.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: tokens.surface.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: tokens.separator)),
        middle: Text('Инсайты', style: textTheme.headlineSmall),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.push('/progress'),
          child: Text('SRS', style: TextStyle(color: tokens.accent, fontSize: 15)),
        ),
      ),
      child: SafeArea(
        child: insights.when(
          loading: () => const LoadingState(message: 'Считаем прогресс…'),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) => ListView(
            padding: const EdgeInsets.all(IosSpacing.screenHorizontal),
            children: [
              const SizedBox(height: IosSpacing.x4),
              _OverviewRow(insights: data),
              const SizedBox(height: IosSpacing.x6),
              _WeakSpotCard(insights: data),
              const SizedBox(height: IosSpacing.x4),
              _StatsStrip(insights: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.insights});

  final LearnerInsights insights;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Container(
      padding: const EdgeInsets.all(IosSpacing.x5),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.separator),
      ),
      child: Row(
        children: [
          Expanded(child: IosStreakTile(days: insights.streakDays)),
          ArcProgressRing(
            progress: insights.languageMasteryPercent / 100,
            size: 108,
            strokeWidth: 9,
            label: 'язык',
          ),
        ],
      ),
    );
  }
}

class _WeakSpotCard extends StatelessWidget {
  const _WeakSpotCard({required this.insights});

  final LearnerInsights insights;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);
    final unit = insights.weakestUnit;

    final title = unit == null
        ? 'Пока нет данных'
        : 'Слабое место: ${unit.titleRu}';
    final body = unit == null
        ? 'Начните урок — появится первая категория для анализа.'
        : 'Освоено на ${unit.masteryPercent}% · ${unit.titleCe}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(IosSpacing.x5),
      decoration: BoxDecoration(
        color: tokens.accentMuted.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: IosSpacing.x2),
          Text(
            body,
            style: textTheme.bodyLarge?.copyWith(
              color: tokens.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.insights});

  final LearnerInsights insights;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final textTheme = IosTypography.of(context, tokens);

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Уровень',
            value: '${insights.level}',
            tokens: tokens,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: IosSpacing.x3),
        Expanded(
          child: _MiniStat(
            label: 'XP',
            value: '${insights.xp}',
            tokens: tokens,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: IosSpacing.x3),
        Expanded(
          child: _MiniStat(
            label: 'Уроков',
            value: '${insights.lessonsCompleted}',
            tokens: tokens,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.tokens,
    required this.textTheme,
  });

  final String label;
  final String value;
  final DesignTokens tokens;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: IosSpacing.x4, horizontal: IosSpacing.x3),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.separator),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: IosSpacing.x1),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}
