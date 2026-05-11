import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/navigation/menu_config.dart';
import '../../ui/shell/app_shell.dart';
import '../models/tactical_animation.dart';
import '../services/tactics_service.dart';

class TacticalAnimationScreen extends StatefulWidget {
  const TacticalAnimationScreen({super.key});

  @override
  State<TacticalAnimationScreen> createState() =>
      _TacticalAnimationScreenState();
}

class _TacticalAnimationScreenState extends State<TacticalAnimationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final TextEditingController _promptController = TextEditingController(
    text:
        'Pressing haut en 4-3-3, le 9 presse les centraux et les ailiers ferment les lateraux.',
  );
  final TextEditingController _customFormationController =
      TextEditingController();
  final List<_MovementDraft> _movementDrafts = [];
  final List<_PassDraft> _passDrafts = [];

  TacticalAnimationOptions? _options = _fallbackOptions();
  TacticalAnimation? _animation;
  bool _loadingOptions = false;
  bool _generating = false;
  bool _editMode = false;
  String? _error;

  String _formation = '4-3-3';
  String _tacticalChoice = 'high_press';
  String _side = 'right';
  double _intensity = 0.72;
  double _durationSeconds = 5.2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5200));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
      _generate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _promptController.dispose();
    _customFormationController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await TacticsService.getAnimationOptions();
      if (!mounted) return;
      setState(() {
        _options = options;
        _loadingOptions = false;
        if (options.formations.isNotEmpty) {
          _formation = options.formations.first;
        }
        if (options.tacticalChoices.isNotEmpty) {
          _tacticalChoice = options.tacticalChoices
              .firstWhere(
                (item) => item.id == 'high_press',
                orElse: () => options.tacticalChoices.first,
              )
              .id;
        }
      });
      await _generate();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOptions = false;
        _options ??= _fallbackOptions();
        _error = e.toString();
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final formation = _customFormationController.text.trim().isNotEmpty
          ? _customFormationController.text.trim()
          : _formation;
      final animation = await TacticsService.generateAnimation(
        TacticalAnimationRequest(
          prompt: _promptController.text.trim(),
          formation: formation,
          tacticalChoice: _tacticalChoice,
          scenarioType: 'open_play',
          opponentShape: 'none',
          defenderCount: 0,
          deliveryType: 'open_play',
          sceneIntent: 'free_simulation',
          opponentReaction: 'none',
          riskLevel: 0,
          side: _side,
          intensity: _intensity,
          durationMs: (_durationSeconds * 1000).round(),
          movements: _movementDrafts
              .where(
                  (draft) => draft.player.isNotEmpty && draft.move.isNotEmpty)
              .map((draft) => TacticalMovementRequest(
                  player: draft.player, move: draft.move))
              .toList(),
          passSequence: _passDrafts
              .where((draft) => draft.from.isNotEmpty && draft.to.isNotEmpty)
              .map((draft) =>
                  TacticalPassRequest(from: draft.from, to: draft.to))
              .toList(),
        ),
      );

      if (!mounted) return;
      _controller
        ..duration = Duration(milliseconds: animation.durationMs)
        ..reset();
      setState(() {
        _animation = animation;
        _generating = false;
        _editMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.toString();
      });
    }
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
      setState(() {});
      return;
    }
    if (_controller.value >= 1) {
      _controller.reset();
    }
    _controller.forward();
    setState(() {});
  }

  void _resetAnimation() {
    _controller.reset();
    setState(() {});
  }

  void _toggleEditMode() {
    _controller.stop();
    setState(() => _editMode = !_editMode);
  }

  void _updatePlayerTarget(String playerId, TacticalPoint point) {
    final animation = _animation;
    if (animation == null) return;
    final clamped = point.clamp();
    setState(() {
      _animation = animation.copyWith(
        players: animation.players
            .map(
              (player) => player.id == playerId
                  ? player.copyWith(
                      to: clamped,
                      movement: 'manuel',
                      instruction:
                          '${player.label}: trajectoire ajustee manuellement par le coach.',
                    )
                  : player,
            )
            .toList(),
        notes: _withManualNote(animation.notes),
      );
    });
  }

  void _updateBallPoint(int index, TacticalPoint point) {
    final animation = _animation;
    if (animation == null || index < 0 || index >= animation.ball.length) {
      return;
    }
    final clamped = point.clamp();
    final updatedBall = [...animation.ball];
    updatedBall[index] = updatedBall[index].copyWith(point: clamped);
    setState(() {
      _animation = animation.copyWith(
        ball: updatedBall,
        notes: _withManualNote(animation.notes),
      );
    });
  }

  List<String> _withManualNote(List<String> notes) {
    const note =
        'Mode coach: les trajectoires modifiees a la main sont conservees dans la simulation locale.';
    if (notes.contains(note)) return notes;
    return [...notes, note];
  }

  void _addMovement() {
    final options = _options;
    if (options == null ||
        options.positions.isEmpty ||
        options.movements.isEmpty) {
      return;
    }
    setState(() {
      _movementDrafts.add(
        _MovementDraft(
          player: options.positions.first,
          move: options.movements.first.id,
        ),
      );
    });
  }

  void _addPass() {
    final options = _options;
    if (options == null || options.positions.length < 2) {
      return;
    }
    setState(() {
      _passDrafts.add(
          _PassDraft(from: options.positions.first, to: options.positions[1]));
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    final canGoBack = Navigator.of(context).canPop() || shell != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tactical Animator'),
        leading: canGoBack
            ? IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).maybePop();
                  } else if (shell != null) {
                    shell.navigate(
                        MenuConfig.defaultRouteForRole(shell.session.role));
                  }
                },
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Regenerer',
            onPressed: _generating ? null : _generate,
            icon: const Icon(Icons.auto_fix_high_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    final options = _options;
    if (options == null) {
      return _ErrorPanel(
          message: _error ?? 'Options indisponibles', onRetry: _loadOptions);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final controls = _ControlsPanel(
          options: options,
          promptController: _promptController,
          customFormationController: _customFormationController,
          formation: _formation,
          tacticalChoice: _tacticalChoice,
          side: _side,
          intensity: _intensity,
          durationSeconds: _durationSeconds,
          movementDrafts: _movementDrafts,
          passDrafts: _passDrafts,
          generating: _generating,
          onFormation: (value) => setState(() => _formation = value),
          onTacticalChoice: (value) => setState(() => _tacticalChoice = value),
          onSide: (value) => setState(() => _side = value),
          onIntensity: (value) => setState(() => _intensity = value),
          onDuration: (value) => setState(() => _durationSeconds = value),
          onAddMovement: _addMovement,
          onRemoveMovement: (index) {
            setState(() => _movementDrafts.removeAt(index));
          },
          onAddPass: _addPass,
          onRemovePass: (index) {
            setState(() => _passDrafts.removeAt(index));
          },
          onGenerate: _generate,
        );

        final preview = _PreviewPanel(
          animation: _animation,
          controller: _controller,
          error: _error,
          generating: _generating,
          isPlaying: _controller.isAnimating,
          editMode: _editMode,
          onPlay: _togglePlay,
          onReset: _resetAnimation,
          onToggleEdit: _toggleEditMode,
          onPlayerTargetChanged: _updatePlayerTarget,
          onBallPointChanged: _updateBallPoint,
          onRetry: _generate,
        );

        if (wide) {
          return Row(
            children: [
              SizedBox(
                width: 390,
                child: SingleChildScrollView(child: controls),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: SingleChildScrollView(child: preview)),
            ],
          );
        }

        return ListView(
          children: [
            controls,
            const Divider(height: 1),
            preview,
          ],
        );
      },
    );
  }

  static TacticalAnimationOptions _fallbackOptions() {
    return TacticalAnimationOptions(
      formations: const [
        '4-3-3',
        '4-4-2',
        '4-2-3-1',
        '4-1-4-1',
        '3-5-2',
        '3-4-3',
        '3-2-4-1',
        '5-3-2',
        '5-4-1',
        '2-3-5',
      ],
      tacticalChoices: const [
        TacticalOption(
            id: 'high_press', label: 'Pressing haut', phase: 'defensive'),
        TacticalOption(
            id: 'mid_block', label: 'Bloc median compact', phase: 'defensive'),
        TacticalOption(id: 'low_block', label: 'Bloc bas', phase: 'defensive'),
        TacticalOption(
            id: 'counter_attack',
            label: 'Contre-attaque rapide',
            phase: 'transition'),
        TacticalOption(
            id: 'possession_build_up',
            label: 'Sortie de balle patiente',
            phase: 'offensive'),
        TacticalOption(
            id: 'wide_overload',
            label: 'Surcharge couloir',
            phase: 'offensive'),
        TacticalOption(
            id: 'switch_play',
            label: 'Renversement de jeu',
            phase: 'offensive'),
        TacticalOption(
            id: 'rest_defense', label: 'Rest-defense 3+2', phase: 'security'),
      ],
      movements: const [
        TacticalOption(id: 'hold', label: 'Garder position'),
        TacticalOption(id: 'press', label: 'Presser'),
        TacticalOption(id: 'drop', label: 'Reculer'),
        TacticalOption(id: 'overlap', label: 'Debordement exterieur'),
        TacticalOption(id: 'underlap', label: 'Appel interieur'),
        TacticalOption(id: 'invert', label: "Rentrer dans l'axe"),
        TacticalOption(id: 'run_in_behind', label: 'Appel profondeur'),
        TacticalOption(id: 'between_lines', label: 'Entre les lignes'),
        TacticalOption(id: 'false_nine', label: 'Decrochage faux 9'),
        TacticalOption(id: 'cover', label: 'Couverture'),
        TacticalOption(id: 'attack_box', label: 'Attaquer la surface'),
      ],
      sides: const [
        TacticalOption(id: 'left', label: 'Gauche'),
        TacticalOption(id: 'right', label: 'Droite'),
      ],
      scenarioTypes: const [
        TacticalOption(id: 'open_play', label: 'Jeu ouvert'),
        TacticalOption(id: 'corner', label: 'Corner offensif'),
        TacticalOption(id: 'free_kick_direct', label: 'Coup franc direct'),
        TacticalOption(id: 'free_kick_indirect', label: 'Coup franc combine'),
        TacticalOption(id: 'penalty', label: 'Penalty'),
        TacticalOption(id: 'throw_in', label: 'Touche offensive'),
        TacticalOption(
            id: 'build_up_under_press', label: 'Sortie sous pressing'),
        TacticalOption(id: 'low_block_unlock', label: 'Debloquer bloc bas'),
      ],
      opponentShapes: const [
        TacticalOption(id: 'none', label: 'Sans adversaire'),
        TacticalOption(id: 'line4', label: 'Ligne de 4'),
        TacticalOption(id: 'zone', label: 'Defense de zone'),
        TacticalOption(id: 'individual', label: 'Marquage individuel'),
        TacticalOption(id: 'high_press', label: 'Pressing haut adverse'),
        TacticalOption(id: 'low_block', label: 'Bloc bas adverse'),
        TacticalOption(id: 'wall', label: 'Mur coup franc'),
      ],
      positions: const [
        'GK',
        'LB',
        'CB',
        'RB',
        'LWB',
        'RWB',
        'DM',
        'CM',
        'AM',
        'LW',
        'RW',
        'ST',
      ],
    );
  }
}

