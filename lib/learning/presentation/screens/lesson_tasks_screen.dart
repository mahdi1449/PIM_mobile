import 'package:flutter/material.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_lesson.dart';
import '../../data/models/learning_task.dart';
import '../../theme/learning_colors.dart';
import '../widgets/learning_top_bar.dart';

class LessonTasksScreen extends StatefulWidget {
  const LessonTasksScreen({
    super.key,
    required this.playerId,
    required this.courseId,
    required this.lesson,
  });

  final String playerId;
  final String courseId;
  final LearningLesson lesson;

  @override
  State<LessonTasksScreen> createState() => _LessonTasksScreenState();
}

class _LessonTasksScreenState extends State<LessonTasksScreen> {
  final LearningApi _api = LearningApi();
  late Future<List<LearningTask>> _future;
  final PageController _controller = PageController();
  int _index = 0;
  bool _saving = false;

  final Map<String, String> _textAnswers = {};
  final Map<String, List<String>> _blankAnswers = {};

  @override
  void initState() {
    super.initState();
    _future = _api.lessonTasks(widget.lesson.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: LearningTopBar(
        title: 'Practice',
        avatarLetter: widget.playerId.isNotEmpty ? widget.playerId[0] : 'O',
      ),
      body: FutureBuilder<List<LearningTask>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load tasks: ${snapshot.error}'),
            );
          }
          final tasks = snapshot.data ?? const <LearningTask>[];
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks for this lesson.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lesson.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (_index + 1) / tasks.length,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE9EDF3),
                              valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_index + 1}/${tasks.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: LearningColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _TaskCard(
                        key: ValueKey(tasks[i].id),
                        task: tasks[i],
                        onTextChanged: (value) =>
                            _textAnswers[tasks[i].id] = value,
                        onBlanksChanged: (answers) =>
                            _blankAnswers[tasks[i].id] = answers,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: LearningColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _index <= 0
                              ? null
                              : () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LearningColors.lime,
                            foregroundColor: LearningColors.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (_index < tasks.length - 1) {
                                    await _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                    return;
                                  }

                                  setState(() => _saving = true);
                                  try {
                                    await _api.updateProgress(
                                      playerId: widget.playerId,
                                      courseId: widget.courseId,
                                      lessonId: widget.lesson.id,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop(true);
                                  } finally {
                                    if (mounted)
                                      setState(() => _saving = false);
                                  }
                                },
                          child: Text(
                            _saving
                                ? 'Saving…'
                                : (_index < tasks.length - 1
                                      ? 'Next'
                                      : 'Finish'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.onTextChanged,
    required this.onBlanksChanged,
  });

  final LearningTask task;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<List<String>> onBlanksChanged;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  final TextEditingController _textController = TextEditingController();
  final List<TextEditingController> _blankControllers = [];

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _blankControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.task.kind.toLowerCase();
    final prompts = (widget.task.payload['prompts'] is List)
        ? (widget.task.payload['prompts'] as List)
              .map((e) => e.toString())
              .toList()
        : const <String>[];

    while (_blankControllers.length < prompts.length) {
      _blankControllers.add(TextEditingController());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LearningColors.border),
      ),
      child: ListView(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: LearningColors.lime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: LearningColors.lime),
                ),
                child: Text(
                  widget.task.kind.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.task.instructions,
            style: TextStyle(
              color: LearningColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (kind == 'fill_blanks' && prompts.isNotEmpty) ...[
            const Text(
              'Fill the blanks',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < prompts.length; i += 1) ...[
              _blankRow(i + 1, prompts[i], _blankControllers[i]),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: LearningColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                widget.onBlanksChanged(
                  _blankControllers.map((c) => c.text).toList(),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saved locally.')));
              },
              child: const Text(
                'Save answers',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ] else ...[
            TextField(
              controller: _textController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: _hintFor(kind),
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: LearningColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: LearningColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: LearningColors.lime,
                    width: 1.2,
                  ),
                ),
              ),
              onChanged: widget.onTextChanged,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: LearningColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                widget.onTextChanged(_textController.text);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saved locally.')));
              },
              child: const Text(
                'Save response',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _blankRow(int idx, String prompt, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearningColors.lime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item $idx',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(prompt, style: const TextStyle(height: 1.3)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Type your answer…',
              filled: true,
              fillColor: LearningColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: LearningColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: LearningColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: LearningColors.lime,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hintFor(String kind) {
    switch (kind) {
      case 'speaking':
        return 'Write your speaking notes…';
      case 'roleplay':
        return 'Write your role-play lines…';
      case 'discussion':
        return 'Write key points…';
      case 'writing':
        return 'Write your answer…';
      default:
        return 'Write your response…';
    }
  }
}
