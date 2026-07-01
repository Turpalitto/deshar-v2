import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/mastery_progress_bar.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(learningUnitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Путь обучения')),
      body: units.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final u = list[i];
            final isLast = i == list.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: u.isUnlocked ? const Color(0xFF1A73E8) : Colors.grey.shade300,
                      ),
                      child: Center(
                        child: Text(
                          u.isUnlocked ? '${u.order}' : '🔒',
                          style: TextStyle(
                            color: u.isUnlocked ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 60, color: Colors.grey.shade300),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Card(
                      child: InkWell(
                        onTap: u.isUnlocked ? () => context.push('/unit/${u.id}') : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.titleCe, style: Theme.of(context).textTheme.labelLarge),
                              Text(u.titleRu, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              MasteryProgressBar(percent: u.masteryPercent),
                              Text('${u.masteryPercent}% · нужно ${u.requiredMastery}% для следующей',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
