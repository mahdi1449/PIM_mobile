import 'package:flutter/material.dart';

class TravelModel {
  final String id;
  final String clubId;
  final String matchId;
  final String destination;
  final double? destinationLat;
  final double? destinationLng;
  final String type; // 'away' | 'home' | 'tour'
  final TravelDeparture departure;
  final TravelReturn travelReturn;
  final TravelHotel hotel;
  final TravelParticipants participants;
  final AirportInfo? departureAirport;
  final AirportInfo? arrivalAirport;
  final String status; // 'planned' | 'active' | 'completed' | 'cancelled'
  final String? notes;
  final double? budgetEstime;

  TravelModel({
    required this.id,
    required this.clubId,
    required this.matchId,
    required this.destination,
    this.destinationLat,
    this.destinationLng,
    required this.type,
    required this.departure,
    required this.travelReturn,
    required this.hotel,
    required this.participants,
    this.departureAirport,
    this.arrivalAirport,
    required this.status,
    this.notes,
    this.budgetEstime,
  });

  factory TravelModel.fromJson(Map<String, dynamic> json) => TravelModel(
    id: json['_id'] ?? '',
    clubId: json['clubId'] ?? '',
    matchId: json['matchId'] is Map ? (json['matchId']['_id'] ?? '') : (json['matchId'] ?? ''),
    destination: json['destination'] ?? 'Destination inconnue',
    destinationLat: json['destinationLat']?.toDouble(),
    destinationLng: json['destinationLng']?.toDouble(),
    type: json['type'] ?? 'away',
    departure: TravelDeparture.fromJson(json['departure'] ?? {}),
    travelReturn: TravelReturn.fromJson(json['return'] ?? {}),
    hotel: TravelHotel.fromJson(json['hotel'] ?? {}),
    participants: TravelParticipants.fromJson(json['participants'] ?? {}),
    departureAirport: json['departureAirport'] != null
        ? AirportInfo.fromJson(json['departureAirport']) : null,
    arrivalAirport: json['arrivalAirport'] != null
        ? AirportInfo.fromJson(json['arrivalAirport']) : null,
    status: json['status'] ?? 'planned',
    notes: json['notes'],
    budgetEstime: json['budgetEstime']?.toDouble(),
  );

  // Couleur selon le statut
  Color get statusColor {
    switch (status) {
      case 'planned': return const Color(0xFF1D9E75);
      case 'active': return const Color(0xFFEF9F27);
      case 'completed': return Colors.white38;
      case 'cancelled': return const Color(0xFFE24B4A);
      default: return Colors.white38;
    }
  }

  // Label du statut en français
  String get statusLabel {
    switch (status) {
      case 'planned': return 'Planifié';
      case 'active': return 'En cours';
      case 'completed': return 'Terminé';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  }

  // Countdown UX
  String get countdownLabel {
    if (status == 'completed') return 'Terminé';
    if (status == 'planned') {
      final now = DateTime.now();
      final diff = departure.at.difference(now);
      if (diff.isNegative) return 'Planifié (Retard)';
      if (diff.inDays == 0) return 'Aujourd\'hui · dans ${diff.inHours}h';
      if (diff.inDays == 1) return 'Demain';
      return 'Dans ${diff.inDays} jours';
    }

    final now = DateTime.now();
    final diff = departure.at.difference(now);
    
    if (diff.isNegative) return 'En cours';
    if (diff.inDays == 0) {
      if (diff.inHours > 0) return 'Aujourd\'hui · dans ${diff.inHours}h';
      return 'Départ imminent';
    }
    if (diff.inDays == 1) return 'Demain';
    return 'Dans ${diff.inDays} jours';
  }

  Color get countdownColor {
    if (status == 'completed') return Colors.white38;
    if (status == 'planned') return const Color(0xFF1D9E75); // Vert pour planifié
    final now = DateTime.now();
    final diff = departure.at.difference(now);
    if (diff.inDays == 0) return const Color(0xFFE24B4A); // Rouge
    if (diff.inDays == 1) return const Color(0xFFEF9F27); // Orange
    return const Color(0xFF1D9E75); // Vert
  }
}

class TravelDeparture {
  final DateTime at;
  final String from;
  final double? fromLat;
  final double? fromLng;
  final String mode; // 'bus' | 'flight' | 'train' | 'car'
  final String? flightNumber;
  final String? terminal;

  TravelDeparture({
    required this.at, required this.from, this.fromLat, this.fromLng,
    required this.mode, this.flightNumber, this.terminal,
  });

  factory TravelDeparture.fromJson(Map<String, dynamic> json) => TravelDeparture(
    at: json['at'] != null ? DateTime.parse(json['at']) : DateTime.now(),
    from: json['from'] ?? '',
    fromLat: json['fromLat']?.toDouble(),
    fromLng: json['fromLng']?.toDouble(),
    mode: json['mode'] ?? 'bus',
    flightNumber: json['flightNumber'],
    terminal: json['terminal'],
  );