class TacticalMatchScenariosScreen extends StatefulWidget {
  const TacticalMatchScenariosScreen({super.key});

  @override
  State<TacticalMatchScenariosScreen> createState() =>
      _TacticalMatchScenariosScreenState();
}

class _TacticalMatchScenariosScreenState
    extends State<TacticalMatchScenariosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  TacticalAnimation? _animation;
  bool _generating = false;
  bool _editMode = false;
  String? _error;

  String _scene = 'corner';
  String _side = 'right';
  String _delivery = 'outswinger';
  String _marking = 'zone';
  String _intent = 'second_post';
  String _opponentReaction = 'protect_six';
  int _defenders = 7;
  double _intensity = 0.74;
  double _risk = 0.42;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6));
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateScene());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateScene() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final animation = await TacticsService.generateAnimation(
        TacticalAnimationRequest(
          prompt: _buildScenePrompt(),
          formation: _scene == 'free_kick' ? '4-2-3-1' : '4-3-3',
          tacticalChoice:
              _scene == 'build_up' ? 'possession_build_up' : 'set_piece_attack',
          scenarioType: _scenarioType,
          opponentShape: _opponentShape,
          defenderCount: _effectiveDefenders,
          deliveryType: _delivery,
          sceneIntent: _intent,
          opponentReaction: _opponentReaction,
          riskLevel: _risk,
          side: _side,
          intensity: (_intensity + (_risk * 0.18)).clamp(0, 1).toDouble(),
          durationMs: 6200,
          movements: _sceneMovements,
          passSequence: const [],
        ),
      );

      if (!mounted) return;
      _controller
        ..duration = Duration(milliseconds: animation.durationMs)
        ..reset();
      setState(() {
        _animation = animation;
        _generating = false;
        _editMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.toString();
      });
    }
  }

  String get _scenarioType {
    return switch (_scene) {
      'corner' => 'corner',
      'free_kick' =>
        _delivery == 'direct' ? 'free_kick_direct' : 'free_kick_indirect',
      'penalty' => 'penalty',
      'throw_in' => 'throw_in',
      _ => 'corner',
    };
  }

  String get _opponentShape {
    if (_scene == 'penalty') return 'individual';
    if (_scene == 'free_kick' && _delivery == 'direct') return 'wall';
    if (_scene == 'throw_in') return _marking == 'zone' ? 'line4' : _marking;
    return _marking;
  }

  int get _effectiveDefenders {
    if (_scene == 'penalty') return 1;
    if (_scene == 'free_kick' && _delivery == 'direct') return 5;
    return _defenders;
  }

  List<TacticalMovementRequest> get _sceneMovements {
    if (_scene == 'penalty') {
      return const [
        TacticalMovementRequest(player: 'ST', move: 'attack_box'),
        TacticalMovementRequest(player: 'AM', move: 'second_ball'),
      ];
    }
    if (_scene == 'free_kick') {
      if (_intent == 'screen_keeper') {
        return const [
          TacticalMovementRequest(player: 'ST', move: 'attack_box'),
          TacticalMovementRequest(player: 'CB', move: 'attack_box'),
          TacticalMovementRequest(player: 'AM', move: 'second_ball'),
          TacticalMovementRequest(player: 'DM', move: 'cover'),
        ];
      }
      return const [
        TacticalMovementRequest(player: 'AM', move: 'hold'),
        TacticalMovementRequest(player: 'ST', move: 'attack_box'),
        TacticalMovementRequest(player: 'CB', move: 'attack_box'),
        TacticalMovementRequest(player: 'CM', move: 'second_ball'),
      ];
    }
    if (_scene == 'throw_in') {
      if (_intent == 'escape_press') {
        return const [
          TacticalMovementRequest(player: 'CM', move: 'support'),
          TacticalMovementRequest(player: 'DM', move: 'support'),
          TacticalMovementRequest(player: 'LW', move: 'between_lines'),
          TacticalMovementRequest(player: 'CB', move: 'cover'),
        ];
      }
      return const [
        TacticalMovementRequest(player: 'LW', move: 'run_in_behind'),
        TacticalMovementRequest(player: 'CM', move: 'support'),
        TacticalMovementRequest(player: 'ST', move: 'attack_box'),
        TacticalMovementRequest(player: 'DM', move: 'cover'),
      ];
    }
    if (_intent == 'first_post') {
      return const [
        TacticalMovementRequest(player: 'ST', move: 'attack_box'),
        TacticalMovementRequest(player: 'LW', move: 'attack_box'),
        TacticalMovementRequest(player: 'AM', move: 'second_ball'),
        TacticalMovementRequest(player: 'DM', move: 'cover'),
      ];
    }
    if (_intent == 'short_combo') {
      return const [
        TacticalMovementRequest(player: 'RW', move: 'support'),
        TacticalMovementRequest(player: 'AM', move: 'between_lines'),
        TacticalMovementRequest(player: 'ST', move: 'attack_box'),
        TacticalMovementRequest(player: 'DM', move: 'cover'),
      ];
    }
    return const [
      TacticalMovementRequest(player: 'ST', move: 'attack_box'),
      TacticalMovementRequest(player: 'CB', move: 'attack_box'),
      TacticalMovementRequest(player: 'AM', move: 'second_ball'),
      TacticalMovementRequest(player: 'DM', move: 'cover'),
    ];
  }

  String _buildScenePrompt() {
    final sideLabel = _side == 'left' ? 'gauche' : 'droite';
    final intentLabel = _intentText(_intent);
    final opponentLabel = _opponentText(_opponentReaction);
    final riskLabel = _risk > 0.68
        ? 'risque eleve'
        : _risk > 0.38
            ? 'risque controle'
            : 'risque bas';
    return switch (_scene) {
      'free_kick' =>
        'Coup franc $sideLabel, $_delivery. Intention coach: $intentLabel. Reaction adverse attendue: $opponentLabel. $riskLabel. Mur ou ligne adverse, appels dans la surface et seconde balle.',
      'penalty' =>
        'Penalty. Intention coach: $intentLabel. Gardien adverse: $opponentLabel. $riskLabel. Routine de frappe vers le cote $sideLabel et joueurs au rebond.',
      'throw_in' =>
        'Touche offensive cote $sideLabel, combinaison $_delivery. Intention coach: $intentLabel. Reaction adverse: $opponentLabel. $riskLabel. Defense adverse $_marking, sortie dans le couloir.',
      _ =>
        'Corner offensif $sideLabel, type $_delivery. Intention coach: $intentLabel. Reaction adverse: $opponentLabel. $riskLabel. Defense adverse $_marking, $_defenders defenseurs. Ecran, attaque zone cible et securite contre-attaque.',
    };
  }

  String _intentText(String value) {
    return switch (value) {
      'first_post' => 'attaquer le premier poteau',
      'second_post' => 'isoler le second poteau',
      'short_combo' => 'attirer puis jouer court',
      'direct_shot' => 'tir direct cadre',
      'screen_keeper' => 'masquer le gardien',
      'rebound' => 'attaquer le rebond',
      'escape_press' => 'sortir de la pression',
      'long_throw' => 'chercher la surface',
      _ => 'creer une finition claire',
    };
  }

  String _opponentText(String value) {
    return switch (value) {
      'protect_six' => 'protege les six metres',
      'man_mark' => 'suit les appels en individuel',
      'jump_wall' => 'mur qui saute et ferme l axe',
      'keeper_wait' => 'gardien qui attend la frappe',
      'press_touchline' => 'pression sur la ligne',
      _ => 'bloc compact proche du ballon',
    };
  }

  void _selectScene(String value) {
    setState(() {
      _scene = value;
      if (value == 'corner') {
        _delivery = 'outswinger';
        _marking = 'zone';
        _intent = 'second_post';
        _opponentReaction = 'protect_six';
        _defenders = 7;
        _risk = 0.42;
      } else if (value == 'free_kick') {
        _delivery = 'direct';
        _marking = 'wall';
        _intent = 'direct_shot';
        _opponentReaction = 'jump_wall';
        _defenders = 5;
        _risk = 0.48;
      } else if (value == 'penalty') {
        _delivery = 'right_foot';
        _marking = 'individual';
        _intent = 'direct_shot';
        _opponentReaction = 'keeper_wait';
        _defenders = 1;
        _risk = 0.34;
      } else if (value == 'throw_in') {
        _delivery = 'short';
        _marking = 'line4';
        _intent = 'escape_press';
        _opponentReaction = 'press_touchline';
        _defenders = 4;
        _risk = 0.55;
      }
    });
  }

  void _togglePlay() {
    if (_controller.isAnimating) {
      _controller.stop();
      setState(() {});
      return;
    }
    if (_controller.value >= 1) {
      _controller.reset();
    }
    _controller.forward();
    setState(() {});
  }

  void _updatePlayerTarget(String playerId, TacticalPoint point) {
    final animation = _animation;
    if (animation == null) return;
    final clamped = point.clamp();
    setState(() {
      _animation = animation.copyWith(
        players: animation.players
            .map(
              (player) => player.id == playerId
                  ? player.copyWith(
                      to: clamped,
                      movement: 'manuel',
                      instruction:
                          '${player.label}: position ajustee pour cette scene.',
                    )
                  : player,
            )
            .toList(),
      );
    });
  }

  void _updateBallPoint(int index, TacticalPoint point) {
    final animation = _animation;
    if (animation == null || index < 0 || index >= animation.ball.length) {
      return;
    }
    final updatedBall = [...animation.ball];
    updatedBall[index] = updatedBall[index].copyWith(point: point.clamp());
    setState(() => _animation = animation.copyWith(ball: updatedBall));
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    final canGoBack = Navigator.of(context).canPop() || shell != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Scenarios'),
        leading: canGoBack
            ? IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).maybePop();
                  } else if (shell != null) {
                    shell.navigate(
                        MenuConfig.defaultRouteForRole(shell.session.role));
                  }
                },
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Regenerer',
            onPressed: _generating ? null : _generateScene,
            icon: const Icon(Icons.auto_fix_high_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final controls = _MatchSceneControls(
            scene: _scene,
            side: _side,
            delivery: _delivery,
            marking: _marking,
            intent: _intent,
            opponentReaction: _opponentReaction,
            defenders: _defenders,
            intensity: _intensity,
            risk: _risk,
            generating: _generating,
            onScene: _selectScene,
            onSide: (value) => setState(() => _side = value),
            onDelivery: (value) => setState(() => _delivery = value),
            onMarking: (value) => setState(() => _marking = value),
            onIntent: (value) => setState(() => _intent = value),
            onOpponentReaction: (value) =>
                setState(() => _opponentReaction = value),
            onDefenders: (value) => setState(() => _defenders = value),
            onIntensity: (value) => setState(() => _intensity = value),
            onRisk: (value) => setState(() => _risk = value),
            onGenerate: _generateScene,
          );
          final preview = _PreviewPanel(
            animation: _animation,
            controller: _controller,
            error: _error,
            generating: _generating,
            isPlaying: _controller.isAnimating,
            editMode: _editMode,
            onPlay: _togglePlay,
            onReset: () {
              _controller.reset();
              setState(() {});
            },
            onToggleEdit: () {
              _controller.stop();
              setState(() => _editMode = !_editMode);
            },
            onPlayerTargetChanged: _updatePlayerTarget,
            onBallPointChanged: _updateBallPoint,
            onRetry: _generateScene,
          );

          if (wide) {
            return Row(
              children: [
                SizedBox(
                    width: 410, child: SingleChildScrollView(child: controls)),
                const VerticalDivider(width: 1),
                Expanded(child: SingleChildScrollView(child: preview)),
              ],
            );
          }

          return ListView(
            children: [
              controls,
              const Divider(height: 1),
              preview,
            ],
          );
        },
      ),
    );
  }
}

