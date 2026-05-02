import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_management/models/user_management_models.dart';
import '../models/learning_models.dart';
import '../services/learning_api_service.dart';

class LearningHomeScreen extends StatefulWidget {
  const LearningHomeScreen({super.key, required this.session});

  final SessionModel session;

  @override
  State<LearningHomeScreen> createState() => _LearningHomeScreenState();
}

class _LearningHomeScreenState extends State<LearningHomeScreen> {
  late final LearningApiService _api;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _api = LearningApiService(token: widget.session.token);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CoursesListScreen(api: _api, session: widget.session),
      ProgressDashboardScreen(api: _api, session: widget.session),
      SportsEnglishChatScreen(api: _api, session: widget.session),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: LearningColors.ink,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                child: _LearningSegmentedNav(
                  selectedIndex: _section,
                  onChanged: (index) => setState(() => _section = index),
                ),
              ),
              Expanded(child: screens[_section]),
            ],
          ),
        ),
      ),
    );
  }
}

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({
    super.key,
    required this.api,
    required this.session,
  });

  final LearningApiService api;
  final SessionModel session;

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  late Future<List<LearningCourse>> _future;
  String _filter = 'ALL';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = widget.api.getCourses(playerId: widget.session.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningCourse>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LearningLoading();
        }
        if (snapshot.hasError) {
          return _LearningError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {
              _future = widget.api.getCourses(playerId: widget.session.userId);
            }),
          );
        }

        final courses = (snapshot.data ?? []).where((course) {
          final matchesFilter = _filter == 'ALL' || course.type == _filter;
          final query = _search.trim().toLowerCase();
          final matchesSearch =
              query.isEmpty ||
              course.title.toLowerCase().contains(query) ||
              course.description.toLowerCase().contains(query);
          return matchesFilter && matchesSearch;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = widget.api.getCourses(playerId: widget.session.userId);
            });
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: LearningColors.text,
                  ),
                  children: const [
                    TextSpan(text: 'Tactical '),
                    TextSpan(
                      text: 'Intelligence',
                      style: TextStyle(color: LearningColors.cyan),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Master the language of the pitch with ODIN professional training modules.',
                style: GoogleFonts.manrope(
                  color: LearningColors.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              _SearchBox(onChanged: (value) => setState(() => _search = value)),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'ALL COURSES',
                      selected: _filter == 'ALL',
                      onTap: () => setState(() => _filter = 'ALL'),
                    ),
                    _FilterChip(
                      label: 'COMMUNICATION',
                      selected: _filter == 'COMMUNICATION',
                      onTap: () => setState(() => _filter = 'COMMUNICATION'),
                    ),
                    _FilterChip(
                      label: 'MEDICAL',
                      selected: _filter == 'MEDICAL',
                      onTap: () => setState(() => _filter = 'MEDICAL'),
                    ),
                    _FilterChip(
                      label: 'TACTICAL',
                      selected: _filter == 'TACTICAL',
                      onTap: () => setState(() => _filter = 'TACTICAL'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final course in courses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _CourseCard(
                    course: course,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailsScreen(
                            api: widget.api,
                            session: widget.session,
                            course: course,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    required this.api,
    required this.session,
    required this.course,
  });

  final LearningApiService api;
  final SessionModel session;
  final LearningCourse course;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late Future<CourseLessonsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getLessons(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: LearningColors.ink,
        body: SafeArea(
          child: FutureBuilder<CourseLessonsResponse>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LearningLoading();
              }
              if (snapshot.hasError) {
                return _LearningError(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {
                    _future = widget.api.getLessons(widget.course.id);
                  }),
                );
              }

              final response = snapshot.data!;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: LearningColors.ink,
                    foregroundColor: LearningColors.text,
                    expandedHeight: 220,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _CourseImage(
                        url: response.course.thumbnailUrl,
                        overlay: true,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            _TinyPill(response.course.level),
                            const SizedBox(width: 10),
                            Text(
                              '${response.lessons.length} MODULES',
                              style: GoogleFonts.spaceGrotesk(
                                color: LearningColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          response.course.title,
                          style: GoogleFonts.spaceGrotesk(
                            color: LearningColors.text,
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          response.course.description,
                          style: GoogleFonts.manrope(
                            color: LearningColors.body,
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        for (final lesson in response.lessons)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _LessonTile(
                              lesson: lesson,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LessonViewerScreen(
                                      api: widget.api,
                                      session: widget.session,
                                      lesson: lesson,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class LessonViewerScreen extends StatefulWidget {
  const LessonViewerScreen({
    super.key,
    required this.api,
    required this.session,
    required this.lesson,
  });

  final LearningApiService api;
  final SessionModel session;
  final LearningLesson lesson;

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  bool _saving = false;

  Future<void> _markComplete() async {
    setState(() => _saving = true);
    try {
      await widget.api.updateProgress(
        playerId: widget.session.userId,
        courseId: widget.lesson.courseId,
        lessonId: widget.lesson.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lesson progress updated')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: LearningColors.ink,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _VideoHero(lesson: widget.lesson),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TinyPill(widget.lesson.moduleLabel.toUpperCase()),
                        const SizedBox(width: 10),
                        Text(
                          '${widget.lesson.durationMinutes} MINS',
                          style: GoogleFonts.spaceGrotesk(
                            color: LearningColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.lesson.title,
                      style: GoogleFonts.spaceGrotesk(
                        color: LearningColors.text,
                        fontSize: 38,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.lesson.content,
                      style: GoogleFonts.manrope(
                        color: LearningColors.body,
                        fontSize: 17,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'FOCUS SCORE',
                            value: '${widget.lesson.focusScore}%',
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _DifficultyCard(
                            level: widget.lesson.focusScore,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _SectionHeader(
                      title: 'LIVE TRANSCRIPT',
                      action: 'VIEW ALL',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    for (final segment in widget.lesson.transcript)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _TranscriptCard(segment: segment),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LearningButton(
                            label: _saving ? 'UPDATING...' : 'MARK AS COMPLETE',
                            onPressed: _saving ? null : _markComplete,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: 'PRACTICE EXERCISES',
                            icon: Icons.extension_outlined,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExercisePlayerScreen(
                                    api: widget.api,
                                    lesson: widget.lesson,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: 'START QUIZ',
                            icon: Icons.quiz_outlined,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(
                                    api: widget.api,
                                    session: widget.session,
                                    lesson: widget.lesson,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExercisePlayerScreen extends StatefulWidget {
  const ExercisePlayerScreen({
    super.key,
    required this.api,
    required this.lesson,
  });

  final LearningApiService api;
  final LearningLesson lesson;

  @override
  State<ExercisePlayerScreen> createState() => _ExercisePlayerScreenState();
}

class _ExercisePlayerScreenState extends State<ExercisePlayerScreen> {
  late Future<List<LearningExercise>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getLessonExercises(widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: LearningColors.ink,
        appBar: AppBar(
          backgroundColor: LearningColors.ink,
          foregroundColor: LearningColors.text,
          title: Text(
            'Exercises',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
          ),
        ),
        body: FutureBuilder<List<LearningExercise>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LearningLoading();
            }
            if (snapshot.hasError) {
              return _LearningError(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {
                  _future = widget.api.getLessonExercises(widget.lesson.id);
                }),
              );
            }
            final exercises = snapshot.data ?? [];
            if (exercises.isEmpty) {
              return const _EmptyLearningState(
                message: 'No exercises for this lesson yet.',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Text(
                  widget.lesson.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: LearningColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PDF-based practice activities. Matching tasks use drag and drop; vocabulary tasks use fill-in-the-blanks.',
                  style: GoogleFonts.manrope(
                    color: LearningColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                for (final exercise in exercises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child:
                        exercise.isMatching &&
                            exercise.matching != null &&
                            exercise.matching!.left.isNotEmpty &&
                            exercise.matching!.right.isNotEmpty
                        ? _MatchingExerciseCard(
                            exercise: exercise,
                            api: widget.api,
                          )
                        : exercise.isFillBlank
                        ? _FillBlankExerciseCard(
                            exercise: exercise,
                            api: widget.api,
                          )
                        : _GenericExerciseCard(
                            exercise: exercise,
                            api: widget.api,
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MatchingExerciseCard extends StatefulWidget {
  const _MatchingExerciseCard({required this.exercise, required this.api});

  final LearningExercise exercise;
  final LearningApiService api;

  @override
  State<_MatchingExerciseCard> createState() => _MatchingExerciseCardState();
}

class _MatchingExerciseCardState extends State<_MatchingExerciseCard> {
  final Map<String, MatchingItem> _answers = {};
  int? _score;
  bool _checked = false;

  void _check() {
    final matching = widget.exercise.matching!;
    if (matching.answerMap.isEmpty) {
      setState(() {
        _checked = true;
        _score = null;
      });
      return;
    }
    var correct = 0;
    for (final entry in _answers.entries) {
      if (matching.answerMap[entry.key] == entry.value.id) {
        correct += 1;
      }
    }
    setState(() {
      _checked = true;
      _score = correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matching = widget.exercise.matching!;
    final usedRightIds = _answers.values.map((item) => item.id).toSet();
    final available = matching.right
        .where((item) => !usedRightIds.contains(item.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LearningColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.cyanDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExerciseHeader(exercise: widget.exercise),
          const SizedBox(height: 12),
          Text(
            _compactPrompt(widget.exercise.prompt),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: LearningColors.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.exercise.sourcePageImage != null)
            _ExerciseImage(
              url: widget.api.resolveAssetUrl(widget.exercise.sourcePageImage),
            ),
          const SizedBox(height: 16),
          Text(
            'DROP ZONE',
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.cyan,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          for (final left in matching.left)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DragTarget<MatchingItem>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    _answers[left.id] = details.data;
                    _checked = false;
                  });
                },
                builder: (context, candidate, rejected) {
                  final answer = _answers[left.id];
                  final isHover = candidate.isNotEmpty;
                  final isCorrect =
                      _checked &&
                      matching.answerMap.isNotEmpty &&
                      matching.answerMap[left.id] == answer?.id;
                  final isWrong =
                      _checked &&
                      matching.answerMap.isNotEmpty &&
                      answer != null &&
                      !isCorrect;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isHover
                          ? LearningColors.cyan.withValues(alpha: 0.16)
                          : LearningColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCorrect
                            ? LearningColors.cyan
                            : isWrong
                            ? LearningColors.danger
                            : LearningColors.line,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (left.imageUrl != null &&
                            left.imageUrl!.isNotEmpty) ...[
                          _ExerciseThumb(
                            url: widget.api.resolveAssetUrl(left.imageUrl),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${left.id}. ${left.label}',
                                style: GoogleFonts.manrope(
                                  color: LearningColors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: InkWell(
                                onTap: answer == null
                                    ? null
                                    : () => setState(() {
                                        _answers.remove(left.id);
                                        _checked = false;
                                      }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: answer == null
                                        ? LearningColors.inkDeep
                                        : LearningColors.cyan.withValues(
                                            alpha: 0.18,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    answer?.label ?? 'Drop here',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      color: answer == null
                                          ? LearningColors.muted
                                          : LearningColors.cyan,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'ANSWER CARDS',
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.body,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final right in available)
                Draggable<MatchingItem>(
                  data: right,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _AnswerCard(item: right, dragging: true),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _AnswerCard(item: right),
                  ),
                  child: _AnswerCard(item: right),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (_checked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _score == null
                    ? 'Submitted for teacher or AI review.'
                    : 'Score: $_score/${matching.left.length} correct',
                style: GoogleFonts.spaceGrotesk(
                  color: _score == null || _score == matching.left.length
                      ? LearningColors.cyan
                      : LearningColors.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          _LearningButton(
            label: matching.answerMap.isEmpty
                ? 'SAVE MATCHING'
                : 'CHECK MATCHES',
            onPressed: _answers.length == matching.left.length ? _check : null,
          ),
        ],
      ),
    );
  }
}

class _FillBlankExerciseCard extends StatefulWidget {
  const _FillBlankExerciseCard({required this.exercise, required this.api});

  final LearningExercise exercise;
  final LearningApiService api;

  @override
  State<_FillBlankExerciseCard> createState() => _FillBlankExerciseCardState();
}

class _FillBlankExerciseCardState extends State<_FillBlankExerciseCard> {
  late final Map<String, TextEditingController> _controllers;
  int? _score;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final item in widget.exercise.fillBlanks)
        item.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _allFilled => widget.exercise.fillBlanks.every((item) {
    final controller = _controllers[item.id];
    return controller != null && controller.text.trim().isNotEmpty;
  });

  void _check() {
    var correct = 0;
    for (final item in widget.exercise.fillBlanks) {
      if (_isCorrect(item)) correct += 1;
    }
    setState(() {
      _score = correct;
      _checked = true;
    });
  }

  bool _isCorrect(FillBlankItem item) {
    final input = _normalizeFillAnswer(_controllers[item.id]?.text ?? '');
    return item.answers.any((answer) => _normalizeFillAnswer(answer) == input);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.fillBlanks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LearningColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.cyanDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExerciseHeader(exercise: widget.exercise),
          const SizedBox(height: 12),
          Text(
            widget.exercise.prompt,
            style: GoogleFonts.manrope(
              color: LearningColors.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FillBlankPromptCard(
                item: item,
                api: widget.api,
                controller: _controllers[item.id]!,
                checked: _checked,
                correct: _checked ? _isCorrect(item) : null,
                onChanged: () {
                  if (!_checked) return;
                  setState(() {
                    _checked = false;
                    _score = null;
                  });
                },
              ),
            ),
          if (_checked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Score: $_score/${items.length} correct',
                style: GoogleFonts.spaceGrotesk(
                  color: _score == items.length
                      ? LearningColors.cyan
                      : LearningColors.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          _LearningButton(
            label: 'CHECK BLANKS',
            onPressed: _allFilled ? _check : null,
          ),
        ],
      ),
    );
  }
}

class _FillBlankPromptCard extends StatelessWidget {
  const _FillBlankPromptCard({
    required this.item,
    required this.api,
    required this.controller,
    required this.checked,
    required this.correct,
    required this.onChanged,
  });

  final FillBlankItem item;
  final LearningApiService api;
  final TextEditingController controller;
  final bool checked;
  final bool? correct;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = correct == null
        ? LearningColors.line
        : correct == true
        ? LearningColors.cyan
        : LearningColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
            _ExerciseThumb(url: api.resolveAssetUrl(item.imageUrl)),
            const SizedBox(height: 12),
          ],
          Text(
            item.sentence,
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (item.hint != null && item.hint!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Hint: ${item.hint}',
              style: GoogleFonts.manrope(
                color: LearningColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            style: GoogleFonts.manrope(
              color: LearningColors.text,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Type the missing word or phrase',
              hintStyle: GoogleFonts.manrope(color: LearningColors.muted),
              filled: true,
              fillColor: LearningColors.inkDeep,
              suffixIcon: checked
                  ? Icon(
                      correct == true
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: correct == true
                          ? LearningColors.cyan
                          : LearningColors.danger,
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LearningColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LearningColors.cyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericExerciseCard extends StatelessWidget {
  const _GenericExerciseCard({required this.exercise, required this.api});

  final LearningExercise exercise;
  final LearningApiService api;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExerciseHeader(exercise: exercise),
          const SizedBox(height: 12),
          Text(
            exercise.prompt,
            style: GoogleFonts.manrope(
              color: LearningColors.body,
              height: 1.45,
            ),
          ),
          if (exercise.sourcePageImage != null) ...[
            const SizedBox(height: 14),
            _ExerciseImage(url: api.resolveAssetUrl(exercise.sourcePageImage)),
          ],
          if (exercise.questions.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final question in exercise.questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  question,
                  style: GoogleFonts.manrope(
                    color: LearningColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
          if (exercise.type.contains('speaking')) ...[
            const SizedBox(height: 14),
            const _TinyPill('SPEAKING / AI REVIEW'),
          ],
        ],
      ),
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.exercise});

  final LearningExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TinyPill(exercise.type.replaceAll('_', ' ').toUpperCase()),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${exercise.title}${exercise.page == null ? '' : ' - PAGE ${exercise.page}'}',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.item, this.dragging = false});

  final MatchingItem item;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dragging ? LearningColors.cyan : LearningColors.inkDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LearningColors.cyanDim),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Text(
        '${item.id}. ${item.label}',
        style: GoogleFonts.manrope(
          color: dragging ? LearningColors.ink : LearningColors.text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: LearningColors.inkDeep,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          ),
        ),
      ),
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  const _ExerciseImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _ImageFallback(),
        ),
      ),
    );
  }
}

String _compactPrompt(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _normalizeFillAnswer(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.api,
    required this.session,
    required this.lesson,
  });

  final LearningApiService api;
  final SessionModel session;
  final LearningLesson lesson;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<LearningQuizQuestion>> _future;
  final Map<String, String> _answers = {};
  int _index = 0;
  bool _submitting = false;
  QuizResult? _result;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getQuiz(widget.lesson.id);
  }

  Future<void> _submit(List<LearningQuizQuestion> questions) async {
    setState(() => _submitting = true);
    try {
      final result = await widget.api.submitQuiz(
        playerId: widget.session.userId,
        lessonId: widget.lesson.id,
        answers: _answers,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: LearningColors.ink,
        body: SafeArea(
          child: FutureBuilder<List<LearningQuizQuestion>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LearningLoading();
              }
              if (snapshot.hasError) {
                return _LearningError(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(
                    () => _future = widget.api.getQuiz(widget.lesson.id),
                  ),
                );
              }
              final questions = snapshot.data ?? [];
              if (questions.isEmpty) {
                return const _EmptyLearningState(
                  message: 'No quiz questions for this lesson yet.',
                );
              }
              if (_result != null) {
                return _QuizResultView(result: _result!);
              }

              final question = questions[_index];
              final selected = _answers[question.id];
              final progress = (_index + 1) / questions.length;

              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          (_index + 1).toString().padLeft(2, '0'),
                          style: GoogleFonts.spaceGrotesk(
                            color: LearningColors.blueSoft,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' / ${questions.length.toString().padLeft(2, '0')}',
                          style: GoogleFonts.spaceGrotesk(
                            color: LearningColors.muted,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.lesson.injuryCommunication
                              ? 'SPORTS MEDICINE'
                              : 'SPORT ENGLISH',
                          style: GoogleFonts.spaceGrotesk(
                            color: LearningColors.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: LearningColors.card,
                        valueColor: const AlwaysStoppedAnimation(
                          LearningColors.cyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 54),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: LearningColors.panel,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: LearningColors.cyanDim,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'ACTIVE INQUIRY',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: LearningColors.body,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 34),
                            Text(
                              question.question,
                              style: GoogleFonts.spaceGrotesk(
                                color: LearningColors.text,
                                fontSize: 28,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Expanded(
                              child: ListView(
                                children: [
                                  for (final option in question.options)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _QuizOption(
                                        label: option,
                                        selected: selected == option,
                                        onTap: () => setState(() {
                                          _answers[question.id] = option;
                                        }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _LearningButton(
                      label: _index == questions.length - 1
                          ? (_submitting ? 'SUBMITTING...' : 'SUBMIT QUIZ')
                          : 'NEXT QUESTION',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: selected == null || _submitting
                          ? null
                          : () {
                              if (_index == questions.length - 1) {
                                _submit(questions);
                              } else {
                                setState(() => _index += 1);
                              }
                            },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({
    super.key,
    required this.api,
    required this.session,
  });

  final LearningApiService api;
  final SessionModel session;

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  late Future<LearningDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getDashboard(widget.session.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningDashboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LearningLoading();
        }
        if (snapshot.hasError) {
          return _LearningError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {
              _future = widget.api.getDashboard(widget.session.userId);
            }),
          );
        }
        final dashboard = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(
              () => _future = widget.api.getDashboard(widget.session.userId),
            );
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
            children: [
              Text(
                dashboard.playerName,
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.text,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TinyPill(dashboard.position.toUpperCase()),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.workspace_premium,
                    color: LearningColors.muted,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ODIN LEVEL 4',
                    style: GoogleFonts.spaceGrotesk(
                      color: LearningColors.muted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _CommunicationScoreCard(score: dashboard.communicationScore),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.school_rounded,
                      value: dashboard.completedCourses.toString(),
                      label: 'COURSES COMPLETED',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      value: '${dashboard.activeCourses}',
                      label: 'ACTIVE COURSES',
                      active: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              _SectionHeader(
                title: 'TACTICAL WEAK POINTS',
                action: 'VIEW DEEP DIVE',
                onTap: () {},
              ),
              const SizedBox(height: 14),
              for (final weakPoint in dashboard.weakPoints)
                _WeakPointCard(weakPoint: weakPoint),
              const SizedBox(height: 28),
              Text(
                'LATEST MILESTONES',
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              if (dashboard.certificates.isEmpty)
                const _MilestoneTile(
                  title: 'Start your first certificate',
                  subtitle: 'Complete a module to unlock a badge',
                  earned: false,
                )
              else
                for (final certificate in dashboard.certificates)
                  _MilestoneTile(
                    title: certificate,
                    subtitle: 'EARNED IN ODIN LEARNING',
                    earned: true,
                  ),
              const SizedBox(height: 16),
              Text(
                'RECOMMENDED NEXT',
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 14),
              for (final course in dashboard.recommendations.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecommendationTile(course: course),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SportsEnglishChatScreen extends StatefulWidget {
  const SportsEnglishChatScreen({
    super.key,
    required this.api,
    required this.session,
  });

  final LearningApiService api;
  final SessionModel session;

  @override
  State<SportsEnglishChatScreen> createState() =>
      _SportsEnglishChatScreenState();
}

class _SportsEnglishChatScreenState extends State<SportsEnglishChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatBubbleData> _messages = [
    _ChatBubbleData(
      role: 'assistant',
      text:
          'Choose a mode and send me your answer. I will coach your sports English like a media trainer.',
    ),
  ];
  String _mode = 'interview';
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatBubbleData(role: 'user', text: text));
      _controller.clear();
      _sending = true;
    });

    try {
      final history = _messages
          .take(_messages.length - 1)
          .map((item) => {'role': item.role, 'content': item.text})
          .toList();
      final reply = await widget.api.sendChatMessage(
        playerId: widget.session.userId,
        message: text,
        mode: _mode,
        history: history,
      );
      if (!mounted) return;
      setState(
        () => _messages.add(_ChatBubbleData(role: 'assistant', text: reply)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleData(
            role: 'assistant',
            text: 'I could not reach the coach service. Try again in a moment.',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Sports English Coach',
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'INTERVIEW',
                      selected: _mode == 'interview',
                      onTap: () => setState(() => _mode = 'interview'),
                    ),
                    _FilterChip(
                      label: 'PRESS ROOM',
                      selected: _mode == 'press_conference',
                      onTap: () => setState(() => _mode = 'press_conference'),
                    ),
                    _FilterChip(
                      label: 'MEDICAL',
                      selected: _mode == 'medical',
                      onTap: () => setState(() => _mode = 'medical'),
                    ),
                    _FilterChip(
                      label: 'PRACTICE',
                      selected: _mode == 'practice',
                      onTap: () => setState(() => _mode = 'practice'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
            itemCount: _messages.length,
            itemBuilder: (context, index) =>
                _ChatBubble(data: _messages[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: LearningColors.inkDeep,
            border: Border(top: BorderSide(color: LearningColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  style: GoogleFonts.manrope(color: LearningColors.text),
                  decoration: InputDecoration(
                    hintText: _mode == 'medical'
                        ? 'Describe pain, movement, and intensity...'
                        : 'Type your answer in English...',
                    hintStyle: const TextStyle(color: LearningColors.muted),
                    filled: true,
                    fillColor: LearningColors.panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                style: IconButton.styleFrom(
                  backgroundColor: LearningColors.cyan,
                  foregroundColor: LearningColors.ink,
                  fixedSize: const Size(54, 54),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LearningColors {
  static const ink = Color(0xFF061523);
  static const inkDeep = Color(0xFF03101C);
  static const panel = Color(0xFF1D2C3E);
  static const card = Color(0xFF101F31);
  static const cardSoft = Color(0xFF13283A);
  static const line = Color(0xFF20384D);
  static const cyan = Color(0xFF63E3D9);
  static const cyanDim = Color(0xFF3E9C9A);
  static const blue = Color(0xFF4B8DFF);
  static const blueSoft = Color(0xFFA9C4FF);
  static const text = Color(0xFFE9F1FF);
  static const body = Color(0xFFC1CBDB);
  static const muted = Color(0xFF77869A);
  static const danger = Color(0xFFFFA098);
}

class _LearningSegmentedNav extends StatelessWidget {
  const _LearningSegmentedNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, 'Courses'),
      (Icons.insights_rounded, 'Progress'),
      (Icons.smart_toy_outlined, 'Coach'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearningColors.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedIndex == i
                        ? LearningColors.cyan
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 18,
                        color: selectedIndex == i
                            ? LearningColors.ink
                            : LearningColors.body,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        items[i].$2,
                        style: GoogleFonts.spaceGrotesk(
                          color: selectedIndex == i
                              ? LearningColors.ink
                              : LearningColors.body,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
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

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.manrope(color: LearningColors.text),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: LearningColors.muted,
        ),
        hintText: 'Search courses...',
        hintStyle: GoogleFonts.manrope(color: LearningColors.muted),
        filled: true,
        fillColor: LearningColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? LearningColors.cyan : LearningColors.panel,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: selected ? LearningColors.ink : LearningColors.body,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final LearningCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = course.progressPercent;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LearningColors.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    child: _CourseImage(
                      url: course.thumbnailUrl,
                      overlay: true,
                    ),
                  ),
                ),
                Positioned(right: 18, top: 18, child: _TinyPill(course.level)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: LearningColors.text,
                      fontSize: 23,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: LearningColors.muted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: LearningColors.cyan,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${course.lessonCount} Modules',
                        style: GoogleFonts.manrope(
                          color: LearningColors.body,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'PROGRESS $progress%',
                        style: GoogleFonts.spaceGrotesk(
                          color: LearningColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 7,
                      backgroundColor: LearningColors.inkDeep,
                      valueColor: const AlwaysStoppedAnimation(
                        LearningColors.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LearningButton(
                    label: progress > 0
                        ? 'CONTINUE TRAINING'
                        : 'START TRAINING',
                    onPressed: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.url, this.overlay = false});

  final String? url;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null && url!.isNotEmpty)
          Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _ImageFallback(),
          )
        else
          const _ImageFallback(),
        if (overlay)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  LearningColors.card.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LearningColors.panel, LearningColors.inkDeep],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.sports_soccer_rounded,
          color: LearningColors.cyan,
          size: 46,
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: LearningColors.cyan.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: LearningColors.cyan,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.onTap});

  final LearningLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: LearningColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: lesson.injuryCommunication
                ? LearningColors.danger
                : LearningColors.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: LearningColors.panel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                lesson.injuryCommunication
                    ? Icons.medical_services_outlined
                    : Icons.play_arrow_rounded,
                color: lesson.injuryCommunication
                    ? LearningColors.danger
                    : LearningColors.cyan,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: LearningColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.moduleLabel} - ${lesson.durationMinutes} mins',
                    style: GoogleFonts.manrope(
                      color: LearningColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: LearningColors.cyan),
          ],
        ),
      ),
    );
  }
}

class _VideoHero extends StatelessWidget {
  const _VideoHero({required this.lesson});

  final LearningLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 290,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF27394C), LearningColors.inkDeep],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.person_rounded,
              color: LearningColors.panel,
              size: 160,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  LearningColors.ink.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 12,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: LearningColors.text,
            ),
          ),
        ),
        Positioned(
          top: 24,
          right: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: LearningColors.cyan.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.circle,
                  color: LearningColors.cyanDim,
                  size: 10,
                ),
                const SizedBox(width: 9),
                Text(
                  'SESSION ACTIVE',
                  style: GoogleFonts.spaceGrotesk(
                    color: LearningColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: LearningColors.cyan.withValues(alpha: 0.88),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: LearningColors.ink,
                size: 46,
              ),
            ),
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 24,
          child: Row(
            children: [
              Text(
                '12:45',
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.58,
                    minHeight: 5,
                    backgroundColor: LearningColors.panel,
                    valueColor: AlwaysStoppedAnimation(LearningColors.cyan),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '24:00',
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: LearningColors.cyanDim, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.cyan,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: LearningColors.cyan, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final dots = level >= 88
        ? 4
        : level >= 75
        ? 3
        : 2;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIFFICULTY',
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(
                    Icons.circle,
                    size: 12,
                    color: i < dots
                        ? LearningColors.cyan
                        : LearningColors.panel,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: LearningColors.cyan,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.segment});

  final TranscriptSegment segment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: segment.current ? LearningColors.panel : LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: segment.current
            ? const Border(
                left: BorderSide(color: LearningColors.cyan, width: 4),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            segment.current ? '${segment.time} - CURRENT' : segment.time,
            style: GoogleFonts.spaceGrotesk(
              color: segment.current
                  ? LearningColors.cyan
                  : LearningColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"${segment.text}"',
            style: GoogleFonts.manrope(
              color: segment.current
                  ? LearningColors.text
                  : LearningColors.muted,
              fontSize: 17,
              height: 1.35,
              fontWeight: segment.current ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningButton extends StatelessWidget {
  const _LearningButton({required this.label, this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LearningColors.blue,
          foregroundColor: LearningColors.ink,
          disabledBackgroundColor: LearningColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                fontSize: 15,
              ),
            ),
            if (icon != null) ...[const SizedBox(width: 14), Icon(icon)],
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        style: OutlinedButton.styleFrom(
          foregroundColor: LearningColors.cyan,
          side: const BorderSide(color: LearningColors.cyanDim),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        label: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: LearningColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? LearningColors.cyan : LearningColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? LearningColors.cyan : LearningColors.muted,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  color: LearningColors.text,
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: LearningColors.panel,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.passed
                    ? Icons.workspace_premium_rounded
                    : Icons.replay_rounded,
                color: result.passed
                    ? LearningColors.cyan
                    : LearningColors.danger,
                size: 64,
              ),
              const SizedBox(height: 18),
              Text(
                '${result.scorePercentage}%',
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.text,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.passed ? 'MODULE PASSED' : 'KEEP TRAINING',
                style: GoogleFonts.spaceGrotesk(
                  color: result.passed
                      ? LearningColors.cyan
                      : LearningColors.danger,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${result.correctAnswers}/${result.totalQuestions} correct answers',
                style: GoogleFonts.manrope(color: LearningColors.body),
              ),
              const SizedBox(height: 26),
              _LearningButton(
                label: 'BACK TO LESSON',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunicationScoreCard extends StatelessWidget {
  const _CommunicationScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final bars = [38, 52, 47, 66, 61, score].map((item) => item / 100).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LearningColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENGLISH COMMUNICATION',
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.body,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toString(),
                style: GoogleFonts.spaceGrotesk(
                  color: LearningColors.cyan,
                  fontSize: 58,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '.2/100',
                  style: GoogleFonts.spaceGrotesk(
                    color: LearningColors.muted,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+4.8%',
                    style: GoogleFonts.spaceGrotesk(
                      color: LearningColors.cyan,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'VS LAST MONTH',
                    style: GoogleFonts.manrope(
                      color: LearningColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: FractionallySizedBox(
                        heightFactor: bar,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              LearningColors.cyanDim,
                              LearningColors.cyan,
                              bar,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: active ? LearningColors.danger : LearningColors.blueSoft,
            size: 28,
          ),
          const SizedBox(height: 26),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: LearningColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: active ? 0.8 : 0.75,
              minHeight: 5,
              backgroundColor: LearningColors.panel,
              valueColor: AlwaysStoppedAnimation(
                active ? LearningColors.cyan : LearningColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakPointCard extends StatelessWidget {
  const _WeakPointCard({required this.weakPoint});

  final Map<String, dynamic> weakPoint;

  @override
  Widget build(BuildContext context) {
    final tags = weakPoint['tags'] is List
        ? (weakPoint['tags'] as List).map((item) => item.toString()).toList()
        : const <String>[];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LearningColors.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: LearningColors.danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: LearningColors.danger,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (weakPoint['title'] ?? 'Training Focus').toString(),
                            style: GoogleFonts.spaceGrotesk(
                              color: LearningColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          (weakPoint['status'] ?? 'Recommended').toString(),
                          style: GoogleFonts.spaceGrotesk(
                            color: LearningColors.danger,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Focus: ${weakPoint['focus'] ?? ''}',
                      style: GoogleFonts.manrope(color: LearningColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tag in tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: LearningColors.card,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.manrope(color: LearningColors.text),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _LearningButton(label: 'START RECOVERY TRAINING'),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.title,
    required this.subtitle,
    required this.earned,
  });

  final String title;
  final String subtitle;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: earned
                ? LearningColors.cyan.withValues(alpha: 0.22)
                : LearningColors.panel,
            child: Icon(
              earned
                  ? Icons.workspace_premium_rounded
                  : Icons.card_giftcard_rounded,
              color: earned ? LearningColors.cyan : LearningColors.muted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: earned ? LearningColors.text : LearningColors.muted,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: LearningColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.course});

  final LearningCourse course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_circle_right_outlined,
            color: LearningColors.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: LearningColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (course.reasons.isNotEmpty)
                  Text(
                    course.reasons.first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: LearningColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          _TinyPill(course.level),
        ],
      ),
    );
  }
}

class _ChatBubbleData {
  _ChatBubbleData({required this.role, required this.text});

  final String role;
  final String text;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.data});

  final _ChatBubbleData data;

  @override
  Widget build(BuildContext context) {
    final isUser = data.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? LearningColors.blue : LearningColors.panel,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          data.text,
          style: GoogleFonts.manrope(
            color: isUser ? LearningColors.ink : LearningColors.text,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _LearningLoading extends StatelessWidget {
  const _LearningLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: LearningColors.cyan),
    );
  }
}

class _LearningError extends StatelessWidget {
  const _LearningError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: LearningColors.danger,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: LearningColors.body),
            ),
            const SizedBox(height: 18),
            _SecondaryButton(
              label: 'RETRY',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLearningState extends StatelessWidget {
  const _EmptyLearningState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.manrope(color: LearningColors.body),
      ),
    );
  }
}
