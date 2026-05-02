class Event {
  final String id;
  final String clubId;
  final String eventType;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String? location;
  final Map<String, dynamic>? eventDetails;
  final String status;
  final String visibility;
  final String? teamId;
  final Map<String, dynamic>? team;
  final int? homeScore;
  final int? awayScore;
  final String? opponentName;
  final int? matchDuration;
  final bool isHome;
  final dynamic aiDebrief;
  final Map<String, dynamic>? matchSummary;
  final bool reminderEnabled;
  final int reminderMinutes;
  final String? createdBy;
  final DateTime? createdAt;
  final WeatherInfo? weather;
  final LogisticsInfo? logistics;

  Event({
    required this.id,
    required this.clubId,
    required this.eventType,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.allDay = false,
    this.location,
    this.eventDetails,
    this.status = 'scheduled',
    this.visibility = 'club',
    this.teamId,
    this.team,
    this.homeScore,
    this.awayScore,
    this.opponentName,
    this.matchDuration = 90,
    this.isHome = true,
    this.aiDebrief,
    this.matchSummary,
    this.reminderEnabled = true,
    this.reminderMinutes = 60,
    this.createdBy,
    this.createdAt,
    this.weather,
    this.logistics,
  });

  String? get teamName => team?['name'];

  String get eventTypeLabel {
    switch (eventType) {
      case 'match': return 'Match';
      case 'detection': return 'Scouting';
      case 'entrainement': return 'Entraînement';
      case 'reunion': return 'Réunion';
      case 'test_physique': return 'Test Physique';
      default: return 'Autre';
    }
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? json['_id'] ?? '',
      clubId: json['clubId'] ?? '',
      eventType: json['eventType'] ?? 'autre',
      title: json['title'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      allDay: json['allDay'] ?? false,
      location: json['location'],
      eventDetails: json['eventDetails'] is Map<String, dynamic>
          ? json['eventDetails']
          : null,
      status: json['status'] ?? 'scheduled',
      visibility: json['visibility'] ?? 'club',
      teamId: json['teamId'],
      team: json['team'] is Map<String, dynamic> ? json['team'] : null,
      homeScore: json['homeScore'] != null ? int.tryParse(json['homeScore'].toString()) : null,
      awayScore: json['awayScore'] != null ? int.tryParse(json['awayScore'].toString()) : null,
      opponentName: json['opponentName'],
      matchDuration: json['matchDuration'] != null ? int.tryParse(json['matchDuration'].toString()) : 90,
      isHome: json['isHome'] ?? true,
      aiDebrief: json['aiDebrief'],
      matchSummary: json['matchSummary'],
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderMinutes: json['reminderMinutes'] ?? 60,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      weather: json['weather'] != null ? WeatherInfo.fromJson(json['weather']) : null,
      logistics: json['logistics'] != null ? LogisticsInfo.fromJson(json['logistics']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'allDay': allDay,
    'location': location,
    'eventDetails': eventDetails,
    'visibility': visibility,
    'teamId': teamId,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'opponentName': opponentName,
    'matchDuration': matchDuration,
    'isHome': isHome,
    'aiDebrief': aiDebrief,
    'matchSummary': matchSummary,
    'reminderEnabled': reminderEnabled,
    'reminderMinutes': reminderMinutes,
  };
}

class WeatherInfo {
  final double tempCelsius;
  final String condition;
  final String icon;
  final double windKmh;

  WeatherInfo({
    required this.tempCelsius,
    required this.condition,
    required this.icon,
    required this.windKmh,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      tempCelsius: (json['tempCelsius'] ?? 0.0).toDouble(),
      condition: json['condition'] ?? '',
      icon: json['icon'] ?? '',
      windKmh: (json['windKmh'] ?? 0.0).toDouble(),
    );
  }
}

class LogisticsInfo {
  final DateTime? departureTime;
  final int? travelTimeSeconds;
  final double? distanceKm;
  final String? itineraryUrl;
  final String? startAddress;
  final double? lat;
  final double? lon;

  LogisticsInfo({
    this.departureTime,
    this.travelTimeSeconds,
    this.distanceKm,
    this.itineraryUrl,
    this.startAddress,
    this.lat,
    this.lon,
  });

  factory LogisticsInfo.fromJson(Map<String, dynamic> json) {
    return LogisticsInfo(
      departureTime: json['departureTime'] != null ? DateTime.tryParse(json['departureTime'].toString()) : null,
      travelTimeSeconds: json['travelTimeSeconds'],
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      itineraryUrl: json['itineraryUrl'],
      startAddress: json['startAddress'],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
    );
  }
}

class EventParticipant {
  final String id;
  final String eventId;
  final String participantType;
  final String participantId;
  final String status;
  final String name;
  final String role;
  final String? type; // 'starter', 'substitute', etc.
  final bool played;
  final bool isStarter;
  final double? rating;
  final int goals;
  final int assists;
  final int minutesPlayed;
  final int? minuteIn;
  final int? minuteOut;
  final int shotsOnTarget;
  final int keyPasses;
  final int tackles;
  final int interceptions;
  final int clearances;
  final int saves;
  final int goalsConceded;
  final int penaltiesSaved;
  final bool yellowCard;
  final bool redCard;
  final int? cardMinute;
  final double distanceCovered;
  final double topSpeed;
  final int sprints;
  final String? privateNote;
  final String? publicNote;
  final bool notificationSent;
  final DateTime? responseDate;
  final bool isMe;
  final String? participantName;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.participantType,
    required this.participantId,
    this.status = 'pending',
    this.name = 'Joueur',
    this.role = 'Joueur',
    this.type,
    this.played = false,
    this.isStarter = false,
    this.rating,
    this.goals = 0,
    this.assists = 0,
    this.minutesPlayed = 0,
    this.minuteIn,
    this.minuteOut,
    this.shotsOnTarget = 0,
    this.keyPasses = 0,
    this.tackles = 0,
    this.interceptions = 0,
    this.clearances = 0,
    this.saves = 0,
    this.goalsConceded = 0,
    this.penaltiesSaved = 0,
    this.yellowCard = false,
    this.redCard = false,
    this.cardMinute,
    this.distanceCovered = 0.0,
    this.topSpeed = 0.0,
    this.sprints = 0,
    this.privateNote,
    this.publicNote,
    this.notificationSent = false,
    this.responseDate,
    this.isMe = false,
    this.participantName,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] ?? json['_id'] ?? '',
      eventId: json['eventId'] ?? '',
      participantType: json['participantType'] ?? '',
      participantId: json['participantId'] ?? '',
      status: json['status'] ?? 'pending',
      name: json['participantName'] ?? json['name'] ?? json['participant']?['firstName'] ?? 'Joueur',
      role: json['role'] ?? json['participantType'] ?? 'Joueur',
      type: json['type'] ?? (json['isStarter'] == true ? 'starter' : 'substitute'),
      played: json['played'] == true || json['played'] == 1,
      isStarter: json['isStarter'] == true || json['isStarter'] == 1,
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      minutesPlayed: json['minutesPlayed'] ?? 0,
      minuteIn: json['minuteIn'],
      minuteOut: json['minuteOut'],
      shotsOnTarget: json['shotsOnTarget'] ?? 0,
      keyPasses: json['keyPasses'] ?? 0,
      tackles: json['tackles'] ?? 0,
      interceptions: json['interceptions'] ?? 0,
      clearances: json['clearances'] ?? 0,
      saves: json['saves'] ?? 0,
      goalsConceded: json['goalsConceded'] ?? 0,
      penaltiesSaved: json['penaltiesSaved'] ?? 0,
      yellowCard: json['yellowCard'] ?? false,
      redCard: json['redCard'] ?? false,
      cardMinute: json['cardMinute'],
      distanceCovered: (json['distanceCovered'] ?? 0.0).toDouble(),
      topSpeed: (json['topSpeed'] ?? 0.0).toDouble(),
      sprints: json['sprints'] ?? 0,
      privateNote: json['privateNote'],
      publicNote: json['publicNote'],
      notificationSent: json['notificationSent'] ?? false,
      responseDate: json['responseDate'] != null
          ? DateTime.tryParse(json['responseDate'].toString())
          : null,
      isMe: json['isMe'] ?? false,
      participantName: json['participant']?['fullName'],
    );
  }
}