class _MatchSceneControls extends StatelessWidget {
  const _MatchSceneControls({
    required this.scene,
    required this.side,
    required this.delivery,
    required this.marking,
    required this.intent,
    required this.opponentReaction,
    required this.defenders,
    required this.intensity,
    required this.risk,
    required this.generating,
    required this.onScene,
    required this.onSide,
    required this.onDelivery,
    required this.onMarking,
    required this.onIntent,
    required this.onOpponentReaction,
    required this.onDefenders,
    required this.onIntensity,
    required this.onRisk,
    required this.onGenerate,
  });

  final String scene;
  final String side;
  final String delivery;
  final String marking;
  final String intent;
  final String opponentReaction;
  final int defenders;
  final double intensity;
  final double risk;
  final bool generating;
  final ValueChanged<String> onScene;
  final ValueChanged<String> onSide;
  final ValueChanged<String> onDelivery;
  final ValueChanged<String> onMarking;
  final ValueChanged<String> onIntent;
  final ValueChanged<String> onOpponentReaction;
  final ValueChanged<int> onDefenders;
  final ValueChanged<double> onIntensity;
  final ValueChanged<double> onRisk;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sceneTitle = switch (scene) {
      'free_kick' => 'Coup franc',
      'penalty' => 'Penalty',
      'throw_in' => 'Touche offensive',
      _ => 'Corner offensif',
    };
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sceneTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.25,
            children: [
              _SceneCard(
                title: 'Corner',
                icon: Icons.flag_rounded,
                selected: scene == 'corner',
                onTap: () => onScene('corner'),
              ),
              _SceneCard(
                title: 'Coup franc',
                icon: Icons.sports_soccer_rounded,
                selected: scene == 'free_kick',
                onTap: () => onScene('free_kick'),
              ),
              _SceneCard(
                title: 'Penalty',
                icon: Icons.gps_fixed_rounded,
                selected: scene == 'penalty',
                onTap: () => onScene('penalty'),
              ),
              _SceneCard(
                title: 'Touche',
                icon: Icons.pan_tool_alt_outlined,
                selected: scene == 'throw_in',
                onTap: () => onScene('throw_in'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SmartSceneBrief(
            scene: scene,
            intent: intent,
            opponentReaction: opponentReaction,
            risk: risk,
          ),
          const SizedBox(height: 14),
          _SceneIntentDropdown(
            scene: scene,
            intent: intent,
            onIntent: onIntent,
          ),
          const SizedBox(height: 12),
          _OpponentReactionDropdown(
            scene: scene,
            reaction: opponentReaction,
            onReaction: onOpponentReaction,
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'left',
                label: Text('Gauche'),
                icon: Icon(Icons.arrow_back),
              ),
              ButtonSegment(
                value: 'right',
                label: Text('Droite'),
                icon: Icon(Icons.arrow_forward),
              ),
            ],
            selected: {side},
            onSelectionChanged: (value) => onSide(value.first),
          ),
          const SizedBox(height: 14),
          _SceneDeliveryDropdown(
            scene: scene,
            delivery: delivery,
            onDelivery: onDelivery,
          ),
          if (scene != 'penalty') ...[
            const SizedBox(height: 12),
            _SceneMarkingDropdown(
              scene: scene,
              marking: marking,
              onMarking: onMarking,
            ),
            const SizedBox(height: 14),
            _SliderBlock(
              label: scene == 'throw_in'
                  ? 'Defenseurs pres de la ligne'
                  : 'Defenseurs dans la surface',
              value: defenders.toDouble(),
              min: scene == 'free_kick' ? 4 : 3,
              max: scene == 'free_kick' ? 7 : 10,
              divisions: scene == 'free_kick' ? 3 : 7,
              display: '$defenders',
              onChanged: (value) => onDefenders(value.round()),
            ),
          ],
          _SliderBlock(
            label: scene == 'penalty'
                ? 'Precision du tir'
                : 'Agressivite des appels',
            value: intensity,
            min: 0,
            max: 1,
            divisions: 10,
            display: '${(intensity * 100).round()}%',
            onChanged: onIntensity,
          ),
          _SliderBlock(
            label: 'Risque accepte',
            value: risk,
            min: 0,
            max: 1,
            divisions: 10,
            display: '${(risk * 100).round()}%',
            onChanged: onRisk,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: generating ? null : onGenerate,
            icon: generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.movie_creation_outlined),
            label: Text('Generer $sceneTitle'),
          ),
        ],
      ),
    );
  }
}

