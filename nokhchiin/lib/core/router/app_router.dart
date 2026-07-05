import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/placement_test_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learning_path/learning_path_screen.dart';
import '../../features/learning_path/lesson_flow_screen.dart';
import '../../features/learning_path/unit_detail_screen.dart';
import '../../features/dictionary/dictionary_screen.dart';
import '../../features/dictionary/dictionary_detail_screen.dart';
import '../../features/games/flashcards_screen.dart';
import '../../features/games/quiz_screen.dart';
import '../../features/games/match_screen.dart';
import '../../features/insights/adult_insights_dashboard_screen.dart';
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
import '../../features/legal/legal_document_screen.dart';
import '../../features/games/typing_exercise_screen.dart';
import '../../features/culture/culture_capsule_preview_screen.dart';
import '../design/widgets/app_shell.dart';
import 'route_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Первый урок после onboarding.
const kFirstLessonUnitId = 'animals';

Page<void> _fadeScale(GoRouterState state, Widget child) => buildFadeScalePage(state: state, child: child);

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/placement',
      builder: (_, __) => const PlacementTestScreen(),
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
      pageBuilder: (context, state) => _fadeScale(state, const LearningPathScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/unit/:id',
      pageBuilder: (context, state) =>
          _fadeScale(state, UnitDetailScreen(unitId: state.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/lesson/:unitId',
      pageBuilder: (context, state) =>
          _fadeScale(state, LessonFlowScreen(unitId: state.pathParameters['unitId']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/dictionary',
      pageBuilder: (context, state) => _fadeScale(state, const DictionaryScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/dictionary/:id',
      pageBuilder: (context, state) =>
          _fadeScale(state, DictionaryDetailScreen(id: state.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/parent',
      pageBuilder: (context, state) => _fadeScale(state, const ParentDashboardScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/flashcards/:unitId',
      pageBuilder: (context, state) =>
          _fadeScale(state, FlashcardsScreen(unitId: state.pathParameters['unitId']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quiz/:unitId',
      pageBuilder: (context, state) =>
          _fadeScale(state, QuizScreen(unitId: state.pathParameters['unitId']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/match/:unitId',
      pageBuilder: (context, state) =>
          _fadeScale(state, MatchScreen(unitId: state.pathParameters['unitId']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/collections',
      pageBuilder: (context, state) => _fadeScale(state, const CollectionsScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/stories',
      pageBuilder: (context, state) => _fadeScale(state, const StoriesListScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/story/:id',
      pageBuilder: (context, state) =>
          _fadeScale(state, StoryReaderScreen(storyId: state.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/boss/:unitId',
      pageBuilder: (context, state) =>
          _fadeScale(state, BossScreen(unitId: state.pathParameters['unitId']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/insights',
      pageBuilder: (context, state) => _fadeScale(state, const AdultInsightsDashboardScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/progress',
      pageBuilder: (context, state) => _fadeScale(state, const ProgressScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/legal/privacy',
      pageBuilder: (context, state) =>
          _fadeScale(state, const LegalDocumentScreen(type: LegalDocumentType.privacy)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/legal/terms',
      pageBuilder: (context, state) =>
          _fadeScale(state, const LegalDocumentScreen(type: LegalDocumentType.terms)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/paywall',
      pageBuilder: (context, state) =>
          _fadeScale(state, PaywallScreen(returnPath: state.uri.queryParameters['return'])),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/dev/culture-capsules',
      pageBuilder: (context, state) => _fadeScale(state, const CultureCapsulePreviewScreen()),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/typing/:unitId',
      pageBuilder: (context, state) =>
          _fadeScale(state, TypingExerciseScreen(unitId: state.pathParameters['unitId']!)),
    ),
  ],
);
