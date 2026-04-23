import 'package:flutter/material.dart';
import '../../data/learning_api.dart';
import '../../theme/learning_colors.dart';

class LearningChatScreen extends StatefulWidget {
  const LearningChatScreen({super.key, required this.playerId});

  final String playerId;

  @override
  State<LearningChatScreen> createState() => _LearningChatScreenState();
}

class _LearningChatScreenState extends State<LearningChatScreen> {
  final LearningApi _api = LearningApi();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Hi! Choose a mode and send a message. I will correct your English and role-play.',
    },
  ];
  String _mode = 'practice';
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: AppBar(
        title: const Text('Sports English Coach'),
        backgroundColor: LearningColors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                _modeChip('Practice', 'practice'),
                const SizedBox(width: 10),
                _modeChip('Interview', 'interview'),
                const SizedBox(width: 10),
                _modeChip('Press', 'press_conference'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: isUser
                          ? LearningColors.lime.withValues(alpha: 0.18)
                          : LearningColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUser
                            ? LearningColors.lime
                            : LearningColors.border,
                      ),
                    ),
                    child: Text(
                      (m['content'] ?? '').toString(),
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: LearningColors.card,
              border: Border(top: BorderSide(color: LearningColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: Icon(
                    _sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  ),
                  color: LearningColors.limeDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, String value) {
    final active = _mode == value;
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? LearningColors.lime.withValues(alpha: 0.18)
              : LearningColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? LearningColors.lime : LearningColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active ? LearningColors.text : LearningColors.textMuted,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _sending = true;
    });
    try {
      final res = await _api.chat(
        mode: _mode,
        playerId: widget.playerId,
        messages: _messages
            .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
            .map((m) => {'role': m['role']!, 'content': m['content']!})
            .toList(),
      );
      final reply = (res['reply'] ?? '').toString();
      if (mounted) {
        setState(() => _messages.add({'role': 'assistant', 'content': reply}));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _messages.add({'role': 'assistant', 'content': 'Error: $e'}),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