class _SmartSceneBrief extends StatelessWidget {
  const _SmartSceneBrief({
    required this.scene,
    required this.intent,
    required this.opponentReaction,
    required this.risk,
  });

  final String scene;
  final String intent;
  final String opponentReaction;
  final double risk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brief = _briefLines();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_outlined,
                  color: scheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Text(
                'Brief IA coach',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in brief)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _briefLines() {
    final riskText = risk > 0.68
        ? 'Risque haut: garder deux joueurs en securite.'
        : risk > 0.38
            ? 'Risque moyen: securiser la seconde balle.'
            : 'Risque bas: priorite a la conservation.';

    if (scene == 'penalty') {
      return [
        'Decision: fixer une routine simple avant la course.',
        opponentReaction == 'keeper_wait'
            ? 'Gardien patient: ne pas changer de cote trop tard.'
            : 'Gardien agressif: frapper tot et bas.',
        riskText,
      ];
    }
    if (scene == 'free_kick') {
      return [
        intent == 'direct_shot'
            ? 'Decision: chercher le tir direct si le mur ouvre un cote.'
            : 'Decision: utiliser le premier appel comme leurre.',
        opponentReaction == 'jump_wall'
            ? 'Piege adverse: mur qui saute, viser bas ou zone gardien.'
            : 'Piege adverse: ligne fixe, attaquer le dos du dernier joueur.',
        riskText,
      ];
    }
    if (scene == 'throw_in') {
      return [
        intent == 'escape_press'
            ? 'Decision: creer un triangle court pour sortir de pression.'
            : 'Decision: chercher rapidement la surface.',
        'Signal cle: le receveur doit etre de profil avant la touche.',
        riskText,
      ];
    }
    return [
      intent == 'short_combo'
          ? 'Decision: attirer deux defenseurs puis jouer le retour court.'
          : intent == 'first_post'
              ? 'Decision: attaquer le premier poteau pour devier.'
              : 'Decision: isoler un finisseur au second poteau.',
      opponentReaction == 'man_mark'
          ? 'Piege adverse: utiliser les ecrans pour casser le marquage.'
          : 'Piege adverse: saturer les six metres puis viser la zone libre.',
      riskText,
    ];
  }
}

