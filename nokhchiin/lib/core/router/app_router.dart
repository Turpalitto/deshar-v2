import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learning_path/learning_path_screen.dart';
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
import '../../features/ai_tutor/ai_tutor_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'path',
          builder: (_, __) => const LearningPathScreen(),
        ),
        GoRoute(
          path: 'unit/:id',
          builder: (_, state) => UnitDetailScreen(
            unitId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'dictionary',
          builder: (_, __) => const DictionaryScreen(),
        ),
        GoRoute(
          path: 'review',
          builder: (_, __) => const ReviewScreen(),
        ),
        GoRoute(
          path: 'parent',
          builder: (_, __) => const ParentDashboardScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'flashcards/:unitId',
          builder: (_, state) => FlashcardsScreen(
            unitId: state.pathParameters['unitId']!,
          ),
        ),
        GoRoute(
          path: 'quiz/:unitId',
          builder: (_, state) => QuizScreen(
            unitId: state.pathParameters['unitId']!,
          ),
        ),
        GoRoute(
          path: 'match/:unitId',
          builder: (_, state) => MatchScreen(
            unitId: state.pathParameters['unitId']!,
          ),
        ),
        GoRoute(
          path: 'worlds',
          builder: (_, __) => const WorldsMapScreen(),
        ),
        GoRoute(
          path: 'collections',
          builder: (_, __) => const CollectionsScreen(),
        ),
        GoRoute(
          path: 'stories',
          builder: (_, __) => const StoriesListScreen(),
        ),
        GoRoute(
          path: 'story/:id',
          builder: (_, state) => StoryReaderScreen(
            storyId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'boss/:unitId',
          builder: (_, state) => BossScreen(
            unitId: state.pathParameters['unitId']!,
          ),
        ),
        GoRoute(
          path: 'tutor',
          builder: (_, __) => const AiTutorScreen(),
        ),
      ],
    ),
  ],
);
