import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/event_player.dart';
import '../services/api_client.dart';
import '../services/events_service.dart';

/// Fournit une instance singleton de [EventsService] à l'ensemble de l'arbre de widgets.
final eventsServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return EventsService(apiClient);
});

/// Provider Riverpod qui récupère la liste des événements sportifs.
/// Supporte des filtres de date et de statut via [EventsFilter].
/// `autoDispose` libère les ressources quand le widget qui l'écoute est détruit.
final eventsProvider = FutureProvider.autoDispose
    .family<List<Event>, EventsFilter?>((ref, filter) async {
  final service = ref.read(eventsServiceProvider);
  return service.getEvents(
    startDate: filter?.startDate,
    endDate: filter?.endDate,
    status: filter?.status,
  );
});

/// Modèle de filtre pour la récupération des événements.
class EventsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final EventStatus? status;

  EventsFilter({this.startDate, this.endDate, this.status});
}

/// Provider qui récupère les détails d'un événement unique, identifié par son ID.
final eventProvider =
    FutureProvider.family<Event, String>((ref, eventId) async {
  final service = ref.read(eventsServiceProvider);
  return service.getEvent(eventId);
});

/// Provider qui récupère la liste des participants (joueurs) d'un événement donné.
final eventPlayersProvider =
    FutureProvider.family<List<EventPlayer>, String>((ref, eventId) async {
  final service = ref.read(eventsServiceProvider);
  return service.getEventPlayers(eventId);
});

/// Provider de formulaire gérant les mutations d'événements (création, modification, clôture).
/// Utilise un [StateNotifier] pour exposer l'état async de chaque opération à l'UI.
final eventFormProvider =
    StateNotifierProvider<EventFormNotifier, AsyncValue<Event?>>((ref) {
  final service = ref.read(eventsServiceProvider);
  return EventFormNotifier(service, ref);
});

/// Notifier qui gère les opérations d'écriture sur les événements.
/// Invalide automatiquement les caches Riverpod concernés après chaque mutation.
class EventFormNotifier extends StateNotifier<AsyncValue<Event?>> {
  final EventsService _service;
  final Ref _ref;

  EventFormNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  /// Crée un événement et invalide la liste pour forcer un rechargement des données.
  Future<Event?> createEvent(Event event) async {
    state = const AsyncValue.loading();
    try {
      final createdEvent = await _service.createEvent(event);
      state = AsyncValue.data(createdEvent);
      // Invalidate events list
      _ref.invalidate(eventsProvider);
      return createdEvent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Met à jour un événement et invalide les caches de la liste et du détail.
  Future<Event?> updateEvent(String id, Event event) async {
    state = const AsyncValue.loading();
    try {
      final updatedEvent = await _service.updateEvent(id, event);
      state = AsyncValue.data(updatedEvent);
      _ref.invalidate(eventsProvider);
      _ref.invalidate(eventProvider(id));
      return updatedEvent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Clôture un événement (passage en statut final) et invalide les providers liés.
  Future<Event?> closeEvent(String id) async {
    state = const AsyncValue.loading();
    try {
      final closedEvent = await _service.closeEvent(id);
      state = AsyncValue.data(closedEvent);
      _ref.invalidate(eventsProvider);
      _ref.invalidate(eventProvider(id));
      return closedEvent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Ajoute un joueur à un événement et rafraîchit la liste des participants.
  Future<EventPlayer?> addPlayerToEvent(String eventId, String playerId) async {
    try {
      final eventPlayer = await _service.addPlayerToEvent(eventId, playerId);
      _ref.invalidate(eventPlayersProvider(eventId));
      return eventPlayer;
    } catch (e) {
      return null;
    }
  }

  /// Met à jour le statut de participation d'un joueur (présent, blessé, etc.).
  Future<EventPlayer?> updateEventPlayerStatus(
    String eventId,
    String playerId,
    ParticipationStatus status,
  ) async {
    try {
      final updatedPlayer = await _service.updateEventPlayer(
        eventId,
        playerId,
        status: status.value,
      );
      _ref.invalidate(eventPlayersProvider(eventId));
      return updatedPlayer;
    } catch (e) {
      return null;
    }
  }

  /// Retire un joueur d'un événement et rafraîchit la liste des participants.
  Future<bool> removePlayerFromEvent(String eventId, String playerId) async {
    try {
      await _service.removePlayerFromEvent(eventId, playerId);
      _ref.invalidate(eventPlayersProvider(eventId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprime un événement et invalide la liste pour mise à jour de l'UI.
  Future<bool> deleteEvent(String id) async {
    try {
      await _service.deleteEvent(id);
      _ref.invalidate(eventsProvider); // Refresh the list
      return true;
    } catch (e) {
      return false;
    }
  }
}
