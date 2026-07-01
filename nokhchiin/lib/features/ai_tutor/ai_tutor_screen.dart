import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/word_illustration.dart';
import '../../data/repositories/repository_impl.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/repositories.dart';

final aiTutorRepoProvider = Provider<AiTutorRepository>((_) => AiTutorRepositoryStub());

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser, this.word});
  final String text;
  final bool isUser;
  final WordEntity? word;
}

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatMessage>[
    _ChatMessage(
      text: 'Салам! Я Цхьогал — твой помощник по чеченскому. '
          'Спроси о слове, попроси объяснить ошибку или потренируй фразы.',
      isUser: false,
    ),
  ];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
    });
    _scrollToEnd();

    final tutor = ref.read(aiTutorRepoProvider);
    final dict = ref.read(dictionaryRepoProvider);
    String reply;
    WordEntity? related;

    final lower = text.toLowerCase();
    if (lower.contains('ошиб') || lower.contains('неправильно')) {
      final words = await dict.getAllWords();
      related = words.isNotEmpty ? words[text.hashCode.abs() % words.length] : null;
      if (related != null) {
        reply = await tutor.explainMistake(word: related, userAnswer: text);
      } else {
        reply = 'Расскажи, какое слово вызвало трудность — разберём вместе.';
      }
    } else if (lower.contains('практик') || lower.contains('фраз') || lower.contains('предложен')) {
      final words = (await dict.getAllWords()).take(5).toList();
      final sentences = await tutor.generatePracticeSentences(words: words);
      reply = 'Вот фразы для тренировки:\n\n${sentences.map((s) => '• $s').join('\n')}';
    } else {
      final results = await dict.search(text);
      if (results.isNotEmpty) {
        related = results.first;
        reply = '${related.chechen} — ${related.russian}. '
            'Нажми 🔊 в словаре или спроси «практика» для упражнений.';
      } else {
        reply = 'Пока я учусь на локальных данных. Попробуй: «что значит Маршалла» '
            'или «дай практику». Скоро подключим облачный AI.';
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false, word: related));
      _loading = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            FoxMascot(size: 36),
            SizedBox(width: 10),
            Text('AI-преподаватель'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        FoxMascot(size: 32, emotion: FoxEmotion.thinking),
                        SizedBox(width: 8),
                        Text('Думаю...'),
                      ],
                    ),
                  );
                }
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                    decoration: BoxDecoration(
                      color: m.isUser ? const Color(0xFF1A73E8) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: m.isUser ? null : Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.word != null) ...[
                          WordIllustration(
                            category: m.word!.category,
                            emoji: m.word!.emoji,
                            size: 64,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          m.text,
                          style: TextStyle(
                            color: m.isUser ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Спроси о слове или попроси практику...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
