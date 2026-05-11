import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../screens/login_screen.dart';
import '../../services/api_service.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/components/loading_state.dart';
import '../../ui/theme/app_spacing.dart';
import '../models/media_training_models.dart';
import '../services/media_training_service.dart';

class MediaTrainingLessonScreen extends StatefulWidget {
  const MediaTrainingLessonScreen({
    super.key,
    required this.lessonId,
    this.authToken,
  });

  final String lessonId;
  final String? authToken;

  @override
  State<MediaTrainingLessonScreen> createState() =>
      _MediaTrainingLessonScreenState();
}

class _MediaTrainingLessonScreenState extends State<MediaTrainingLessonScreen> {
  final MediaTrainingService _service = MediaTrainingService();
  final ApiService _apiService = ApiService();

  MediaTrainingLesson? _lesson;
  bool _isLoading = true;
  bool _isCreatingSession = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lesson = await _service.getLesson(
        widget.lessonId,
        authToken: widget.authToken,
      );
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startSession() async {
    final lesson = _lesson;
    if (lesson == null) return;

    setState(() => _isCreatingSession = true);
    try {
      final session = await _service.createSession(
        lesson.id,
        authToken: widget.authToken,
      );
      if (!mounted) return;
      final shouldRefresh = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MediaTrainingSessionScreen(
            lesson: lesson,
            session: session,
            authToken: widget.authToken,
          ),
        ),
      );
      if (shouldRefresh == true) {
        await _loadLesson();
      }
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingSession = false);
      }
    }
  }

  bool _isUnauthorizedError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('unauthorized') ||
        text.contains('authentication required') ||
        text.contains('invalid token');
  }

  Future<void> _redirectToLogin() async {
    await _apiService.removeToken();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expiree. Merci de vous reconnecter.'),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Media Training')),
        body: const LoadingState(message: 'Chargement de la lecon...'),
      );
    }

    if (_error != null || _lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Media Training')),
        body: EmptyState(
          title: 'Lecon indisponible',
          message: _error ?? 'Impossible de charger cette lecon.',
          action: ElevatedButton.icon(
            onPressed: _loadLesson,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reessayer'),
          ),
        ),
      );
    }

    final lesson = _lesson!;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: RefreshIndicator(
        onRefresh: _loadLesson,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            _LessonHero(lesson: lesson),
            const SizedBox(height: AppSpacing.s16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objectifs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  ...lesson.objectives.map(
                    (objective) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(child: Text(objective)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blocs pedagogiques',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  for (final block in lesson.lessonBlocks) ...[
                    _LessonBlockCard(block: block),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maitrise',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  ...lesson.masteryRules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(child: Text(rule.label)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (lesson.nextSimulationCase != null) ...[
                    Text(
                      lesson.nextSimulationCase!.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(lesson.nextSimulationCase!.context),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Angle journaliste: ${lesson.nextSimulationCase!.journalistAngle}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Pression ${lesson.nextSimulationCase!.pressureLevel}/5',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  ...lesson.simulationPreview.map(
                    (question) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.question,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (question.expectedElements.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.s8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: question.expectedElements
                                    .map((item) => _InlineTag(label: item))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.s16),
        child: ElevatedButton.icon(
          onPressed:
              (!lesson.unlocked || _isCreatingSession) ? null : _startSession,
          icon: _isCreatingSession
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_circle_fill_rounded),
          label: Text(
            !lesson.unlocked
                ? (lesson.lockedReason ?? 'Lecon verrouillee')
                : 'Demarrer la simulation',
          ),
        ),
      ),
    );
  }
}

class _LessonHero extends StatelessWidget {
  const _LessonHero({required this.lesson});

