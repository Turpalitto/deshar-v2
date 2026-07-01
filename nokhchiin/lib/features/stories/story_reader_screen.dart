import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/content_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/widgets/word_illustration.dart';

final _audioProvider = Provider((_) => AudioService());

class StoryReaderScreen extends ConsumerStatefulWidget {
  const StoryReaderScreen({super.key, required this.storyId});
  final String storyId;

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  int _panel = 0;
  bool _quizMode = false;
  int _quizIndex = 0;
  int _quizScore = 0;
  Map<String, dynamic>? _story;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(contentSourceProvider).loadStory(widget.storyId);
    if (mounted) setState(() => _story = s);
  }

  List<Map<String, dynamic>> get _panels =>
      (_story?['panels'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  List<Map<String, dynamic>> get _quiz =>
      (_story?['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  void _nextPanel() {
    if (_panel < _panels.length - 1) {
      setState(() => _panel++);
    } else if (_quiz.isNotEmpty) {
      setState(() => _quizMode = true);
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(userProfileProvider.notifier).addXp(40, 10);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('История прочитана! 🎉'),
        content: const Text('Отличная работа! +40 XP'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ура!')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_story == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_quizMode) {
      return _buildQuiz(context);
    }

    final panel = _panels[_panel];
    final dialogue = (panel['dialogue'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final unitId = _story!['unitId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(_story!['titleRu'] as String),
        actions: [
          Text('${_panel + 1}/${_panels.length}', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WordIllustration(
              category: unitId,
              emoji: _story!['emoji'] as String?,
              size: 200,
            ),
            const SizedBox(height: 16),
            if (panel['narrationRu'] != null)
              Text(
                panel['narrationRu'] as String,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ...dialogue.map((d) => _DialogueBubble(
                  speaker: d['speaker'] as String? ?? '',
                  chechen: d['chechen'] as String? ?? '',
                  russian: d['russian'] as String? ?? '',
                  onSpeak: () => ref.read(_audioProvider).speakChechen(d['chechen'] as String? ?? ''),
                )),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_panel > 0)
                  TextButton(
                    onPressed: () => setState(() => _panel--),
                    child: const Text('Назад'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _nextPanel,
                  child: Text(_panel < _panels.length - 1 ? 'Далее' : (_quiz.isNotEmpty ? 'Квиз' : 'Готово')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz(BuildContext context) {
    if (_quizIndex >= _quiz.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const Scaffold(body: Center(child: Text('Завершение...')));
    }

    final q = _quiz[_quizIndex];
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    final answer = q['answer'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Проверь себя')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const FoxMascot(size: 64, emotion: FoxEmotion.thinking),
            Text(q['question'] as String, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const Spacer(),
            ...options.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (o == answer) _quizScore++;
                        setState(() => _quizIndex++);
                      },
                      child: Padding(padding: const EdgeInsets.all(14), child: Text(o)),
                    ),
                  ),
                )),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  const _DialogueBubble({
    required this.speaker,
    required this.chechen,
    required this.russian,
    required this.onSpeak,
  });

  final String speaker, chechen, russian;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (speaker.isNotEmpty)
                    Text(speaker, style: Theme.of(context).textTheme.labelLarge),
                  Text(chechen, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(russian, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.volume_up_rounded), onPressed: onSpeak),
          ],
        ),
      ),
    );
  }
}
