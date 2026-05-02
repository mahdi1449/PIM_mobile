import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/event.dart';
import '../models/match_live_event.dart';

class EventsProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Event> _events = [];
  Event? _selectedEvent;
  Map<String, List<Event>> _calendarEvents = {};
  List<EventParticipant> _participants = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _matchSheet;
  List<MatchLiveEvent> _liveEvents = [];
  Map<String, dynamic>? _weatherPreview;
  Map<String, dynamic>? _presenceStats;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  Map<String, List<Event>> get calendarEvents => _calendarEvents;
  List<EventParticipant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get matchSheet => _matchSheet;
  List<MatchLiveEvent> get liveEvents => _liveEvents;
  Map<String, dynamic>? get weatherPreview => _weatherPreview;
  Map<String, dynamic>? get presenceStats => _presenceStats;

  void selectEvent(Event? e) {
    _selectedEvent = e;
    notifyListeners();
  }

  Future<void> fetchEvents({
    String? eventType,
    String? teamId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (eventType != null) params['eventType'] = eventType;
      if (teamId != null) params['teamId'] = teamId;
      if (status != null) params['status'] = status;

      final data = await _api.get('/events', queryParams: params);

      if (data is Map && data['data'] != null && data['data']['events'] != null) {
        _events = (data['data']['events'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else if (data is Map && data['data'] is List) {
        _events = (data['data'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else if (data is List) {
        _events = data.map((e) => Event.fromJson(e)).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement des événements';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCalendar(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/events/calendar', queryParams: {
        'startDate': startDate.toIso8601String().split('T').first,
        'endDate': endDate.toIso8601String().split('T').first,
      });

      _calendarEvents = {};
      
      if (data is Map && data['data'] != null && data['data']['calendar'] != null) {
        final calendarMap = data['data']['calendar'] as Map;
        for (var dateKey in calendarMap.keys) {
          final items = calendarMap[dateKey];
          if (items is List) {
            for (var e in items) {
              try {
                final event = Event.fromJson(e);
                final key = '${event.startDate.year}-${event.startDate.month.toString().padLeft(2, '0')}-${event.startDate.day.toString().padLeft(2, '0')}';
                if (_calendarEvents[key] == null) _calendarEvents[key] = [];
                _calendarEvents[key]!.add(event);
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getTeamStats(String id) async {
    try {
      final response = await _api.get('/events/$id/team-stats');
      if (response is Map && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching team stats: $e');
      return null;
    }
  }

  Future<void> fetchEvent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/events/$id');
      if (data is Map && data['data'] != null) {
        _selectedEvent = Event.fromJson(data['data']);
      } else {
        _selectedEvent = Event.fromJson(data);
      }
    } catch (e) {
      _error = 'Erreur lors du chargement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/events', body: eventData);
      await fetchEvents();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      await _api.put('/events/$id', body: eventData);
      await fetchEvents();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _api.delete('/events/$id');
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchParticipants(String eventId) async {
    try {
      final data = await _api.get('/events/$eventId/participants');
      if (data is Map && data['data'] != null && data['data']['participants'] is List) {
        _participants = (data['data']['participants'] as List)
            .map((p) => EventParticipant.fromJson(p))
            .toList();
      } else if (data is Map && data['participants'] is List) {
        _participants = (data['participants'] as List)
            .map((p) => EventParticipant.fromJson(p))
            .toList();
      } else if (data is List) {
        _participants =
            data.map((p) => EventParticipant.fromJson(p)).toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateEventStatus(String id, String status) async {
    try {
      await _api.patch('/events/$id/status', body: {'status': status});
      await fetchEvents();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  List<Event> getEventsForDay(DateTime day) {
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _calendarEvents[key] ?? [];
  }

  // ─── Convocations ─────────────────────────────────────────────────────────
  Future<bool> sendConvocations(String eventId, List<String> playerIds, {String? meetingTime, String? requiredKit}) async {
    try {
      await _api.post('/events/$eventId/convocations', body: {
        'playerIds': playerIds,
        'details': {
          'meetingTime': meetingTime,
          'requiredKit': requiredKit,
        },
      });
      await fetchParticipants(eventId);
      return true;
    } catch (e) {
      _error = 'Échec de l\'envoi des convocations';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchWeatherPreviewData(String location) async {
    try {
      final data = await _api.get('/events/weather-preview', queryParams: {'location': location});
      if (data is Map && data['data'] != null) {
        return data['data'];
      }
      return data is Map ? data as Map<String, dynamic> : null;
    } catch (_) {
      return null;
    }
  }

  // ─── Match Sheet ──────────────────────────────────────────────────────────
  Future<void> fetchMatchSheet(String eventId) async {
    try {
      final data = await _api.get('/events/$eventId/match-sheet');
      _matchSheet = data['data'] ?? data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> saveMatchSheet(String eventId, Map<String, dynamic> sheetData) async {
    try {
      await _api.patch('/events/$eventId/match-sheet', body: sheetData);
      await fetchMatchSheet(eventId);
      return true;
    } catch (e) {
      _error = 'Échec de la sauvegarde de la feuille de match';
      notifyListeners();
      return false;
    }
  }

  // ─── Live Events ──────────────────────────────────────────────────────────
  Future<void> fetchLiveEvents(String eventId) async {
    try {
      final data = await _api.get('/events/$eventId/live-events');
      List<dynamic> list = [];
      if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      }
      _liveEvents = list.map((e) => MatchLiveEvent.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addLiveEvent(String eventId, Map<String, dynamic> eventData) async {
    try {
      await _api.post('/events/$eventId/live-events', body: eventData);
      await fetchLiveEvents(eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Match Result ─────────────────────────────────────────────────────────
  Future<bool> setMatchResult(String eventId, int home, int away, {int? duration, bool? isHome}) async {
    try {
      await _api.patch('/events/$eventId/result', body: {
        'homeScore': home,
        'awayScore': away,
        'matchDuration': duration,
        'isHome': isHome,
      });
      await fetchEvent(eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Weather State ───────────────────────────────────────────────────────
  Future<void> fetchWeatherPreview(String location) async {
    try {
      final data = await _api.get('/events/weather-preview', queryParams: {'location': location});
      _weatherPreview = data['data'] ?? data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> respondToConvocation(String eventId, String participantId, String status) async {
    try {
      await _api.patch('/events/$eventId/convocations/$participantId/respond', body: {
        'status': status,
      });
      await fetchEvent(eventId);
      await fetchParticipants(eventId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur lors de la réponse';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchPresenceReport(String eventId) async {
    try {
      final data = await _api.get('/events/$eventId/presence-report');
      _presenceStats = data['data'] ?? data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateParticipantStatus(String eventId, String participantId, String status) async {
    try {
      await _api.patch('/events/$eventId/participants/$participantId/status', body: {
        'status': status,
      });
      await fetchParticipants(eventId);
      await fetchPresenceReport(eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveBulkPlayerStats(String eventId, List<Map<String, dynamic>> stats) async {
    try {
      await _api.patch('/events/$eventId/bulk-player-stats', body: {
        'stats': stats,
      });
      await fetchParticipants(eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTeamStats(String eventId, Map<String, dynamic> data) async {
    try {
      await _api.patch('/events/$eventId/team-stats', body: data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
