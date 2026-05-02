class MatchLiveEvent {
  final String id;
  final String eventId;
  final String type;
  final int minute;
  final String? playerId;
  final String? playerName;
  final String? playerInId;
  final String? playerInName;
  final String? assistPlayerId;
  final String? assistPlayerName;
  final String? description;

  MatchLiveEvent({
    required this.id,
    required this.eventId,
    required this.type,
    required this.minute,
    this.playerId,
    this.playerName,
    this.playerInId,
    this.playerInName,
    this.assistPlayerId,
    this.assistPlayerName,
    this.description,
  });

  String get displayTitle {
    switch (type) {
      case 'goal': return 'BUT !';
      case 'own_goal': return 'BUT CONTRE SON CAMP';
      case 'yellow_card': return 'CARTON JAUNE';
      case 'red_card': return 'CARTON ROUGE';
      case 'substitution': return 'CHANGEMENT';
      case 'injury': return 'BLESSURE';
      default: return type.toUpperCase();
    }
  }

  factory MatchLiveEvent.fromJson(Map<String, dynamic> json) {
    return MatchLiveEvent(
      id: json['id'] ?? json['_id'] ?? '',
      eventId: json['eventId'] ?? '',
      type: json['type'] ?? 'custom',
      minute: json['minute'] ?? 0,
      playerId: json['playerId'],
      playerName: json['playerName'],
      playerInId: json['playerInId'],
      playerInName: json['playerInName'],
      assistPlayerId: json['assistPlayerId'],
      assistPlayerName: json['assistPlayerName'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'minute': minute,
    'playerId': playerId,
    'playerName': playerName,
    'playerInId': playerInId,
    'playerInName': playerInName,
    'assistPlayerId': assistPlayerId,
    'assistPlayerName': assistPlayerName,
    'description': description,
  };
}