class _SceneIntentDropdown extends StatelessWidget {
  const _SceneIntentDropdown({
    required this.scene,
    required this.intent,
    required this.onIntent,
  });

  final String scene;
  final String intent;
  final ValueChanged<String> onIntent;

  @override
  Widget build(BuildContext context) {
    final items = switch (scene) {
      'free_kick' => const [
          DropdownMenuItem(value: 'direct_shot', child: Text('Tir direct')),
          DropdownMenuItem(
              value: 'screen_keeper', child: Text('Masquer gardien')),
          DropdownMenuItem(value: 'rebound', child: Text('Attaquer rebond')),
        ],
      'penalty' => const [
          DropdownMenuItem(value: 'direct_shot', child: Text('Frappe placee')),
          DropdownMenuItem(value: 'rebound', child: Text('Equipe au rebond')),
        ],
      'throw_in' => const [
          DropdownMenuItem(
              value: 'escape_press', child: Text('Sortir pressing')),
          DropdownMenuItem(
              value: 'long_throw', child: Text('Chercher surface')),
          DropdownMenuItem(
              value: 'short_combo', child: Text('Combinaison courte')),
        ],
      _ => const [
          DropdownMenuItem(value: 'second_post', child: Text('Second poteau')),
          DropdownMenuItem(value: 'first_post', child: Text('Premier poteau')),
          DropdownMenuItem(value: 'short_combo', child: Text('Corner court')),
        ],
    };
    final initialValue =
        items.any((item) => item.value == intent) ? intent : items.first.value!;

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Intention coach',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.ads_click_rounded),
      ),
      items: items,
      onChanged: (value) {
        if (value != null) onIntent(value);
      },
    );
  }
}

class _OpponentReactionDropdown extends StatelessWidget {
  const _OpponentReactionDropdown({
    required this.scene,
    required this.reaction,
    required this.onReaction,
  });

  final String scene;
  final String reaction;
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final items = switch (scene) {
      'free_kick' => const [
          DropdownMenuItem(value: 'jump_wall', child: Text('Mur qui saute')),
          DropdownMenuItem(value: 'protect_six', child: Text('Ligne basse')),
          DropdownMenuItem(value: 'man_mark', child: Text('Marquage appels')),
        ],
      'penalty' => const [
          DropdownMenuItem(
              value: 'keeper_wait', child: Text('Gardien patient')),
          DropdownMenuItem(
              value: 'protect_six', child: Text('Gardien agressif')),
        ],
      'throw_in' => const [
          DropdownMenuItem(
              value: 'press_touchline', child: Text('Pressing ligne')),
          DropdownMenuItem(value: 'man_mark', child: Text('Marquage proche')),
          DropdownMenuItem(value: 'protect_six', child: Text('Bloc bas')),
        ],
      _ => const [
          DropdownMenuItem(value: 'protect_six', child: Text('Protege 6m')),
          DropdownMenuItem(value: 'man_mark', child: Text('Individuel strict')),
          DropdownMenuItem(value: 'press_touchline', child: Text('Sort vite')),
        ],
    };
    final initialValue = items.any((item) => item.value == reaction)
        ? reaction
        : items.first.value!;

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Reaction adverse attendue',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.visibility_outlined),
      ),
      items: items,
      onChanged: (value) {
        if (value != null) onReaction(value);
      },
    );
  }
}

class _SceneDeliveryDropdown extends StatelessWidget {
  const _SceneDeliveryDropdown({
    required this.scene,
    required this.delivery,
    required this.onDelivery,
  });

  final String scene;
  final String delivery;
  final ValueChanged<String> onDelivery;

  @override
  Widget build(BuildContext context) {
    final label = switch (scene) {
      'free_kick' => 'Type de coup franc',
      'penalty' => 'Tireur / intention',
      'throw_in' => 'Type de touche',
      _ => 'Type de corner',
    };
    final items = switch (scene) {
      'free_kick' => const [
          DropdownMenuItem(value: 'direct', child: Text('Direct avec mur')),
          DropdownMenuItem(value: 'indirect', child: Text('Combinaison')),
          DropdownMenuItem(value: 'second_post', child: Text('Second poteau')),
        ],
      'penalty' => const [
          DropdownMenuItem(value: 'right_foot', child: Text('Tireur droitier')),
          DropdownMenuItem(value: 'left_foot', child: Text('Tireur gaucher')),
          DropdownMenuItem(value: 'power', child: Text('Frappe puissance')),
        ],
      'throw_in' => const [
          DropdownMenuItem(value: 'short', child: Text('Touche courte')),
          DropdownMenuItem(value: 'long', child: Text('Touche longue')),
          DropdownMenuItem(
              value: 'inside', child: Text('Combinaison interieure')),
        ],
      _ => const [
          DropdownMenuItem(value: 'outswinger', child: Text('Sortant')),
          DropdownMenuItem(value: 'inswinger', child: Text('Rentrant')),
          DropdownMenuItem(value: 'short', child: Text('Joue court')),
          DropdownMenuItem(value: 'second_post', child: Text('Second poteau')),
        ],
    };
    final initialValue = items.any((item) => item.value == delivery)
        ? delivery
        : items.first.value!;

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.sports_soccer_rounded),
      ),
      items: items,
      onChanged: (value) {
        if (value != null) onDelivery(value);
      },
    );
  }
}

