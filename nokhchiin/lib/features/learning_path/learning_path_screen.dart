import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/widgets/app_scaffold.dart';
import '../../core/design/widgets/error_state.dart';
import '../../core/design/widgets/loading_state.dart';
import '../../core/providers/providers.dart';
import 'widgets/learning_path_trail.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(learningUnitsProvider);

    return AppScaffold(
      title: 'Путь обучения',
      body: units.when(
        data: (list) => LearningPathTrail(units: list),
        loading: () => const LoadingState(message: 'Строим путь…'),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}
