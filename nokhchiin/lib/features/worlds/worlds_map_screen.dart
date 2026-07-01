import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/providers/providers.dart';

class WorldsMapScreen extends ConsumerWidget {
  const WorldsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = ref.watch(worldsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final stars = profile?.stars ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Миры')),
      body: worlds.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final w = list[i];
            final unlocked = stars >= (w['unlockStars'] as int? ?? 0);
            final gradient = (w['gradient'] as List).cast<String>();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: unlocked
                      ? () {
                          final units = (w['units'] as List).cast<String>();
                          if (units.isNotEmpty) context.push('/unit/${units.first}');
                        }
                      : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient.map((h) => Color(int.parse(h.replaceFirst('#', '0xFF')))).toList(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Text(w['emoji'] as String? ?? '🌍', style: const TextStyle(fontSize: 48)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w['titleCe'] as String, style: Theme.of(context).textTheme.labelLarge),
                                Text(w['titleRu'] as String, style: Theme.of(context).textTheme.headlineMedium),
                                Text(
                                  unlocked ? 'Открыт' : 'Нужно ${w['unlockStars']} ⭐',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(unlocked ? '▶' : '🔒', style: const TextStyle(fontSize: 24)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
