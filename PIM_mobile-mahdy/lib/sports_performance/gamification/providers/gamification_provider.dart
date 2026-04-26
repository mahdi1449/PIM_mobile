import 'package:flutter/material.dart';
import '../../../services/gamification_service.dart';
import '../models/gamification_models.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _apiService = GamificationService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  GamificationProfile? _currentProfile;
  GamificationProfile? get currentProfile => _currentProfile;

  List<ActionLog> _recentActions = [];
  List<ActionLog> get recentActions => _recentActions;

  List<dynamic> _leaderboard = [];
  List<dynamic> get leaderboard => _leaderboard;

  String? _error;
  String? get error => _error;

  // Charger le profil d'un joueur
  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getPlayerProfile(userId);
      if (result['success']) {
        final data = result['data'];
        
        // Mapper le profil
        if (data['profile'] != null) {
          _currentProfile = GamificationProfile.fromJson(data['profile']);
        }

        // Mapper les actions récentes
        if (data['recentActions'] != null) {
          _recentActions = (data['recentActions'] as List)
              .map((a) => ActionLog.fromJson(a))
              .toList();
        }
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Erreur lors du chargement du profil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger le classement
  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.getLeaderboard();
      if (result['success']) {
        _leaderboard = result['data'];
      }
    } catch (e) {
      _error = 'Erreur lors du chargement du classement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
