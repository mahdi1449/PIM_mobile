import 'player.dart';

// Participation Status Enum
enum ParticipationStatus {
  invited('invited'),
  confirmed('confirmed'),
  completed('completed'),
  absent('absent');

  final String value;
  const ParticipationStatus(this.value);

  static ParticipationStatus fromString(String value) {
    return ParticipationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParticipationStatus.invited,
    );
  }
}

// Event Player Model
class EventPlayer {
  final String id;
  final String eventId;
  final Player player;
  final ParticipationStatus status;
  final String? coachNotes;
  final DateTime joinedAt;
  final DateTime? completedAt;

  EventPlayer({
    required this.id,
    required this.eventId,
    required this.player,
    required this.status,
    this.coachNotes,
    required this.joinedAt,
    this.completedAt,
  });

  factory EventPlayer.fromJson(Map<String, dynamic> json) {
    return EventPlayer(
      id: json['_id'] ?? json['id'],
      eventId: json['eventId'],
      player: json['playerId'] is String
          ? Player(
              id: json['playerId'],
              firstName: '',
              lastName: '',
              dateOfBirth: DateTime.now(),
              position: '',
              strongFoot: 'Right',
            )
          : Player.fromJson(json['playerId']),
      status: ParticipationStatus.fromString(json['status']),
      coachNotes: json['coachNotes'],
      joinedAt: DateTime.parse(json['joinedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'playerId': player.id,
      'status': status.value,
      'coachNotes': coachNotes,
      'joinedAt': joinedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case ParticipationStatus.invited:
        return 'Invité';
      case ParticipationStatus.confirmed:
        return 'Confirmé';
      case ParticipationStatus.completed:
        return 'Complété';
      case ParticipationStatus.absent:
        return 'Absent';
    }
  }

  bool get isCompleted => status == ParticipationStatus.completed;
  bool get isConfirmed => status == ParticipationStatus.confirmed;
}
