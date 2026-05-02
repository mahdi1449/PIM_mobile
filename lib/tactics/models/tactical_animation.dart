class TacticalAnimationOptions {
  const TacticalAnimationOptions({
    required this.formations,
    required this.tacticalChoices,
    required this.movements,
    required this.sides,
    required this.scenarioTypes,
    required this.opponentShapes,
    required this.positions,
  });

  final List<String> formations;
  final List<TacticalOption> tacticalChoices;
  final List<TacticalOption> movements;
  final List<TacticalOption> sides;
  final List<TacticalOption> scenarioTypes;
  final List<TacticalOption> opponentShapes;
  final List<String> positions;

  factory TacticalAnimationOptions.fromJson(Map<String, dynamic> json) {
    return TacticalAnimationOptions(
      formations: _stringList(json['formations']),
      tacticalChoices: _optionList(json['tacticalChoices']),
      movements: _optionList(json['movements']),
      sides: _optionList(json['sides']),
      scenarioTypes: _optionList(json['scenarioTypes']),
      opponentShapes: _optionList(json['opponentShapes']),
      positions: _stringList(json['positions']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList();
  }

  static List<TacticalOption> _optionList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => TacticalOption.fromJson(item))
        .toList();
  }
}

class TacticalOption {
  const TacticalOption({
    required this.id,
    required this.label,
    this.phase,
  });

  final String id;
  final String label;
  final String? phase;

  factory TacticalOption.fromJson(Map<dynamic, dynamic> json) {
    return TacticalOption(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['id']?.toString() ?? '',
      phase: json['phase']?.toString(),
    );
  }
}

class TacticalMovementRequest {
  const TacticalMovementRequest({
    required this.player,
    required this.move,
  });

  final String player;
  final String move;

  Map<String, dynamic> toJson() => {
        'player': player,
        'move': move,
      };
}

class TacticalPassRequest {
  const TacticalPassRequest({
    required this.from,
    required this.to,
  });

  final String from;
  final String to;

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
      };
}

class TacticalAnimationRequest {
  const TacticalAnimationRequest({
    this.prompt,
    required this.formation,
    required this.tacticalChoice,
    required this.scenarioType,
    required this.opponentShape,
    required this.defenderCount,
    this.deliveryType,
    this.sceneIntent,
    this.opponentReaction,
    this.riskLevel,
    required this.side,
    required this.intensity,
    required this.durationMs,
    required this.movements,
    required this.passSequence,
  });

  final String? prompt;
  final String formation;
  final String tacticalChoice;
  final String scenarioType;
  final String opponentShape;
  final int defenderCount;
  final String? deliveryType;
  final String? sceneIntent;
  final String? opponentReaction;
  final double? riskLevel;
  final String side;
  final double intensity;
  final int durationMs;
  final List<TacticalMovementRequest> movements;
  final List<TacticalPassRequest> passSequence;

  Map<String, dynamic> toJson() => {
        if (prompt != null && prompt!.trim().isNotEmpty) 'prompt': prompt,
        'formation': formation,
        'tacticalChoice': tacticalChoice,
        'scenarioType': scenarioType,
        'opponentShape': opponentShape,
        'defenderCount': defenderCount,
        if (deliveryType != null) 'deliveryType': deliveryType,
        if (sceneIntent != null) 'sceneIntent': sceneIntent,
        if (opponentReaction != null) 'opponentReaction': opponentReaction,
        if (riskLevel != null) 'riskLevel': riskLevel,
        'side': side,
        'intensity': intensity,
        'durationMs': durationMs,
        'movements': movements.map((item) => item.toJson()).toList(),
        'passSequence': passSequence.map((item) => item.toJson()).toList(),
      };
}

class TacticalAnimation {
  const TacticalAnimation({
    required this.title,
    required this.formation,
    required this.tacticalChoice,
    required this.side,
    required this.durationMs,
    required this.players,
    required this.ball,
    required this.passSequence,
    required this.coachingPoints,
    required this.notes,
  });

  final String title;
  final String formation;
  final String tacticalChoice;
  final String side;
  final int durationMs;
  final List<TacticalAnimationPlayer> players;
  final List<TacticalBallPoint> ball;
  final List<TacticalPassRequest> passSequence;
  final List<String> coachingPoints;
  final List<String> notes;

  TacticalAnimation copyWith({
    String? title,
    String? formation,
    String? tacticalChoice,
    String? side,
    int? durationMs,
    List<TacticalAnimationPlayer>? players,
    List<TacticalBallPoint>? ball,
    List<TacticalPassRequest>? passSequence,
    List<String>? coachingPoints,
    List<String>? notes,
  }) {
    return TacticalAnimation(
      title: title ?? this.title,
      formation: formation ?? this.formation,
      tacticalChoice: tacticalChoice ?? this.tacticalChoice,
      side: side ?? this.side,
      durationMs: durationMs ?? this.durationMs,
      players: players ?? this.players,
      ball: ball ?? this.ball,
      passSequence: passSequence ?? this.passSequence,
      coachingPoints: coachingPoints ?? this.coachingPoints,
      notes: notes ?? this.notes,
    );
  }

