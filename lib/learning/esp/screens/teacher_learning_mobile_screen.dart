import 'package:flutter/material.dart';
import '../data/esp_mock_data.dart';
import '../models/esp_models.dart';
import '../ui/esp_theme.dart';

class TeacherLearningMobileScreen extends StatefulWidget {
  const TeacherLearningMobileScreen({
    super.key,
    required this.teacherName,
    this.avatarUrl,
  });

  final String teacherName;
  final String? avatarUrl;

  @override
  State<TeacherLearningMobileScreen> createState() =>
      _TeacherLearningMobileScreenState();
}

class _TeacherLearningMobileScreenState extends State<TeacherLearningMobileScreen> {
  int _activeTab = 0;
  EspDifficulty _selectedLevel = EspDifficulty.beginner;
  String _selectedCategory = 'Vocabulary';
  EspExerciseType _selectedExerciseType = EspExerciseType.fillBlank;
  EspQuestionType _selectedQuestionType = EspQuestionType.mcq;
  final Set<String> _selectedBlocks = <String>{'Text', 'Vocabulary'};

  final TextEditingController _lessonTitleController = TextEditingController(
    text: 'Match Day Communication',
  );
  final TextEditingController _lessonDescriptionController = TextEditingController(
    text: 'Teach players how to answer media questions with confidence.',
  );
  final TextEditingController _exercisePromptController = TextEditingController(
    text: 'Complete: "Stay ____ and trust the game plan."',
  );
  final TextEditingController _quizQuestionController = TextEditingController(
    text: 'What does "hold the line" mean?',
  );
  final TextEditingController _quizExplanationController = TextEditingController(
    text: 'It means defenders keep shape and avoid dropping too deep.',
  );
  final List<TextEditingController> _quizOptionControllers = [
    TextEditingController(text: 'Defenders stay organized in one line'),
    TextEditingController(text: 'Only strikers press the goalkeeper'),
    TextEditingController(text: 'Midfielders stop passing'),
    TextEditingController(text: 'Wingers move to the bench'),
  ];
  int _correctQuizOption = 0;

