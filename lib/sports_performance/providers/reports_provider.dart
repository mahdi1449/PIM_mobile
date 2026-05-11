import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_report.dart';
import '../models/player_report.dart';
import '../services/api_client.dart';
import '../services/reports_service.dart';

/// Fournit une instance de [ReportsService] à l'ensemble des providers de rapports.
final reportsServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return ReportsService(apiClient);
});

/// Provider qui récupère le rapport de synthèse d'un événement.
final eventReportProvider =
    FutureProvider.family<EventReport, String>((ref, eventId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getEventReport(eventId);
});

/// Provider qui récupère le rapport individuel d'un participant (EventPlayer).
final playerReportProvider =
    FutureProvider.family<PlayerReport, String>((ref, eventPlayerId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getPlayerReport(eventPlayerId);
});

/// Provider qui récupère le classement des joueurs par score normalisé pour un événement.
final eventRankingProvider =
    FutureProvider.family<List<RankedPlayer>, String>((ref, eventId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getEventRanking(eventId);
});

/// Provider qui identifie les meilleurs performeurs d'un événement.
final topPlayersProvider =
    FutureProvider.family<List<TopPlayer>, String>((ref, eventId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getTopPlayers(eventId);
});

/// Provider qui récupère la courbe de progression historique d'un joueur.
final playerProgressionProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, playerId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getPlayerProgression(playerId);
});

/// Provider d'état gérant la génération massive de rapports après un événement.
final reportGenerationProvider =
    StateNotifierProvider<ReportGenerationNotifier, AsyncValue<bool>>((ref) {
  final service = ref.read(reportsServiceProvider);
  return ReportGenerationNotifier(service, ref);
});

/// Notifier qui orchestre la génération de tous les rapports d'un événement.
/// Invalide automatiquement les caches liés (classement, top players, rapport) après génération.
class ReportGenerationNotifier extends StateNotifier<AsyncValue<bool>> {
  final ReportsService _service;
  final Ref _ref;

  ReportGenerationNotifier(this._service, this._ref)
      : super(const AsyncValue.data(false));

  /// Lance la génération de tous les rapports et rafraîchit les providers liés.
  Future<bool> generateAllReports(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _service.generateAllReports(eventId);
      state = const AsyncValue.data(true);
      
      // Invalidate all related providers
      _ref.invalidate(eventReportProvider(eventId));
      _ref.invalidate(eventRankingProvider(eventId));
      _ref.invalidate(topPlayersProvider(eventId));
      
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Réinitialise l'état de génération à `false` (pour réafficher le bouton de génération).
  void reset() {
    state = const AsyncValue.data(false);
  }
}
