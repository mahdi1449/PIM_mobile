import 'package:flutter/material.dart';
import '../models/cognitive_session.dart';
import '../services/cognitive_lab_service.dart';
import '../../services/api_client.dart';

/// Provider ChangeNotifier pour le Laboratoire Cognitif.
/// Gère l'état de la dernière session, du score de référence (baseline) et de
/// la vue d'équipe pour détecter les joueurs en état de fatigue mentale critique.
class CognitiveLabProvider with ChangeNotifier {
  final CognitiveLabService _service = CognitiveLabService(ApiClient());

  /// Indique si un chargement est en cours.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Dernière session cognitive enregistrée pour le joueur courant.
  CognitiveSession? _latestSession;
  CognitiveSession? get latestSession => _latestSession;

  /// Score de référence (baseline) du joueur, calculé sur les premières sessions.
  Map<String, dynamic>? _baseline;
  Map<String, dynamic>? get baseline => _baseline;

  /// Historique des sessions cognitives du joueur.
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => _history;

  /// Résumé de l'état cognitif global de l'équipe du jour.
  Map<String, dynamic> _squadSummary = {};
  Map<String, dynamic> get squadSummary => _squadSummary;

  /// Liste des joueurs dont le score cognitif est en dessous du seuil d'alerte.
  List<dynamic> _atRiskPlayers = [];
  List<dynamic> get atRiskPlayers => _atRiskPlayers;

  /// Toutes les sessions du jour pour l'équipe.
  List<dynamic> _allSessions = [];
  List<dynamic> get allSessions => _allSessions;

  /// Charge le tableau de bord cognitif d'un joueur.
  /// Reconstruit la session la plus récente avec les informations du joueur injectées.
  /// Si le joueur est nouveau (aucune session), crée un squelette de session.
  Future<void> fetchDashboard(String playerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getDashboard(playerId);

      if (data['latestSession'] != null) {
        final sessionMap = Map<String, dynamic>.from(data['latestSession']);
        sessionMap['playerInfo'] = data['playerInfo']; // Inject identities
        _latestSession = CognitiveSession.fromJson(sessionMap);
      } else if (data['playerInfo'] != null) {
        // Skeleton session for new players
        _latestSession = CognitiveSession.fromJson({
          'playerId': playerId,
          'playerInfo': data['playerInfo'],
        });
      } else {
        _latestSession = null;
      }

      _baseline = data['baseline'];
      if (data['history'] != null) {
        _history = List<Map<String, dynamic>>.from(data['history']);
      }
    } catch (e) {
      print('Error fetching dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge la vue d'équipe : résumé global, joueurs à risque et toutes les sessions du jour.
  Future<void> fetchSquadOverview() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getSquadOverview();
      _squadSummary = data['summary'] ?? {};
      _atRiskPlayers = data['atRiskPlayers'] ?? [];
      _allSessions = data['allSessions'] ?? [];
    } catch (e) {
      print('Error fetching squad overview: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Soumet une nouvelle session cognitive et met à jour l'état local immédiatement.
  /// Déclenche aussi un rechargement complet du dashboard pour mettre à jour la baseline.
  Future<CognitiveSession?> submitSession(Map<String, dynamic> sessionData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _service.createSession(sessionData);

      // Update local state immediately with the result
      _latestSession = session;

      // Also trigger a full refresh to get baseline and history updated
      await fetchDashboard(sessionData['playerId']);

      return session;
    } catch (e) {
      print('Error submitting session: $e');
      rethrow; // Rethrow to let UI handle the error message
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
