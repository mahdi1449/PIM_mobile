import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/club.dart';

class ClubsProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  Club? _currentClub;
  bool _isLoading = false;
  String? _error;

  Club? get currentClub => _currentClub;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchClub(String clubId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/clubs/$clubId');
      if (data != null) {
        _currentClub = Club.fromJson(data);
      }
    } catch (e) {
      _error = 'Impossible de charger les infos du club';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateClub(String clubId, Map<String, dynamic> clubData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.patch('/clubs/$clubId', body: clubData);
      if (data != null) {
        _currentClub = Club.fromJson(data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