class _SceneMarkingDropdown extends StatelessWidget {
  const _SceneMarkingDropdown({
    required this.scene,
    required this.marking,
    required this.onMarking,
  });

  final String scene;
  final String marking;
  final ValueChanged<String> onMarking;

  @override
  Widget build(BuildContext context) {
    final items = scene == 'free_kick'
        ? const [
            DropdownMenuItem(value: 'wall', child: Text('Mur coup franc')),
            DropdownMenuItem(value: 'zone', child: Text('Ligne + zone')),
            DropdownMenuItem(value: 'individual', child: Text('Individuel')),
          ]
        : const [
            DropdownMenuItem(value: 'zone', child: Text('Defense de zone')),
            DropdownMenuItem(value: 'individual', child: Text('Individuel')),
            DropdownMenuItem(value: 'line4', child: Text('Ligne + gardien')),
          ];
    final initialValue = items.any((item) => item.value == marking)
        ? marking
        : items.first.value!;

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Organisation adverse',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shield_outlined),
      ),
      items: items,
      onChanged: (value) {
        if (value != null) onMarking(value);
      },
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          color: selected ? scheme.primaryContainer : scheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? scheme.primary : scheme.onSurface),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Icon(Icons.check_circle_rounded),
          ],
        ),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.options,
    required this.promptController,
    required this.customFormationController,
    required this.formation,
    required this.tacticalChoice,
    required this.side,
    required this.intensity,
    required this.durationSeconds,
    required this.movementDrafts,
    required this.passDrafts,
    required this.generating,
    required this.onFormation,
    required this.onTacticalChoice,
    required this.onSide,
    required this.onIntensity,
    required this.onDuration,
    required this.onAddMovement,
    required this.onRemoveMovement,
    required this.onAddPass,
    required this.onRemovePass,
    required this.onGenerate,
  });

  final TacticalAnimationOptions options;
  final TextEditingController promptController;
  final TextEditingController customFormationController;
  final String formation;
  final String tacticalChoice;
  final String side;
  final double intensity;
  final double durationSeconds;
  final List<_MovementDraft> movementDrafts;
  final List<_PassDraft> passDrafts;
  final bool generating;
  final ValueChanged<String> onFormation;
  final ValueChanged<String> onTacticalChoice;
  final ValueChanged<String> onSide;
  final ValueChanged<double> onIntensity;
  final ValueChanged<double> onDuration;
  final VoidCallback onAddMovement;
  final ValueChanged<int> onRemoveMovement;
  final VoidCallback onAddPass;
  final ValueChanged<int> onRemovePass;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Scenario', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Idee tactique libre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.psychology_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formation,
              decoration: const InputDecoration(
                labelText: 'Formation',
                border: OutlineInputBorder(),
              ),
              items: options.formations
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onFormation(value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customFormationController,
              decoration: const InputDecoration(
                labelText: 'Formation personnalisee',
                hintText: 'ex: 3-2-4-1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: tacticalChoice,
              decoration: const InputDecoration(
                labelText: 'Choix tactique',
                border: OutlineInputBorder(),
              ),
              items: options.tacticalChoices
                  .map((item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onTacticalChoice(value);
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'left',
                    label: Text('Gauche'),
                    icon: Icon(Icons.arrow_back)),
                ButtonSegment(
                    value: 'right',
                    label: Text('Droite'),
                    icon: Icon(Icons.arrow_forward)),
              ],
              selected: {side},
              onSelectionChanged: (value) => onSide(value.first),
            ),
            const SizedBox(height: 18),
            _SliderBlock(
              label: 'Intensite',
              value: intensity,
              min: 0,
              max: 1,
              divisions: 10,
              display: '${(intensity * 100).round()}%',
              onChanged: onIntensity,
            ),
            _SliderBlock(
              label: 'Duree',
              value: durationSeconds,
              min: 2.5,
              max: 10,
              divisions: 15,
              display: '${durationSeconds.toStringAsFixed(1)}s',
              onChanged: onDuration,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Mouvements par poste',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton.filledTonal(
                  tooltip: 'Ajouter',
                  onPressed: onAddMovement,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (movementDrafts.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ajoute des mouvements precis pour surcharger le scenario collectif.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (var i = 0; i < movementDrafts.length; i += 1)
                _MovementRow(
                  key: ValueKey(
                      'movement-$i-${movementDrafts[i].player}-${movementDrafts[i].move}'),
                  draft: movementDrafts[i],
                  positions: options.positions,
                  movements: options.movements,
                  onRemove: () => onRemoveMovement(i),
                ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text('Sequence de passes exacte',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton.filledTonal(
                  tooltip: 'Ajouter une passe',
                  onPressed: onAddPass,
                  icon: const Icon(Icons.add_link_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (passDrafts.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Si tu ajoutes des passes, le ballon les suivra dans cet ordre puis finira par une frappe au but.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (var i = 0; i < passDrafts.length; i += 1)
                _PassRow(
                  key: ValueKey(
                      'pass-$i-${passDrafts[i].from}-${passDrafts[i].to}'),
                  draft: passDrafts[i],
                  positions: options.positions,
                  onRemove: () => onRemovePass(i),
                ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Generer animation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(display, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: display,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MovementRow extends StatefulWidget {
  const _MovementRow({
    super.key,
    required this.draft,
    required this.positions,
    required this.movements,
    required this.onRemove,
  });

  final _MovementDraft draft;
  final List<String> positions;
  final List<TacticalOption> movements;
  final VoidCallback onRemove;

  @override
  State<_MovementRow> createState() => _MovementRowState();
}

class _MovementRowState extends State<_MovementRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              initialValue: widget.draft.player,
              decoration: const InputDecoration(
                labelText: 'Poste',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.positions
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() {
                widget.draft.player = value ?? widget.draft.player;
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: DropdownButtonFormField<String>(
              initialValue: widget.draft.move,
              decoration: const InputDecoration(
                labelText: 'Mouvement',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.movements
                  .map((item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.label)))
                  .toList(),
              onChanged: (value) => setState(() {
                widget.draft.move = value ?? widget.draft.move;
              }),
            ),
          ),
          IconButton(
            tooltip: 'Retirer',
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _PassRow extends StatefulWidget {
  const _PassRow({
    super.key,
    required this.draft,
    required this.positions,
    required this.onRemove,
  });

  final _PassDraft draft;
  final List<String> positions;
  final VoidCallback onRemove;

  @override
  State<_PassRow> createState() => _PassRowState();
}

class _PassRowState extends State<_PassRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: widget.draft.from,
              decoration: const InputDecoration(
                labelText: 'Passeur',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.positions
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() {
                widget.draft.from = value ?? widget.draft.from;
              }),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: widget.draft.to,
              decoration: const InputDecoration(
                labelText: 'Receveur',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.positions
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() {
                widget.draft.to = value ?? widget.draft.to;
              }),
            ),
          ),
          IconButton(
            tooltip: 'Retirer',
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.animation,
    required this.controller,
    required this.error,
    required this.generating,
    required this.isPlaying,
    required this.editMode,
    required this.onPlay,
    required this.onReset,
    required this.onToggleEdit,
    required this.onPlayerTargetChanged,
    required this.onBallPointChanged,
    required this.onRetry,
  });

  final TacticalAnimation? animation;
  final AnimationController controller;
  final String? error;
  final bool generating;
  final bool isPlaying;
  final bool editMode;
  final VoidCallback onPlay;
  final VoidCallback onReset;
  final VoidCallback onToggleEdit;
  final void Function(String playerId, TacticalPoint point)
      onPlayerTargetChanged;
  final void Function(int index, TacticalPoint point) onBallPointChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final item = animation;
    if (error != null && item == null) {
      return _ErrorPanel(message: error!, onRetry: onRetry);
    }
    if (item == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                          '${item.formation} - ${item.side} - ${item.durationMs} ms'),
                    ],
                  ),
                ),
                IconButton.filled(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: generating || editMode ? null : onPlay,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Reset',
                  onPressed: onReset,
                  icon: const Icon(Icons.replay),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: editMode ? 'Terminer modification' : 'Modifier',
                  onPressed: generating ? null : onToggleEdit,
                  icon: Icon(editMode
                      ? Icons.done_rounded
                      : Icons.edit_location_alt_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (editMode) ...[
              _EditModeHint(),
              const SizedBox(height: 14),
            ],
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final currentMs = controller.value * item.durationMs;
                return _LiveActionBar(
                  point: _activeBallPoint(item.ball, currentMs),
                  progress: controller.value,
                );
              },
            ),
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: AspectRatio(
                  aspectRatio: 0.68,
                  child: _AnimatedPitch(
                    animation: item,
                    controller: controller,
                    editMode: editMode,
                    onPlayerTargetChanged: onPlayerTargetChanged,
                    onBallPointChanged: onBallPointChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _CoachNotes(animation: item),
          ],
        ),
      ),
    );
  }

  TacticalBallPoint? _activeBallPoint(
      List<TacticalBallPoint> points, double currentMs) {
    if (points.isEmpty) return null;
    var active = points.first;
    for (final point in points) {
      if (point.atMs <= currentMs) {
        active = point;
      } else {
        break;
      }
    }
    return active;
  }
}

class _LiveActionBar extends StatelessWidget {
  const _LiveActionBar({required this.point, required this.progress});

  final TacticalBallPoint? point;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = point?.label ?? 'Scenario pret';
    final event = _eventLabel(point?.event ?? '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.sports_soccer_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 10),
              Text(event, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress.clamp(0, 1)),
        ],
      ),
    );
  }

  String _eventLabel(String event) {
    return switch (event) {
      'possession' => 'Controle',
      'carry' => 'Conduite',
      'pass' => 'Passe',
      'receive' => 'Reception',
      'shot_preparation' => 'Frappe',
      'goal' => 'But',
      _ => 'Live',
    };
  }
}

