import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_management_models.dart';

class UserManagementApi {
  UserManagementApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) {
      return env;
    }
    return kIsWeb ? 'http://localhost:3001/api' : 'http://10.0.2.2:3001/api';
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> payload, {
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    required String token,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  Future<List<dynamic>> _getList(String path, {String? token}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      return [];
    }

    throw Exception(_extractError(response));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    throw Exception(_extractError(response));
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // ignore
    }
    return 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
  }

  Future<SessionModel> login(String email, String password) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final user = (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{});

    return SessionModel(
      token: (data['accessToken'] ?? '').toString(),
      userId: (user['sub'] ?? '').toString(),
      role: (user['role'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      status: (user['status'] ?? '').toString(),
      clubId: user['clubId']?.toString(),
      firstName: user['firstName']?.toString(),
      lastName: user['lastName']?.toString(),
      photoUrl: user['photoUrl']?.toString(),
    );
  }

  Future<void> registerResponsable(Map<String, dynamic> payload) async {
    await _post('/auth/register/responsable', payload);
  }

  Future<void> registerMember(Map<String, dynamic> payload) async {
    await _post('/auth/register/member', payload);
  }

  Future<void> verifyEmail(String email, String code) async {
    await _post('/auth/verify-email', {'email': email, 'code': code});
  }

  Future<void> requestForgotPassword(String email) async {
    await _post('/auth/forgot-password/request', {'email': email});
  }

  Future<void> resetForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post('/auth/forgot-password/reset', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<List<ClubModel>> getActiveClubs() async {
    final list = await _getList('/clubs/active');
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClubModel.fromJson)
        .toList();
  }

  Future<List<ClubModel>> getPendingClubs(String token) async {
    final list = await _getList('/clubs/pending', token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClubModel.fromJson)
        .toList();
  }

  Future<void> approveClub(String token, String clubId, bool approve) async {
    await _patch('/clubs/$clubId/approval', {
      'status': approve ? 'ACTIVE' : 'REJECTED',
    }, token: token);
  }

  Future<List<UserModel>> getPendingUsers(String token) async {
    final list = await _getList('/users/pending', token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<void> approveUser(String token, String userId, bool approve) async {
    await _patch('/users/$userId/approval', {
      'status': approve ? 'ACTIVE' : 'REJECTED',
    }, token: token);
  }

  Future<UserModel> updateUser(
    String token,
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patch('/users/$userId', payload, token: token);
    return UserModel.fromJson(data);
  }

  Future<void> deleteUser(String token, String userId) async {
    await _delete('/users/$userId', token: token);
  }

  Future<List<UserModel>> getUsers(String token) async {
    final list = await _getList('/users', token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }
}
