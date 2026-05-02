import 'dart:async';
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
    if (userId.isEmpty) {
      _error = "ID Joueur manquant";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ajout d'un timeout de 10 secondes
      final result = await _apiService.getPlayerProfile(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'success': false, 'message': 'Le serveur ne répond pas (Timeout)'},
      );

      if (result['success']) {
        final data = result['payload'];
        
        final profileData = data['profile'] ?? data;
        if (profileData != null && profileData is Map<String, dynamic>) {
          _currentProfile = GamificationProfile.fromJson(profileData);
        }

        final actionsData = data['recentActions'];
        if (actionsData != null && actionsData is List) {
          _recentActions = actionsData
              .map((a) => ActionLog.fromJson(a))
              .toList();
        } else {
          _recentActions = [];
        }
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
      print('GamificationProvider Error: $e');
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
      final result = await _apiService.getLeaderboard().timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'success': false, 'message': 'Timeout'},
      );
      
      if (result['success']) {
        _leaderboard = result['payload'] ?? [];
      }
    } catch (e) {
      print('Leaderboard Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