class _EditModeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode coach: deplace les points bleus pour les courses et les points jaunes pour le ballon.',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPitch extends StatelessWidget {
  const _AnimatedPitch({
    required this.animation,
    required this.controller,
    required this.editMode,
    required this.onPlayerTargetChanged,
    required this.onBallPointChanged,
  });

  final TacticalAnimation animation;
  final AnimationController controller;
  final bool editMode;
  final void Function(String playerId, TacticalPoint point)
      onPlayerTargetChanged;
  final void Function(int index, TacticalPoint point) onBallPointChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PitchPainter(
                        animation: animation, value: controller.value),
                  ),
                ),
                for (final player in animation.players)
                  _PlayerToken(
                    player: player,
                    point: _playerPoint(
                        player, controller.value, animation.durationMs),
                    size: size,
                  ),
                if (animation.ball.isNotEmpty)
                  _BallToken(
                    point: _ballPoint(
                        animation.ball, controller.value, animation.durationMs),
                    size: size,
                  ),
                if (editMode) ...[
                  for (final player in animation.players)
                    _DragHandle(
                      point: player.to,
                      size: size,
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.directions_run_rounded,
                      tooltip: 'Fin de course ${player.label}',
                      onPanUpdate: (details) => onPlayerTargetChanged(
                        player.id,
                        _shiftPoint(player.to, details.delta, size),
                      ),
                    ),
                  for (var i = 0; i < animation.ball.length; i += 1)
                    _DragHandle(
                      point: animation.ball[i].point,
                      size: size,
                      color: const Color(0xFFFFD166),
                      icon: animation.ball[i].event == 'goal'
                          ? Icons.sports_score_rounded
                          : Icons.sports_soccer_rounded,
                      tooltip: animation.ball[i].label ?? 'Point ballon',
                      onPanUpdate: (details) => onBallPointChanged(
                        i,
                        _shiftPoint(
                            animation.ball[i].point, details.delta, size),
                      ),
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  TacticalPoint _playerPoint(
      TacticalAnimationPlayer player, double value, int durationMs) {
    final currentMs = value * durationMs;
    if (currentMs <= player.startMs) return player.from;
    if (currentMs >= player.endMs) return player.to;
    final local = (currentMs - player.startMs) /
        math.max(1, player.endMs - player.startMs);
    final eased = Curves.easeInOutCubic.transform(local.clamp(0, 1));
    return TacticalPoint(
      x: player.from.x + (player.to.x - player.from.x) * eased,
      y: player.from.y + (player.to.y - player.from.y) * eased,
    );
  }

  TacticalPoint _ballPoint(
      List<TacticalBallPoint> points, double value, int durationMs) {
    final currentMs = value * durationMs;
    var previous = points.first;
    for (final next in points.skip(1)) {
      if (currentMs <= next.atMs) {
        final span = math.max(1, next.atMs - previous.atMs);
        final local =
            ((currentMs - previous.atMs) / span).clamp(0, 1).toDouble();
        final eased = Curves.easeInOut.transform(local);
        return TacticalPoint(
          x: previous.point.x + (next.point.x - previous.point.x) * eased,
          y: previous.point.y + (next.point.y - previous.point.y) * eased,
        );
      }
      previous = next;
    }
    return points.last.point;
  }

  TacticalPoint _shiftPoint(TacticalPoint point, Offset delta, Size size) {
    return TacticalPoint(
      x: point.x + (delta.dx / math.max(1, size.width)) * 100,
      y: point.y + (delta.dy / math.max(1, size.height)) * 100,
    ).clamp();
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.point,
    required this.size,
    required this.color,
    required this.icon,
    required this.tooltip,
    required this.onPanUpdate,
  });

  final TacticalPoint point;
  final Size size;
  final Color color;
  final IconData icon;
  final String tooltip;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final x = point.x / 100 * size.width;
    final y = point.y / 100 * size.height;
    return Positioned(
      left: x - 15,
      top: y - 15,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPanUpdate,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 15, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _PlayerToken extends StatelessWidget {
  const _PlayerToken({
    required this.player,
    required this.point,
    required this.size,
  });

  final TacticalAnimationPlayer player;
  final TacticalPoint point;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final x = point.x / 100 * size.width;
    final y = point.y / 100 * size.height;
    final scheme = Theme.of(context).colorScheme;
    final away = player.team == 'away';
    final tokenColor = away ? const Color(0xFFE53935) : scheme.primary;
    final labelColor = away ? Colors.white : scheme.onPrimary;
    final borderColor = away ? const Color(0xFFFFCDD2) : Colors.white;
    return Positioned(
      left: x - 22,
      top: y - 22,
      child: Tooltip(
        message: player.instruction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokenColor,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  player.label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 72),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                player.movement,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BallToken extends StatelessWidget {
  const _BallToken({required this.point, required this.size});

  final TacticalPoint point;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final x = point.x / 100 * size.width;
    final y = point.y / 100 * size.height;
    return Positioned(
      left: x - 8,
      top: y - 8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.black87, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter({required this.animation, required this.value});

  final TacticalAnimation animation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D6B42), Color(0xFF093F2C)],
      ).createShader(rect);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)), bg);

    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (var i = 0; i < 8; i += 1) {
      if (i.isEven) {
        canvas.drawRect(
            Rect.fromLTWH(0, i * size.height / 8, size.width, size.height / 8),
            stripe);
      }
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(6)),
      line,
    );
    canvas.drawLine(Offset(10, size.height / 2),
        Offset(size.width - 10, size.height / 2), thin);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.13, thin);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2.5,
        Paint()..color = Colors.white);
    _box(canvas, size, true, line, thin);
    _box(canvas, size, false, line, thin);
    _drawBallTrail(canvas, size);

    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final player in animation.players) {
      final start = _offset(player.from, size);
      final end = _offset(player.to, size);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + end.dx) / 2,
          (start.dy + end.dy) / 2 - 18,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, pathPaint);
      _arrow(canvas, start, end, pathPaint.color);
    }
  }

  void _box(Canvas canvas, Size size, bool top, Paint line, Paint thin) {
    final y = top ? 10.0 : size.height - 10.0;
    final sign = top ? 1.0 : -1.0;
    final penalty = Rect.fromCenter(
      center: Offset(size.width / 2, y + sign * size.height * 0.095),
      width: size.width * 0.52,
      height: size.height * 0.19,
    );
    final six = Rect.fromCenter(
      center: Offset(size.width / 2, y + sign * size.height * 0.038),
      width: size.width * 0.28,
      height: size.height * 0.076,
    );
    canvas.drawRect(penalty, thin);
    canvas.drawRect(six, thin);
    canvas.drawCircle(
        Offset(size.width / 2, y + sign * size.height * 0.13), 2.5, line);
  }

  Offset _offset(TacticalPoint point, Size size) {
    return Offset(point.x / 100 * size.width, point.y / 100 * size.height);
  }

  void _drawBallTrail(Canvas canvas, Size size) {
    final points = animation.ball;
    if (points.length < 2) return;

    final currentMs = value * animation.durationMs;
    final futurePaint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final donePaint = Paint()
      ..color = const Color(0xFFFFF3B0).withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < points.length; i += 1) {
      final from = points[i - 1];
      final to = points[i];
      final start = _offset(from.point, size);
      final end = _offset(to.point, size);
      final paint = to.atMs <= currentMs ? donePaint : futurePaint;
      final control = _curveControlPoint(start, end, i);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
      _arrow(canvas, control, end, paint.color);

      if (to.event == 'pass' || to.event == 'cross' || to.event == 'goal') {
        final marker = Paint()
          ..color = to.event == 'goal'
              ? const Color(0xFFFF4D6D)
              : const Color(0xFFFFD166)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(end, to.event == 'goal' ? 7 : 5, marker);
        _drawSmallLabel(
          canvas,
          to.event == 'goal' ? 'GOAL' : '$i',
          end + const Offset(8, -10),
          size,
        );
      }
    }
  }

  Offset _curveControlPoint(Offset start, Offset end, int index) {
    final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final vector = end - start;
    if (vector.distance < 4) return midpoint;
    final normal = Offset(-vector.dy, vector.dx) / vector.distance;
    final curve = math.min(42.0, math.max(12.0, vector.distance * 0.16));
    final direction = index.isEven ? 1.0 : -1.0;
    return midpoint + normal * curve * direction;
  }

  void _drawSmallLabel(Canvas canvas, String text, Offset offset, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = offset.dx.clamp(4.0, size.width - painter.width - 4);
    final dy = offset.dy.clamp(4.0, size.height - painter.height - 4);
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx - 4, dy - 2, painter.width + 8, painter.height + 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(bg, Paint()..color = Colors.black.withValues(alpha: 0.58));
    painter.paint(canvas, Offset(dx, dy));
  }

  void _arrow(Canvas canvas, Offset start, Offset end, Color color) {
    final vector = end - start;
    if (vector.distance < 4) return;
    final angle = math.atan2(vector.dy, vector.dx);
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const length = 7.0;
    final p1 = Offset(
      end.dx - length * math.cos(angle - math.pi / 7),
      end.dy - length * math.sin(angle - math.pi / 7),
    );
    final p2 = Offset(
      end.dx - length * math.cos(angle + math.pi / 7),
      end.dy - length * math.sin(angle + math.pi / 7),
    );
    canvas.drawLine(end, p1, arrowPaint);
    canvas.drawLine(end, p2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.value != value;
  }
}

