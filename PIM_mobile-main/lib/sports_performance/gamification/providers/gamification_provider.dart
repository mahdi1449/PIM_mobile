import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/gamification_service.dart';
import '../models/gamification_models.dart';

/// Provider ChangeNotifier qui gère l'état de la Gamification pour un joueur.
/// Il centralise le profil XP, l'historique d'actions, le classement et les achats boutique.
class GamificationProvider with ChangeNotifier {
  final GamificationService _apiService = GamificationService();

  /// Indique si une opération asynchrone est en cours (pour afficher les spinners UI).
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Profil de gamification courant contenant le niveau, l'XP et les badges du joueur.
  GamificationProfile? _currentProfile;
  GamificationProfile? get currentProfile => _currentProfile;

  /// Historique des dernières actions récompensées (entraînements, voyages, etc.).
  List<ActionLog> _recentActions = [];
  List<ActionLog> get recentActions => _recentActions;

  /// Classement global des joueurs par points XP.
  List<dynamic> _leaderboard = [];
  List<dynamic> get leaderboard => _leaderboard;

  /// Liste des achats boutique (pour la vue Admin).
  List<dynamic> _adminPurchases = [];
  List<dynamic> get adminPurchases => _adminPurchases;

  /// Message d'erreur affiché à l'utilisateur en cas d'échec d'une opération.
  String? _error;
  String? get error => _error;

  /// Charge le profil de gamification d'un joueur (XP, niveau, badges, historique).
  /// Inclut un timeout de 10s pour ne pas bloquer l'UI si le backend est lent.
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
      print('Fetching gamification profile for userId: $userId');
      final result = await _apiService.getPlayerProfile(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'success': false, 'message': 'Le serveur ne répond pas (Timeout)'},
      );

      print('API Result Success: ${result['success']}');
      if (result['success']) {
        final data = result['payload'];
        print('API Data received: $data');
        
        final profileData = data['profile'] ?? data;
        if (profileData != null && profileData is Map<String, dynamic>) {
          _currentProfile = GamificationProfile.fromJson(profileData);
          print('Profile parsed successfully: ${_currentProfile?.userId}');
        } else {
          print('Invalid profile data format: $profileData');
        }

        final actionsData = data['recentActions'];
        if (actionsData != null && actionsData is List) {
          _recentActions = actionsData
              .map((a) => ActionLog.fromJson(a))
              .toList();
          print('Actions parsed: ${_recentActions.length}');
        } else {
          _recentActions = [];
        }
      } else {
        _error = result['message'];
        print('API Error Message: $_error');
      }
    } catch (e, stack) {
      _error = 'Erreur lors du traitement des données.';
      print('GamificationProvider Exception: $e');
      print('Stacktrace: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge le classement global des joueurs par points XP accumulés.
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

  /// Échange des points XP contre un article de la boutique.
  /// Rafraîchit automatiquement le profil après un achat réussi pour mettre à jour le solde.
  Future<Map<String, dynamic>> redeemReward(String userId, String item, int points) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.redeemReward(
        userId: userId,
        item: item,
        points: points,
      );

      if (result['success']) {
        // Rafraîchir le profil et l'historique après l'achat
        await fetchProfile(userId);
        return {'success': true};
      } else {
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur lors de l\'achat'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge tous les achats effectués dans la boutique (vue réservée à l'administrateur).
  Future<void> fetchAdminPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.getAdminPurchases();
      if (result['success']) {
        _adminPurchases = result['payload'] ?? [];
      }
    } catch (e) {
      print('Admin Purchases Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