  @override
  void dispose() {
    _lessonTitleController.dispose();
    _lessonDescriptionController.dispose();
    _exercisePromptController.dispose();
    _quizQuestionController.dispose();
    _quizExplanationController.dispose();
    for (final controller in _quizOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EspTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            _TeacherHeader(
              teacherName: widget.teacherName,
              avatarUrl: widget.avatarUrl,
            ),
            const SizedBox(height: 8),
            _TabStrip(
              activeIndex: _activeTab,
              onChanged: (value) => setState(() => _activeTab = value),
              labels: const [
                'Dashboard',
                'Lessons',
                'Tasks',
                'Quiz',
                'Players',
                'Analytics',
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tabBody(_activeTab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBody(int index) {
    switch (index) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildLessonBuilderTab();
      case 2:
        return _buildTaskBuilderTab();
      case 3:
        return _buildQuizBuilderTab();
      case 4:
        return _buildPlayersTab();
      case 5:
      default:
        return _buildAnalyticsTab();
    }
  }

  Widget _buildDashboardTab() {
    return ListView(
      key: const ValueKey<String>('teacher-dashboard'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Instructor Dashboard',
          subtitle: 'Live ESP learning KPIs in ODIN ERP CLUB',
          icon: Icons.dashboard_rounded,
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: EspMockData.teacherMetrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, index) {
            final metric = EspMockData.teacherMetrics[index];
            return _MetricCard(metric: metric);
          },
        ),
        const SizedBox(height: 16),
        const _SectionTitle(
          title: 'Quick Actions',
          subtitle: 'Create lessons, tasks, and quizzes in one flow',
          icon: Icons.flash_on_rounded,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.auto_stories_rounded,
          title: 'Create a new lesson',
          subtitle: 'Build vocabulary, video, and speaking blocks',
          actionLabel: 'Open Lesson Builder',
          onTap: () => setState(() => _activeTab = 1),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.rule_rounded,
          title: 'Create interactive task',
          subtitle: 'Fill blank, matching, drag and speaking practice',
          actionLabel: 'Open Task Builder',
          onTap: () => setState(() => _activeTab = 2),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.quiz_rounded,
          title: 'Publish quiz',
          subtitle: 'MCQ, true/false, and listening questions',
          actionLabel: 'Open Quiz Builder',
          onTap: () => setState(() => _activeTab = 3),
        ),
      ],
    );
  }

  Widget _buildLessonBuilderTab() {
    return ListView(
      key: const ValueKey<String>('teacher-lessons'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Lesson Builder (Mobile)',
          subtitle: 'Create lessons directly from phone or tablet',
          icon: Icons.auto_stories_rounded,
        ),
        const SizedBox(height: 10),
        _FormCard(
          child: Column(
            children: [
              _FieldLabel(title: 'Title'),
              _DarkTextField(controller: _lessonTitleController),
              const SizedBox(height: 10),
              _FieldLabel(title: 'Description'),
              _DarkTextField(
                controller: _lessonDescriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DropdownField<EspDifficulty>(
                      label: 'Level',
                      value: _selectedLevel,
                      items: EspDifficulty.values
                          .map(
                            (level) => DropdownMenuItem<EspDifficulty>(
                              value: level,
                              child: Text(difficultyLabel(level)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLevel = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Category',
                      value: _selectedCategory,
                      items: const [
                        'Vocabulary',
                        'Training',
                        'Match',
                        'Medical',
                        'Motivational',
                      ]
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _FieldLabel(title: 'Content Blocks'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EspMockData.contentBlocks.map((block) {
                  final selected = _selectedBlocks.contains(block.label);
                  return FilterChip(
                    selected: selected,
                    backgroundColor: EspTheme.background,
                    selectedColor: EspTheme.neonGreen.withOpacity(0.2),
                    side: BorderSide(
                      color: selected ? EspTheme.neonGreen : EspTheme.border,
                    ),
                    avatar: Icon(block.icon, size: 16, color: EspTheme.neonBlue),
                    label: Text(
                      block.label,
                      style: const TextStyle(color: EspTheme.textPrimary),
                    ),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedBlocks.add(block.label);
                        } else {
                          _selectedBlocks.remove(block.label);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showSavedToast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EspTheme.neonGreen,
                    foregroundColor: EspTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Lesson'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBuilderTab() {
    return ListView(
      key: const ValueKey<String>('teacher-tasks'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Task Builder',
          subtitle: 'Create practical exercises for players',
          icon: Icons.rule_rounded,
        ),
        const SizedBox(height: 10),
        _FormCard(
          child: Column(
            children: [
              _DropdownField<EspExerciseType>(
                label: 'Exercise Type',
                value: _selectedExerciseType,
                items: EspExerciseType.values
                    .map(
                      (value) => DropdownMenuItem<EspExerciseType>(
                        value: value,
                        child: Text(exerciseTypeLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedExerciseType = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              _FieldLabel(title: 'Prompt / Instructions'),
              _DarkTextField(controller: _exercisePromptController, maxLines: 3),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EspTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EspTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        color: EspTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exerciseTypeLabel(_selectedExerciseType),
                      style: const TextStyle(
                        color: EspTheme.neonBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _exercisePromptController.text,
                      style: const TextStyle(color: EspTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showSavedToast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EspTheme.neonBlue,
                    foregroundColor: EspTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Create Task'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizBuilderTab() {
    return ListView(
      key: const ValueKey<String>('teacher-quiz'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Quiz Builder',
          subtitle: 'Build MCQ / True-False / Listening questions',
          icon: Icons.quiz_rounded,
        ),
        const SizedBox(height: 10),
        _FormCard(
          child: Column(
            children: [
              _DropdownField<EspQuestionType>(
                label: 'Question Type',
                value: _selectedQuestionType,
                items: EspQuestionType.values
                    .map(
                      (value) => DropdownMenuItem<EspQuestionType>(
                        value: value,
                        child: Text(_questionTypeLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedQuestionType = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              _FieldLabel(title: 'Question'),
              _DarkTextField(controller: _quizQuestionController),
              const SizedBox(height: 10),
              ...List.generate(_quizOptionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DarkTextField(
                    controller: _quizOptionControllers[index],
                    hint: 'Option ${index + 1}',
                  ),
                );
              }),
              const SizedBox(height: 2),
              _DropdownField<int>(
                label: 'Correct Answer',
                value: _correctQuizOption,
                items: List.generate(
                  _quizOptionControllers.length,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text('Option ${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _correctQuizOption = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              _FieldLabel(title: 'Explanation'),
              _DarkTextField(
                controller: _quizExplanationController,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showSavedToast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EspTheme.neonGreen,
                    foregroundColor: EspTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.publish_outlined),
                  label: const Text('Publish Quiz'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersTab() {
    return ListView(
      key: const ValueKey<String>('teacher-players'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Player Management',
          subtitle: 'Track individual progress and assign lessons',
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: 10),
        ...EspMockData.playerPerformances.map(
          (player) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlayerPerformanceCard(player: player),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      key: const ValueKey<String>('teacher-analytics'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _SectionTitle(
          title: 'Analytics',
          subtitle: 'Weak areas and engagement insights',
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EspTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EspTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weak Areas',
                style: TextStyle(
                  color: EspTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...EspMockData.weakAreas.map(
                (area) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              area.label,
                              style: const TextStyle(color: EspTheme.textSecondary),
                            ),
                          ),
                          Text(
                            '${area.value}%',
                            style: const TextStyle(
                              color: EspTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: area.value / 100,
                          minHeight: 8,
                          backgroundColor: EspTheme.surfaceAlt,
                          valueColor: AlwaysStoppedAnimation<Color>(area.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.psychology_alt_outlined,
          title: 'AI Recommendation',
          subtitle: 'Assign extra listening drills to U17 (avg < 70%)',
          actionLabel: 'Generate personalized plan',
          onTap: _showSavedToast,
        ),
      ],
    );
  }

  String _questionTypeLabel(EspQuestionType value) {
    switch (value) {
      case EspQuestionType.mcq:
        return 'MCQ';
      case EspQuestionType.trueFalse:
        return 'True / False';
      case EspQuestionType.listening:
        return 'Listening';
    }
  }

  void _showSavedToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.teacherName,
    required this.avatarUrl,
  });

  final String teacherName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: EspTheme.cardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: EspTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: EspTheme.surfaceAlt,
              backgroundImage:
                  avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(Icons.school_outlined, color: EspTheme.neonBlue)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacherName,
                    style: const TextStyle(
                      color: EspTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Teacher Interface • Mobile',
                    style: TextStyle(
                      color: EspTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EspTheme.neonBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: EspTheme.neonBlue.withOpacity(0.45)),
              ),
              child: const Text(
                'ESP',
                style: TextStyle(
                  color: EspTheme.neonBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.activeIndex,
    required this.onChanged,
    required this.labels,
  });

  final int activeIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final selected = index == activeIndex;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onChanged(index),
            backgroundColor: EspTheme.surface,
            selectedColor: EspTheme.neonBlue.withOpacity(0.18),
            side: BorderSide(color: selected ? EspTheme.neonBlue : EspTheme.border),
            label: Text(
              labels[index],
              style: TextStyle(
                color: selected ? EspTheme.neonBlue : EspTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: EspTheme.surfaceAlt,
            border: Border.all(color: EspTheme.border),
          ),
          child: Icon(icon, size: 18, color: EspTheme.neonBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: EspTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: EspTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final EspTeacherMetric metric;

  @override
  Widget build(BuildContext context) {
    final deltaColor = metric.positive ? EspTheme.neonGreen : EspTheme.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EspTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: const TextStyle(color: EspTheme.textSecondary, fontSize: 12),
          ),
          const Spacer(),
          Text(
            metric.value,
            style: const TextStyle(
              color: EspTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.deltaLabel,
            style: TextStyle(
              color: deltaColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EspTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: EspTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: EspTheme.neonBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: EspTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: EspTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EspTheme.border),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: EspTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: EspTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EspTheme.textSecondary),
        filled: true,
        fillColor: EspTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EspTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EspTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EspTheme.neonBlue),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: EspTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: EspTheme.surfaceAlt,
          decoration: InputDecoration(
            filled: true,
            fillColor: EspTheme.background,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EspTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EspTheme.border),
            ),
          ),
          style: const TextStyle(color: EspTheme.textPrimary),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PlayerPerformanceCard extends StatelessWidget {
  const _PlayerPerformanceCard({required this.player});

  final EspPlayerPerformance player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EspTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    color: EspTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${player.progressPercent}%',
                style: const TextStyle(
                  color: EspTheme.neonGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ScoreRow(label: 'Vocabulary', value: player.vocabularyScore),
          _ScoreRow(label: 'Listening', value: player.listeningScore),
          _ScoreRow(label: 'Speaking', value: player.speakingScore),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.assignment_outlined, size: 16),
              label: const Text('Assign Lesson'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EspTheme.neonBlue,
                side: const BorderSide(color: EspTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: EspTheme.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 7,
                backgroundColor: EspTheme.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation<Color>(EspTheme.neonBlue),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: EspTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