class _CoachNotes extends StatelessWidget {
  const _CoachNotes({required this.animation});

  final TacticalAnimation animation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _InfoCard(
          title: 'Points coach',
          icon: Icons.record_voice_over_outlined,
          children: animation.coachingPoints,
        ),
        _InfoCard(
          title: 'Details moteur',
          icon: Icons.memory_outlined,
          children: animation.notes,
        ),
        _TimelineCard(animation: animation),
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_2_outlined),
                  SizedBox(width: 8),
                  Text('Joueurs'),
                ],
              ),
              const SizedBox(height: 10),
              Text('${animation.players.length} postes animes'),
              Text(
                  '${animation.players.map((p) => p.movement).toSet().length} mouvements distincts'),
              if (animation.passSequence.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  animation.passSequence
                      .map((pass) => '${pass.from} -> ${pass.to}')
                      .join('  |  '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                const Text('Fin: frappe vers le but'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.animation});

  final TacticalAnimation animation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final events = animation.ball
        .where((item) =>
            item.label != null &&
            item.label!.isNotEmpty &&
            item.event != 'carry')
        .toList();
    return Container(
      width: 330,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Scenario exact',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          for (final event in events.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${(event.atMs / 1000).toStringAsFixed(1)}s',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(child: Text(event.label!)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 330,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 15, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(child)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline_rounded, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementDraft {
  _MovementDraft({required this.player, required this.move});

  String player;
  String move;
}

class _PassDraft {
  _PassDraft({required this.from, required this.to});

  String from;
  String to;
}
