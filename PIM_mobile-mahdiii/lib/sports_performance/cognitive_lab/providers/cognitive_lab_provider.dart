import 'package:flutter/material.dart';
import '../models/cognitive_session.dart';
import '../services/cognitive_lab_service.dart';
import '../../services/api_client.dart';

class CognitiveLabProvider with ChangeNotifier {
  final CognitiveLabService _service = CognitiveLabService(ApiClient());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CognitiveSession? _latestSession;
  CognitiveSession? get latestSession => _latestSession;

  Map<String, dynamic>? _baseline;
  Map<String, dynamic>? get baseline => _baseline;

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => _history;

  Map<String, dynamic> _squadSummary = {};
  Map<String, dynamic> get squadSummary => _squadSummary;

  List<dynamic> _atRiskPlayers = [];
  List<dynamic> get atRiskPlayers => _atRiskPlayers;

  Future<void> fetchDashboard(String playerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getDashboard(playerId);
      _latestSession = data['latestSession'] != null 
          ? CognitiveSession.fromJson(data['latestSession']) 
          : null;
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

  Future<void> fetchSquadOverview() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getSquadOverview();
      _squadSummary = data['summary'] ?? {};
      _atRiskPlayers = data['atRiskPlayers'] ?? [];
    } catch (e) {
      print('Error fetching squad overview: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CognitiveSession?> submitSession(Map<String, dynamic> sessionData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _service.createSession(sessionData);
      // Actualiser le tableau de bord avec l'historique complet apres le test
      await fetchDashboard(sessionData['playerId']);
      return session;
    } catch (e) {
      print('Error submitting session: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
