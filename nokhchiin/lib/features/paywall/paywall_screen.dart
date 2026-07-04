import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:nokhchiin/core/l10n/l10n_extensions.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/widgets/app_icon_image.dart';
import '../../core/design/widgets/app_button.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/services/analytics_service.dart';
import '../../core/widgets/legal_links_row.dart';
import 'package:nokhchiin/l10n/app_localizations.dart';
import '../../domain/constants/subscription_limits.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/repositories/billing_repository.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.returnPath});

  final String? returnPath;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).track(
        AnalyticsEventName.paywallViewed,
        properties: {
          if (widget.returnPath != null) 'return_path': widget.returnPath!,
        },
      );
    });
  }

  Future<void> _run(
    AnalyticsEventName event,
    Future<void> Function() action,
  ) async {
    setState(() => _loading = true);
    final analytics = ref.read(analyticsServiceProvider);
    try {
      await analytics.track(event);
      await action();
      if (event == AnalyticsEventName.trialStarted ||
          event == AnalyticsEventName.purchaseStarted) {
        await analytics.track(AnalyticsEventName.purchaseCompleted);
      }
      if (!mounted) return;
      if (widget.returnPath != null) {
        context.go(widget.returnPath!);
      } else {
        context.pop();
      }
    } on BillingUnavailableException catch (e) {
      await analytics.track(
        AnalyticsEventName.purchaseFailed,
        properties: {'error': e.message, 'kind': 'unavailable'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      await analytics.track(
        AnalyticsEventName.purchaseFailed,
        properties: {'error': e.toString()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.iosTokens;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(analyticsServiceProvider).track(AnalyticsEventName.paywallDismissed);
        }
      },
      child: AppScaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close_rounded, color: tokens.textTertiary),
                ),
              ),
              const AppIconImage(asset: AppIcons.rewardCrown, size: 52)
                  .animate()
                  .fadeIn()
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Нохчийн Premium',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.paywallSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              NokhchiinSurfaceCard(
                radius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    for (final row in <(String, String)>[
                      (AppIcons.iconInfinity, l10n.compareRowPath),
                      (AppIcons.stateOffline, l10n.compareRowOffline),
                      (AppIcons.actionReview, l10n.compareRowSrs),
                      (AppIcons.cultureHeritage, 'Все культурные капсулы'),
                      (AppIcons.navDictionary, 'Словарь 7 800+ слов'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            AppIconImage(asset: row.$1, size: 20, color: tokens.accent),
                            const SizedBox(width: 12),
                            Expanded(child: Text(row.$2)),
                            Icon(Icons.check_rounded, color: tokens.success, size: 18),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _CompareTable(l10n: l10n),
              const SizedBox(height: AppSpacing.xl),
              NokhchiinSurfaceCard(
                radius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      l10n.paywallTrialTitle(SubscriptionLimits.trialDays),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.paywallTrialSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.xl),
              NokhchiinButton(
                label: _loading ? '…' : l10n.paywallStartTrial,
                fullWidth: true,
                onPressed: _loading
                    ? null
                    : () => _run(
                          AnalyticsEventName.trialStarted,
                          () => ref.read(billingServiceProvider).startTrial(),
                        ),
              ),
              const SizedBox(height: AppSpacing.md),
              NokhchiinButton(
                label: _loading ? '…' : l10n.paywallBuyPremium,
                fullWidth: true,
                color: tokens.accentMuted,
                textColor: tokens.accent,
                onPressed: _loading
                    ? null
                    : () => _run(
                          AnalyticsEventName.purchaseStarted,
                          () => ref.read(billingServiceProvider).purchasePremium(),
                        ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.paywallRestore,
                variant: AppButtonVariant.ghost,
                expanded: false,
                onPressed: _loading
                    ? null
                    : () => _run(
                          AnalyticsEventName.restoreTapped,
                          () async {
                            await ref.read(billingServiceProvider).restorePurchases();
                            await ref.read(analyticsServiceProvider).track(
                                  AnalyticsEventName.restoreCompleted,
                                );
                          },
                        ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const LegalLinksRow(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, bool, bool)>[
      (l10n.compareRowUnits, true, true),
      (l10n.compareRowPath, false, true),
      (l10n.compareRowSrs, false, true),
      (l10n.compareRowParent, false, true),
      (l10n.compareRowOffline, false, true),
    ];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                child: Text(
                  l10n.compareFree,
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.comparePremium,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(r.$1, style: Theme.of(context).textTheme.bodyMedium)),
                    Expanded(
                      child: Icon(
                        r.$2 ? Icons.check_rounded : Icons.remove_rounded,
                        color: r.$2 ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Icon(
                        r.$3 ? Icons.check_rounded : Icons.remove_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
