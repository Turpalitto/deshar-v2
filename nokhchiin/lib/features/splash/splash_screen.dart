import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/design_system.dart';
import '../../core/providers/providers.dart';
import '../../core/router/app_router.dart';
import '../../domain/entities/learning_entities.dart';

/// Splash — terracotta экран из Figma Make.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Таймер и загрузка профиля идут параллельно — Future.delayed уже
    // тикает, пока мы ждём профиль, так что общее время — max(загрузка,
    // 2200мс), а не их сумма. Раньше профиль читался синхронно (`.value`)
    // сразу после таймера без ожидания future — на медленном/холодном
    // старте это могло быть null, и уже прошедший онбординг пользователь
    // снова попадал на онбординг (аудит §6).
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 2200));
    final profile = await ref.read(userProfileProvider.future).catchError(
          (_) => const UserProfileEntity(),
        );
    await minDelay;
    if (!mounted) return;
    // Проверяем hasCompletedOnboarding, а не profile != null.
    // profile всегда non-null (default = kids), но hasCompletedOnboarding
    // false до выбора трека в onboarding. Аудит logic §9.
    OnboardingGuard.completed = profile.hasCompletedOnboarding;
    context.go(profile.hasCompletedOnboarding ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    const terra = Color(0xFFC4724E);

    return Scaffold(
      backgroundColor: terra,
      body: Stack(
        children: [
          const Positioned.fill(
            child: NokhchiinOrnament(opacity: 0.08, light: true),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NokhchiinAppIcon(size: 96)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.94, 0.94), curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                const Text(
                  'Нохчийн',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Text(
                  'Учи чеченский язык',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ).animate().fadeIn(delay: 160.ms),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