  final MediaTrainingLesson lesson;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.82),
            scheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroBadge(label: lesson.level),
              _HeroBadge(label: lesson.format),
              _HeroBadge(label: '${lesson.estimatedMinutes} min'),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            lesson.summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            lesson.focus,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lesson.skillTags
                .map((tag) => _HeroBadge(label: tag.replaceAll('_', ' ')))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LessonBlockCard extends StatelessWidget {
  const _LessonBlockCard({required this.block});

  final MediaLessonBlock block;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(block.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(block.summary),
          const SizedBox(height: AppSpacing.s12),
          ...block.keyTakeaways.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Coach prompt: ${block.coachPrompt}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class MediaTrainingSessionScreen extends StatefulWidget {
  const MediaTrainingSessionScreen({
    super.key,
    required this.lesson,
    required this.session,
    this.authToken,
  });

  final MediaTrainingLesson lesson;
  final MediaTrainingSession session;
  final String? authToken;

  @override
  State<MediaTrainingSessionScreen> createState() =>
      _MediaTrainingSessionScreenState();
}

class _MediaTrainingSessionScreenState
    extends State<MediaTrainingSessionScreen> {
  final MediaTrainingService _service = MediaTrainingService();
  final ApiService _apiService = ApiService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  late final List<TextEditingController> _controllers;

  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _isOpeningNextSession = false;
  bool _isRetryingSession = false;
  bool _isVoiceActionInProgress = false;
  int? _recordingQuestionIndex;
  int? _transcribingQuestionIndex;
  MediaTrainingEvaluationResult? _result;

  @override
  void initState() {
    super.initState();
    _controllers = widget.session.simulationQuestions
        .map((_) => TextEditingController())
        .toList();
  }

  @override
  void dispose() {
    if (_recordingQuestionIndex != null) {
      unawaited(_audioRecorder.stop().catchError((_) => null));
    }
    unawaited(_audioRecorder.dispose());
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _answeredCount => _controllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  String _buildTranscript() {
    final segments = <String>[];
    for (var index = 0;
        index < widget.session.simulationQuestions.length;
        index++) {
      final answer = _controllers[index].text.trim();
      if (answer.isEmpty) continue;
      segments.add(answer);
    }
    return segments.join('\n');
  }

  Future<void> _goToQuestion(int index) async {
    if (index < 0 || index >= widget.session.simulationQuestions.length) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  Future<void> _toggleVoiceAnswer() async {
    if (_isVoiceActionInProgress) return;

    setState(() => _isVoiceActionInProgress = true);
    try {
      if (_recordingQuestionIndex == _currentQuestionIndex) {
        await _stopVoiceAnswer();
        return;
      }
      if (_recordingQuestionIndex != null) {
        await _stopVoiceAnswer();
        return;
      }
      await _startVoiceAnswer();
    } finally {
      if (mounted) {
        setState(() => _isVoiceActionInProgress = false);
      }
    }
  }

  Future<void> _startVoiceAnswer() async {
    if (_isSubmitting || _transcribingQuestionIndex != null) return;

    try {
      if (_recordingQuestionIndex != null) {
        await _audioRecorder.stop();
      }

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission micro refusee.')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final question =
          widget.session.simulationQuestions[_currentQuestionIndex];
      final path =
          '${tempDir.path}/media_training_${widget.session.id}_${question.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() => _recordingQuestionIndex = _currentQuestionIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() => _recordingQuestionIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible: $e')),
      );
    }
  }

  Future<void> _stopVoiceAnswer() async {
    final questionIndex = _recordingQuestionIndex;
    if (questionIndex == null) return;

    setState(() {
      _recordingQuestionIndex = null;
      _transcribingQuestionIndex = questionIndex;
    });

    try {
      final audioPath = await _audioRecorder.stop();
      if (audioPath == null || audioPath.isEmpty) {
        throw MediaTrainingException('Aucun audio enregistre');
      }

      final transcript = await _service.transcribeAudio(
        audioPath,
        authToken: widget.authToken,
      );
      final transcribedText = transcript.text.trim();
      if (transcribedText.isEmpty) {
        throw MediaTrainingException('Transcription vide');
      }

      final controller = _controllers[questionIndex];
      final current = controller.text.trim();
      controller.text =
          current.isEmpty ? transcribedText : '$current\n$transcribedText';
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );

      if (!mounted) return;
      setState(() => _transcribingQuestionIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reponse vocale transcrite.')),
      );
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      setState(() => _transcribingQuestionIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transcription impossible: $e')),
      );
    }
  }

  Future<void> _submit() async {
    final answers = <Map<String, String>>[];
    for (var index = 0;
        index < widget.session.simulationQuestions.length;
        index++) {
      final question = widget.session.simulationQuestions[index];
      answers.add({
        'questionId': question.id,
        'answer': _controllers[index].text.trim(),
      });
    }

    final transcript = _buildTranscript();
    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute au moins une reponse avant l analyse.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _service.evaluateSession(
        widget.session.id,
        answers,
        transcript: transcript,
        authToken: widget.authToken,
      );
      if (!mounted) return;
      setState(() => _result = result);
      final hasNextLesson = result.unlockedNextLessonId != null &&
          result.unlockedNextLessonId!.isNotEmpty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasNextLesson
                ? 'Session analysee. Suite disponible.'
                : 'Session analysee.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _retryCurrentLesson() async {
    setState(() => _isRetryingSession = true);
    try {
      final newSession = await _service.createSession(
        widget.lesson.id,
        authToken: widget.authToken,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => MediaTrainingSessionScreen(
            lesson: widget.lesson,
            session: newSession,
            authToken: widget.authToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de relancer la simulation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRetryingSession = false);
      }
    }
  }

  Future<void> _copyImprovedAnswer() async {
    final text = _result?.evaluation.improvedAnswerExample;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiee')),
    );
  }

  Future<void> _openNextSession() async {
    final result = _result;
    final nextLessonId = result?.unlockedNextLessonId;
    if (nextLessonId == null || nextLessonId.isEmpty) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isOpeningNextSession = true);
    try {
      final nextLesson = await _service.getLesson(
        nextLessonId,
        authToken: widget.authToken,
      );
      final nextSession = await _service.createSession(
        nextLessonId,
        authToken: widget.authToken,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<bool, bool>(
        MaterialPageRoute(
          builder: (_) => MediaTrainingSessionScreen(
            lesson: nextLesson,
            session: nextSession,
            authToken: widget.authToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d ouvrir la session suivante: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningNextSession = false);
      }
    }
  }

  MediaSimulationQuestion? _findQuestion(String questionId) {
    for (final question in widget.session.simulationQuestions) {
      if (question.id == questionId || question.questionId == questionId) {
        return question;
      }
    }
    return null;
  }

  String _completionLabel(String status) {
    switch (status) {
      case 'MASTERED':
        return 'Maitrisee';
      case 'COMPLETED':
        return 'Validee';
      case 'NOT_COMPLETED':
        return 'A renforcer';
      default:
        return status;
    }
  }

  String _riskFlagLabel(String riskFlag) {
    switch (riskFlag) {
      case 'REFEREE_BLAME':
        return 'Blame arbitrage';
      case 'EMOTIONAL_ESCALATION':
        return 'Escalade emotionnelle';
      case 'NO_FORWARD_PLAN':
        return 'Pas de plan pour la suite';
      case 'LOW_OWNERSHIP_SIGNAL':
        return 'Responsabilite trop faible';
      case 'MEDIA_DISCIPLINE_RISK':
        return 'Risque discipline media';
      case 'TACTICAL_DISCLOSURE_RISK':
        return 'Risque fuite tactique';
      default:
        return riskFlag.replaceAll('_', ' ').toLowerCase();
    }
  }

  bool _isUnauthorizedError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('unauthorized') ||
        text.contains('authentication required') ||
        text.contains('invalid token');
  }

  Future<void> _redirectToLogin() async {
    await _apiService.removeToken();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expiree. Merci de vous reconnecter.'),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _result != null;
    final hasQuestions = widget.session.simulationQuestions.isNotEmpty;
    final hasUnlockedNextLesson = hasResult &&
        _result!.unlockedNextLessonId != null &&
        _result!.unlockedNextLessonId!.isNotEmpty;
    final isLastQuestion = hasQuestions &&
        _currentQuestionIndex == widget.session.simulationQuestions.length - 1;
    final isVoiceBusy = _isVoiceActionInProgress ||
        _recordingQuestionIndex != null ||
        _transcribingQuestionIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasResult ? 'Resultat' : 'Conference media'),
      ),
      body: hasResult
          ? _buildResult(context)
          : hasQuestions
              ? _buildQuestionnaire(context)
              : const EmptyState(
                  title: 'Conference indisponible',
                  message: 'Cette session ne contient aucune question.',
                ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.s16),
        child: !hasResult
            ? hasQuestions
                ? Row(
                    children: [
                      if (_currentQuestionIndex > 0) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (_isSubmitting ||
                                    isVoiceBusy ||
                                    widget.session.simulationQuestions.isEmpty)
                                ? null
                                : () =>
                                    _goToQuestion(_currentQuestionIndex - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Precedente'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isSubmitting ||
                                  isVoiceBusy ||
                                  widget.session.simulationQuestions.isEmpty)
                              ? null
                              : isLastQuestion
                                  ? _submit
                                  : () =>
                                      _goToQuestion(_currentQuestionIndex + 1),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  isLastQuestion
                                      ? Icons.auto_awesome_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                          label: Text(
                            isLastQuestion
                                ? 'Analyser la conference'
                                : 'Suivante',
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: hasUnlockedNextLesson
                        ? ElevatedButton.icon(
                            onPressed:
                                _isOpeningNextSession ? null : _openNextSession,
                            icon: _isOpeningNextSession
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.skip_next_rounded),
                            label: Text(
                              _isOpeningNextSession
                                  ? 'Ouverture...'
                                  : 'Continuer',
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed:
                                _isRetryingSession ? null : _retryCurrentLesson,
                            icon: _isRetryingSession
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded),
                            label: Text(
                              _isRetryingSession ? 'Relance...' : 'Refaire',
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Terminer'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionnaire(BuildContext context) {
    final question = widget.session.simulationQuestions[_currentQuestionIndex];
    final isLastQuestion =
        _currentQuestionIndex == widget.session.simulationQuestions.length - 1;
    final isRecording = _recordingQuestionIndex == _currentQuestionIndex;
    final isTranscribing = _transcribingQuestionIndex == _currentQuestionIndex;
    final isVoiceTransition =
        _isVoiceActionInProgress && !isRecording && !isTranscribing;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.82),
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResultBadge(label: widget.lesson.format),
                  _ResultBadge(label: widget.lesson.level),
                  _ResultBadge(
                    label:
                        '${_currentQuestionIndex + 1}/${widget.session.simulationQuestions.length}',
                  ),
                  _ResultBadge(
                    label:
                        'Repondu $_answeredCount/${widget.session.simulationQuestions.length}',
                  ),
                  _ResultBadge(
                      label: isRecording ? 'Micro actif' : 'Voix + texte'),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              const Text(
                'Conference de presse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Lis la question, reponds au micro ou au clavier, puis ajuste le texte avant l analyse finale.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              LinearProgressIndicator(
                value: widget.session.simulationQuestions.isEmpty
                    ? 0
                    : (_currentQuestionIndex + 1) /
                        widget.session.simulationQuestions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (widget.session.simulationCase != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.simulationCase!.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(widget.session.simulationCase!.context),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Question chaude: ${widget.session.simulationCase!.journalistAngle}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'Pression ${widget.session.simulationCase!.pressureLevel}/5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consignes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s12),
              ...widget.session.instructions.map(
                (instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(child: Text(instruction)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.article_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journaliste ${_currentQuestionIndex + 1}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          isLastQuestion
                              ? 'Derniere question'
                              : 'Question suivante dans la conference',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (question.difficulty > 0)
                    _InlineTag(label: 'Difficulte ${question.difficulty}/5'),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _controllers[_currentQuestionIndex].clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Effacer'),
                  ),
                ],
              ),
              if (question.expectedElements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    'Coach cues',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle:
                      const Text('Repere discret pour garder le bon message'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: question.expectedElements
                            .map((item) => _InlineTag(label: item))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ta reponse',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                isRecording
                    ? 'Enregistrement en cours...'
                    : isTranscribing
                        ? 'Transcription de la reponse...'
                        : isVoiceTransition
                            ? 'Preparation du micro...'
                            : 'Speech to text ou saisie clavier.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s12),
              SizedBox(
                width: double.infinity,
                child: isRecording
                    ? FilledButton.icon(
                        onPressed: _isVoiceActionInProgress
                            ? null
                            : _toggleVoiceAnswer,
                        icon: _isVoiceActionInProgress
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.stop_circle_rounded),
                        label: Text(
                          _isVoiceActionInProgress
                              ? 'Arret...'
                              : 'Stopper et transcrire',
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: (_isSubmitting ||
                                isTranscribing ||
                                _isVoiceActionInProgress)
                            ? null
                            : _toggleVoiceAnswer,
                        icon: isTranscribing || isVoiceTransition
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.mic_rounded),
                        label: Text(
                          isVoiceTransition
                              ? 'Preparation...'
                              : isTranscribing
                                  ? 'Transcription...'
                                  : 'Speech to text',
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.s12),
              TextField(
                controller: _controllers[_currentQuestionIndex],
                minLines: 8,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Ecris ta reponse ici.',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.s12),
              for (var index = 0;
                  index < widget.session.simulationQuestions.length;
                  index++) ...[
                _ConferenceAnswerSummaryCard(
                  index: index,
                  isActive: index == _currentQuestionIndex,
                  question: widget.session.simulationQuestions[index],
                  answer: _controllers[index].text.trim(),
                  onTap: () => _goToQuestion(index),
                ),
                if (index != widget.session.simulationQuestions.length - 1)
                  const SizedBox(height: AppSpacing.s8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final result = _result!;
    final evaluation = result.evaluation;
    final hasUnlockedNextLesson = result.unlockedNextLessonId != null &&
        result.unlockedNextLessonId!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${evaluation.overallScore.toStringAsFixed(0)}/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                evaluation.coachSummary,
                style: const TextStyle(color: Colors.white, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResultBadge(label: evaluation.readinessLevel),
                  _ResultBadge(
                    label: _completionLabel(evaluation.lessonCompletionStatus),
                  ),
                  _ResultBadge(
                    label:
                        'Progress ${result.progressPercent.toStringAsFixed(0)}%',
                  ),
                  _ResultBadge(
                    label:
                        '${result.completedObjectives}/${result.totalObjectives} objectifs',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasUnlockedNextLesson
                    ? Icons.rocket_launch_rounded
                    : Icons.track_changes_rounded,
                color: hasUnlockedNextLesson
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUnlockedNextLesson
                          ? 'Suite debloquee'
                          : 'Session enregistree',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      hasUnlockedNextLesson
                          ? 'Tu peux passer a la prochaine lecon.'
                          : 'L avancement est enregistre.',
                    ),
                    if (!hasUnlockedNextLesson &&
                        evaluation.rectifications.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Priorite: ${evaluation.rectifications.first}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (evaluation.riskFlags.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: evaluation.riskFlags
                      .map(
                        (flag) => _RiskChip(label: _riskFlagLabel(flag)),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scores',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.s12),
              _ResultMetricRow(label: 'Global', value: evaluation.overallScore),
              _ResultMetricRow(label: 'Q&A', value: evaluation.qaScore),
              _ResultMetricRow(
                label: 'Gestion du cas',
                value: evaluation.caseHandlingScore,
              ),
              _ResultMetricRow(
                label: 'Qualite des reponses',
                value: evaluation.answerQualityScore,
              ),
              const Divider(height: 24),
              _ResultMetricRow(
                label: 'Clarte',
                value: evaluation.metrics.clarity,
              ),
              _ResultMetricRow(
                label: 'Controle du message',
                value: evaluation.metrics.messageControl,
              ),
              _ResultMetricRow(
                label: 'Controle emotionnel',
                value: evaluation.metrics.emotionalControl,
              ),
              _ResultMetricRow(
                label: 'Discipline',
                value: evaluation.metrics.discipline,
              ),
              _ResultMetricRow(
                label: 'Structure',
                value: evaluation.metrics.structure,
              ),
              _ResultMetricRow(
                label: 'Gestion pression',
                value: evaluation.metrics.pressureManagement,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (result.answers.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Par question',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s16),
                for (final answer in result.answers) ...[
                  _AnswerFeedbackCard(
                    answer: answer,
                    question: _findQuestion(answer.questionId),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        _FeedbackListCard(
          title: 'Points forts',
          icon: Icons.thumb_up_alt_outlined,
          items: evaluation.strengths,
        ),
        const SizedBox(height: AppSpacing.s16),
        _FeedbackListCard(
          title: 'Rectifications',
          icon: Icons.tips_and_updates_outlined,
          items: evaluation.rectifications,
        ),
        const SizedBox(height: AppSpacing.s16),
        _FeedbackListCard(
          title: 'Axes a renforcer',
          icon: Icons.auto_fix_high_outlined,
          items: evaluation.improvements,
        ),
        const SizedBox(height: AppSpacing.s16),
        if (evaluation.improvedAnswerExample != null &&
            evaluation.improvedAnswerExample!.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meilleure reponse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(evaluation.improvedAnswerExample!),
                const SizedBox(height: AppSpacing.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _copyImprovedAnswer,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copier'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        if (evaluation.suggestedDrills.isNotEmpty) ...[
          _FeedbackListCard(
            title: 'Drills recommandes',
            icon: Icons.sports_gymnastics_outlined,
            items: evaluation.suggestedDrills,
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A travailler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(evaluation.nextSessionFocus),
              if (result.unlockedNextLessonTitle != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(
                  'Suite: ${result.unlockedNextLessonTitle}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ConferenceAnswerSummaryCard extends StatelessWidget {
  const _ConferenceAnswerSummaryCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.onTap,
    this.isActive = false,
  });

  final int index;
  final MediaSimulationQuestion question;
  final String answer;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: answer.isNotEmpty
                    ? Colors.green.withValues(alpha: 0.14)
                    : theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: answer.isNotEmpty
                      ? Colors.green
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    question.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    answer.isEmpty ? 'Aucune reponse pour le moment.' : answer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Icon(
              isActive
                  ? Icons.radio_button_checked_rounded
                  : Icons.chevron_right_rounded,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerFeedbackCard extends StatelessWidget {
  const _AnswerFeedbackCard({
    required this.answer,
    this.question,
  });

  final MediaTrainingScoredAnswer answer;
  final MediaSimulationQuestion? question;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, answer.score);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question?.question ?? 'Question ${answer.questionId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      answer.answer.isEmpty
                          ? 'Aucune reponse saisie.'
                          : answer.answer,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    answer.score.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            answer.feedback,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FeedbackListCard extends StatelessWidget {
  const _FeedbackListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.s8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (items.isEmpty)
            Text(
              'Aucun element disponible.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('- '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultMetricRow extends StatelessWidget {
  const _ResultMetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, value);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _scoreColor(BuildContext context, double? score) {
  final value = score ?? 0;
  if (value >= 80) return Colors.green;
  if (value >= 65) return Colors.orange;
  if (value > 0) return Colors.redAccent;
  return Theme.of(context).colorScheme.primary;
}