  String get modeLabel {
    switch (mode) {
      case 'flight': return 'Vol';
      case 'bus': return 'Bus';
      case 'train': return 'Train';
      case 'car': return 'Voiture';
      default: return mode;
    }
  }

  IconData get modeIcon {
    switch (mode) {
      case 'flight': return Icons.flight;
      case 'bus': return Icons.directions_bus;
      case 'train': return Icons.train;
      case 'car': return Icons.directions_car;
      default: return Icons.directions;
    }
  }
}

class TravelReturn {
  final DateTime at;
  final String? from;
  final String? flightNumber;

  TravelReturn({required this.at, this.from, this.flightNumber});

  factory TravelReturn.fromJson(Map<String, dynamic> json) => TravelReturn(
    at: json['at'] != null ? DateTime.parse(json['at']) : DateTime.now(),
    from: json['from'],
    flightNumber: json['flightNumber'],
  );
}

class TravelHotel {
  final String name;
  final String address;
  final String? phone;
  final String? website;
  final double? lat;
  final double? lng;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<HotelRoom> rooms;

  TravelHotel({
    required this.name, required this.address, this.phone, this.website,
    this.lat, this.lng,
    required this.checkIn, required this.checkOut, required this.rooms,
  });

  factory TravelHotel.fromJson(Map<String, dynamic> json) => TravelHotel(
    name: json['name'] ?? 'Hôtel non spécifié',
    address: json['address'] ?? '',
    phone: json['phone'],
    website: json['website'],
    lat: json['lat']?.toDouble(),
    lng: json['lng']?.toDouble(),
    checkIn: json['checkIn'] != null ? DateTime.parse(json['checkIn']) : DateTime.now(),
    checkOut: json['checkOut'] != null ? DateTime.parse(json['checkOut']) : DateTime.now(),
    rooms: (json['rooms'] as List? ?? [])
        .map((r) => HotelRoom.fromJson(r)).toList(),
  );

  int get singleRooms => rooms.where((r) => r.type == 'single').length;
  int get doubleRooms => rooms.where((r) => r.type == 'double').length;
  int get suiteRooms => rooms.where((r) => r.type == 'suite').length;
}

class HotelRoom {
  final String roomNumber;
  final String type; // 'single' | 'double' | 'suite'
  final String? occupant1Id;
  final String? occupant1Name;
  final String? occupant2Id;
  final String? occupant2Name;
  final bool isStaffRoom;

  HotelRoom({
    required this.roomNumber, required this.type,
    this.occupant1Id, this.occupant1Name,
    this.occupant2Id, this.occupant2Name,
    this.isStaffRoom = false,
  });

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    String? getName(dynamic obj) {
      if (obj is Map) {
        if (obj['fullName'] != null) return obj['fullName'];
        if (obj['firstName'] != null && obj['lastName'] != null) return '${obj['firstName']} ${obj['lastName']}';
        if (obj['name'] != null) return obj['name'];
      }
      return null;
    }

    return HotelRoom(
      roomNumber: json['roomNumber'] ?? '',
      type: json['type'] ?? 'single',
      occupant1Id: json['occupant1'] is Map ? json['occupant1']['_id'] : json['occupant1'],
      occupant1Name: getName(json['occupant1']),
      occupant2Id: json['occupant2'] is Map ? json['occupant2']['_id'] : json['occupant2'],
      occupant2Name: getName(json['occupant2']),
      isStaffRoom: json['isStaffRoom'] ?? false,
    );
  }
}

class TravelParticipants {
  final List<ParticipantInfo> players;
  final List<ParticipantInfo> staff;

  TravelParticipants({required this.players, required this.staff});

  factory TravelParticipants.fromJson(Map<String, dynamic> json) => TravelParticipants(
    players: (json['players'] as List? ?? [])
        .map((p) => ParticipantInfo.fromJson(p)).toList(),
    staff: (json['staff'] as List? ?? [])
        .map((s) => ParticipantInfo.fromJson(s)).toList(),
  );
}

class ParticipantInfo {
  final String id;
  final String name;
  final String? position;
  final String? photo;
  final int? jerseyNumber;

  ParticipantInfo({required this.id, required this.name, this.position, this.photo, this.jerseyNumber});

  factory ParticipantInfo.fromJson(dynamic json) {
    if (json == null) return ParticipantInfo(id: '', name: '');
    if (json is String) return ParticipantInfo(id: json, name: '');
    if (json is Map) {
      return ParticipantInfo(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        position: json['position'],
        photo: json['photo'],
        jerseyNumber: json['jerseyNumber'],
      );
    }
    return ParticipantInfo(id: '', name: '');
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class AirportInfo {
  final String code;
  final String name;
  final double? lat;
  final double? lng;

  AirportInfo({required this.code, required this.name, this.lat, this.lng});

  factory AirportInfo.fromJson(Map<String, dynamic> json) => AirportInfo(
    code: json['code'] ?? 'N/A',
    name: json['name'] ?? '',
    lat: json['lat']?.toDouble(),
    lng: json['lng']?.toDouble(),
  );
}
