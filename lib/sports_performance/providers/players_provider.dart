import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../services/api_client.dart';
import '../services/players_service.dart';

/// Fournit une instance partagée de [ApiClient] à tous les providers.
final apiClientProvider = Provider((ref) => ApiClient());

/// Fournit une instance de [PlayersService] réutilisant le [ApiClient] global.
final playersServiceProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return PlayersService(apiClient);
});

/// Provider qui récupère la liste complète des joueurs actifs du club.
final playersProvider = FutureProvider<List<Player>>((ref) async {
  final service = ref.read(playersServiceProvider);
  return service.getPlayers();
});

/// Provider qui récupère le profil d'un joueur unique par son ID.
final playerProvider =
    FutureProvider.family<Player, String>((ref, playerId) async {
  final service = ref.read(playersServiceProvider);
  return service.getPlayer(playerId);
});

/// Provider de formulaire gérant les opérations d'écriture sur les joueurs (création, modification, suppression).
final playerFormProvider =
    StateNotifierProvider<PlayerFormNotifier, AsyncValue<Player?>>((ref) {
  final service = ref.read(playersServiceProvider);
  return PlayerFormNotifier(service, ref);
});

/// Notifier qui gère les mutations de joueurs et invalide les caches Riverpod après chaque opération.
class PlayerFormNotifier extends StateNotifier<AsyncValue<Player?>> {
  final PlayersService _service;
  final Ref _ref;

  PlayerFormNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  /// Crée un nouveau joueur et rafraîchit la liste globale.
  Future<Player?> createPlayer(Player player) async {
    state = const AsyncValue.loading();
    try {
      final createdPlayer = await _service.createPlayer(player);
      state = AsyncValue.data(createdPlayer);
      _ref.invalidate(playersProvider); // Refresh the list
      return createdPlayer;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Met à jour un joueur existant et rafraîchit le cache global et celui du joueur spécifique.
  Future<Player?> updatePlayer(String id, Player player) async {
    state = const AsyncValue.loading();
    try {
      final updatedPlayer = await _service.updatePlayer(id, player);
      state = AsyncValue.data(updatedPlayer);
      _ref.invalidate(playersProvider); // Refresh the list
      _ref.invalidate(playerProvider(id)); // Refresh specific player
      return updatedPlayer;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Supprime un joueur et rafraîchit la liste de l'effectif.
  Future<bool> deletePlayer(String id) async {
    try {
      await _service.deletePlayer(id);
      _ref.invalidate(playersProvider); // Refresh the list
      return true;
    } catch (e) {
      return false;
    }
  }
}
