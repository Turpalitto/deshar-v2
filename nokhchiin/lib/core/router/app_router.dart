import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learning_path/learning_path_screen.dart';
import '../../features/learning_path/lesson_flow_screen.dart';
import '../../features/learning_path/unit_detail_screen.dart';
import '../../features/dictionary/dictionary_screen.dart';
import '../../features/games/flashcards_screen.dart';
import '../../features/games/quiz_screen.dart';
import '../../features/games/match_screen.dart';
import '../../features/parent/parent_dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/worlds/worlds_map_screen.dart';
import '../../features/collections/collections_screen.dart';
import '../../features/boss/boss_screen.dart';
import '../../features/stories/stories_list_screen.dart';
import '../../features/stories/story_reader_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/paywall/paywall_screen.dart';
import '../../features/games/typing_exercise_screen.dart';
import '../design/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Первый урок после onboarding.
const kFirstLessonUnitId = 'animals';

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/worlds',
              builder: (_, __) => const WorldsMapScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/review',
              builder: (_, __) => const ReviewScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/path',
      builder: (_, __) => const LearningPathScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/unit/:id',
      builder: (_, state) => UnitDetailScreen(unitId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/lesson/:unitId',
      builder: (_, state) => LessonFlowScreen(unitId: state.pathParameters['unitId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/dictionary',
      builder: (_, __) => const DictionaryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/parent',
      builder: (_, __) => const ParentDashboardScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/flashcards/:unitId',
      builder: (_, state) => FlashcardsScreen(unitId: state.pathParameters['unitId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quiz/:unitId',
      builder: (_, state) => QuizScreen(unitId: state.pathParameters['unitId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/match/:unitId',
      builder: (_, state) => MatchScreen(unitId: state.pathParameters['unitId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/collections',
      builder: (_, __) => const CollectionsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/stories',
      builder: (_, __) => const StoriesListScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/story/:id',
      builder: (_, state) => StoryReaderScreen(storyId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/boss/:unitId',
      builder: (_, state) => BossScreen(unitId: state.pathParameters['unitId']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/progress',
      builder: (_, __) => const ProgressScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/paywall',
      builder: (_, state) => PaywallScreen(returnPath: state.uri.queryParameters['return']),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/typing/:unitId',
      builder: (_, state) => TypingExerciseScreen(unitId: state.pathParameters['unitId']!),
    ),
  ],
);
