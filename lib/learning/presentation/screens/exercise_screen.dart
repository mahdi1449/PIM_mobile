import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_lesson_detail.dart';
import '../../theme/learning_colors.dart';
import '../widgets/learning_top_bar.dart';
import 'exercise_result_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    super.key,
    required this.playerId,
    required this.exercise,
  });

  final String playerId;
  final LearningExercise exercise;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final LearningApi _api = LearningApi();
  bool _submitting = false;

  final Map<String, dynamic> _answers = {};

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;

    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: LearningTopBar(
        title: 'Exercise',
        avatarLetter: widget.playerId.isNotEmpty ? widget.playerId[0] : 'O',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Text(ex.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            ex.type.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(color: LearningColors.textMuted, fontWeight: FontWeight.w800),
          ),
          if (ex.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(ex.instructions, style: TextStyle(color: LearningColors.textMuted, height: 1.35)),
          ],
          if (_readingText(ex).trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _readingCard(_readingTitle(ex), _readingText(ex)),
          ],
          if (ex.prompt.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _promptCard(ex.prompt),
          ],
          const SizedBox(height: 14),
          if (ex.questions.isNotEmpty) ...[
            for (final q in ex.questions) ...[
              _questionCard(q, ex.type),
              const SizedBox(height: 12),
            ]
          ] else ...[
            _openTextFallback(ex),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.lime,
                foregroundColor: LearningColors.text,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting…' : (ex.graded ? 'Submit' : 'Save')),
            ),
          ),
        ],
      ),
    );
  }

  String _readingTitle(LearningExercise ex) => (ex.payload['readingTitle'] ?? '').toString();
  String _readingText(LearningExercise ex) => (ex.payload['readingText'] ?? '').toString();

  Widget _readingCard(String title, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty)
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          if (title.trim().isNotEmpty) const SizedBox(height: 10),
          Text(text, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _promptCard(String prompt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.lime.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.lime),
      ),
      child: Text(prompt, style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
    );
  }

  Widget _openTextFallback(LearningExercise ex) {
    final controller = TextEditingController(text: (_answers['text'] ?? '').toString());
    return TextField(
      controller: controller,
      maxLines: 8,
      decoration: InputDecoration(
        hintText: 'Write your response…',
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
          borderSide: BorderSide(color: LearningColors.lime, width: 1.2),
        ),
      ),
      onChanged: (v) => _answers['text'] = v,
    );
  }

  Widget _questionCard(LearningQuestion q, String exerciseType) {
    final type = q.type.isNotEmpty ? q.type : exerciseType;
    switch (type) {
      case 'multiple_choice':
        return _multipleChoice(q);
      case 'true_false':
        return _trueFalse(q);
      case 'fill_in_blank':
      case 'dialogue_gap_fill':
        return _fillBlanks(q);
      case 'matching':
        return _matching(q);
      case 'reorder_sentence':
        return _reorderSentence(q);
      default:
        return _openText(q);
    }
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
      ),
      child: child,
    );
  }

  Widget _openText(LearningQuestion q) {
    final controller = TextEditingController(text: (_answers[q.id] ?? '').toString());
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Type your answer…',
              filled: true,
              fillColor: const Color(0xFFF2F4F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: LearningColors.border),
              ),
            ),
            onChanged: (v) => _answers[q.id] = v,
          ),
        ],
      ),
    );
  }

  Widget _multipleChoice(LearningQuestion q) {
    final selected = _answers[q.id] as String?;
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final opt in q.options)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == opt.id ? LearningColors.lime : LearningColors.border,
                ),
                color: selected == opt.id ? LearningColors.lime.withValues(alpha: 0.10) : Colors.transparent,
              ),
              child: RadioListTile<String>(
                value: opt.id,
                groupValue: selected,
                onChanged: (v) => setState(() => _answers[q.id] = v),
                title: Text(opt.text),
                dense: true,
                activeColor: LearningColors.limeDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trueFalse(LearningQuestion q) {
    final selected = _answers[q.id];
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tfButton(q.id, true, selected == true, 'True'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _tfButton(q.id, false, selected == false, 'False'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tfButton(String qid, bool value, bool active, String label) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: active ? LearningColors.lime : LearningColors.border),
        backgroundColor: active ? LearningColors.lime.withValues(alpha: 0.10) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => setState(() => _answers[qid] = value),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _fillBlanks(LearningQuestion q) {
    final exercise = widget.exercise;
    final items = (exercise.payload['items'] as List? ?? const []).map((e) => e.toString()).toList();
    final sentences = (exercise.payload['sentences'] as List? ?? const []).map((e) => e.toString()).toList();
    final dialogue = (exercise.payload['dialogue'] as List? ?? const []).map((e) => e.toString()).toList();
    final lines = items.isNotEmpty ? items : (sentences.isNotEmpty ? sentences : dialogue);

    final blanks = (_answers[q.id] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final blankCount = _countBlanks(lines.join('\n'));
    while (blanks.length < blankCount) {
      blanks.add('');
    }

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(lines.join('\n'), style: const TextStyle(height: 1.35)),
          const SizedBox(height: 12),
          for (int i = 0; i < blankCount; i += 1) ...[
            TextField(
              decoration: InputDecoration(
                labelText: 'Blank ${i + 1}',
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (v) {
                blanks[i] = v;
                _answers[q.id] = blanks;
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  int _countBlanks(String text) {
    final matches = RegExp(r'_{2,}|\\b____\\b|\\b______\\b|\\b\\_\\_\\_\\_\\b').allMatches(text).length;
    final legacy = RegExp(r'_{2,}').allMatches(text).length;
    return max(1, max(matches, legacy));
  }

  Widget _matching(LearningQuestion q) {
    final ex = widget.exercise;
    final left = (ex.payload['left'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final right = (ex.payload['right'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final map = (_answers[q.id] is Map)
        ? Map<String, dynamic>.from(_answers[q.id] as Map)
        : <String, dynamic>{};

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.prompt, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final l in left) ...[
            _matchRow(
              leftId: (l['id'] ?? '').toString(),
              leftText: (l['text'] ?? '').toString(),
              right: right,
              selectedRightId: map[(l['id'] ?? '').toString()]?.toString(),
              onChanged: (rid) => setState(() {
                map[(l['id'] ?? '').toString()] = rid;
                _answers[q.id] = map;
              }),
            ),
            const SizedBox(height: 10),
          ]
        ],
      ),
    );
  }

  Widget _matchRow({
    required String leftId,
    required String leftText,
    required List<Map<String, dynamic>> right,
    required String? selectedRightId,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LearningColors.lime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LearningColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(leftText, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: selectedRightId,
            hint: const Text('Select'),
            items: right
                .map(
                  (r) => DropdownMenuItem<String>(
                    value: (r['id'] ?? '').toString(),
                    child: Text((r['text'] ?? '').toString()),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _reorderSentence(LearningQuestion q) {
    final raw = q.prompt.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (raw.isEmpty) {
      return _openText(q);
    }
    final key = 'order:${q.id}';
    final current = (_answers[key] as List?)?.map((e) => e.toString()).toList();
    final tokens = current ?? (raw.toList()..shuffle(Random(q.id.hashCode)));
    _answers[key] = tokens;

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reorder the words to make a correct sentence:', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(q.prompt, style: TextStyle(color: LearningColors.textMuted)),
          const SizedBox(height: 12),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) => setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = tokens.removeAt(oldIndex);
              tokens.insert(newIndex, item);
              _answers[key] = tokens;
              _answers[q.id] = tokens;
            }),
            children: [
              for (int i = 0; i < tokens.length; i += 1)
                ListTile(
                  key: ValueKey('$key-$i-${tokens[i]}'),
                  title: Text(tokens[i], style: const TextStyle(fontWeight: FontWeight.w800)),
                  tileColor: const Color(0xFFF2F4F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final ex = widget.exercise;
      final res = await _api.submitExercise(
        playerId: widget.playerId,
        exerciseId: ex.id,
        answers: _answers,
      );
      if (!mounted) return;
      if (ex.graded) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseResultScreen(result: res),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