  factory TacticalAnimation.fromJson(Map<String, dynamic> json) {
    return TacticalAnimation(
      title: json['title']?.toString() ?? 'Animation tactique',
      formation: json['formation']?.toString() ?? '',
      tacticalChoice: json['tacticalChoice']?.toString() ?? '',
      side: json['side']?.toString() ?? '',
      durationMs: _asInt(json['durationMs']) ?? 5200,
      players: (json['players'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => TacticalAnimationPlayer.fromJson(item))
          .toList(),
      ball: (json['ball'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => TacticalBallPoint.fromJson(item))
          .toList(),
      passSequence: (json['passSequence'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => TacticalPassRequest(
              from: item['from']?.toString() ?? '',
              to: item['to']?.toString() ?? '',
            ),
          )
          .where((item) => item.from.isNotEmpty && item.to.isNotEmpty)
          .toList(),
      coachingPoints: _stringList(json['coachingPoints']),
      notes: _stringList(json['notes']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString()).toList();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class TacticalAnimationPlayer {
  const TacticalAnimationPlayer({
    required this.id,
    required this.label,
    required this.role,
    required this.line,
    required this.team,
    required this.movement,
    required this.from,
    required this.to,
    required this.startMs,
    required this.endMs,
    required this.instruction,
  });

  final String id;
  final String label;
  final String role;
  final String line;
  final String team;
  final String movement;
  final TacticalPoint from;
  final TacticalPoint to;
  final int startMs;
  final int endMs;
  final String instruction;

  TacticalAnimationPlayer copyWith({
    String? id,
    String? label,
    String? role,
    String? line,
    String? team,
    String? movement,
    TacticalPoint? from,
    TacticalPoint? to,
    int? startMs,
    int? endMs,
    String? instruction,
  }) {
    return TacticalAnimationPlayer(
      id: id ?? this.id,
      label: label ?? this.label,
      role: role ?? this.role,
      line: line ?? this.line,
      team: team ?? this.team,
      movement: movement ?? this.movement,
      from: from ?? this.from,
      to: to ?? this.to,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      instruction: instruction ?? this.instruction,
    );
  }

  factory TacticalAnimationPlayer.fromJson(Map<dynamic, dynamic> json) {
    return TacticalAnimationPlayer(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      line: json['line']?.toString() ?? '',
      team: json['team']?.toString() ?? 'home',
      movement: json['movement']?.toString() ?? '',
      from: TacticalPoint.fromJson(json['from']),
      to: TacticalPoint.fromJson(json['to']),
      startMs: TacticalAnimation._asInt(json['startMs']) ?? 0,
      endMs: TacticalAnimation._asInt(json['endMs']) ?? 2500,
      instruction: json['instruction']?.toString() ?? '',
    );
  }
}

class TacticalBallPoint {
  const TacticalBallPoint({
    required this.point,
    required this.atMs,
    required this.event,
    this.role,
    this.from,
    this.to,
    this.label,
  });

  final TacticalPoint point;
  final int atMs;
  final String event;
  final String? role;
  final String? from;
  final String? to;
  final String? label;

  TacticalBallPoint copyWith({
    TacticalPoint? point,
    int? atMs,
    String? event,
    String? role,
    String? from,
    String? to,
    String? label,
  }) {
    return TacticalBallPoint(
      point: point ?? this.point,
      atMs: atMs ?? this.atMs,
      event: event ?? this.event,
      role: role ?? this.role,
      from: from ?? this.from,
      to: to ?? this.to,
      label: label ?? this.label,
    );
  }

  factory TacticalBallPoint.fromJson(Map<dynamic, dynamic> json) {
    return TacticalBallPoint(
      point: TacticalPoint.fromJson(json),
      atMs: TacticalAnimation._asInt(json['atMs']) ?? 0,
      event: json['event']?.toString() ?? '',
      role: json['role']?.toString(),
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      label: json['label']?.toString(),
    );
  }
}

class TacticalPoint {
  const TacticalPoint({required this.x, required this.y});

  final double x;
  final double y;

  TacticalPoint clamp() {
    return TacticalPoint(
      x: x.clamp(4, 96).toDouble(),
      y: y.clamp(2, 98).toDouble(),
    );
  }

  factory TacticalPoint.fromJson(dynamic value) {
    if (value is Map) {
      return TacticalPoint(
        x: _asDouble(value['x']) ?? 50,
        y: _asDouble(value['y']) ?? 50,
      );
    }
    return const TacticalPoint(x: 50, y: 50);
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
