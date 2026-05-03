import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../communication/models/communication_models.dart';
import '../../config/app_config.dart';
import '../models/user_management_models.dart';

class UserManagementApi {
  UserManagementApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    return AppConfig.apiBaseUrl;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
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
      _buildUri(path),
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

  Future<Map<String, dynamic>> _getObject(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await _client.get(
      _buildUri(path, query),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
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
      teamId: user['teamId']?.toString(),
      clubName: user['clubName']?.toString(),
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

  Future<List<ClubModel>> getAllClubs(String token) async {
    final list = await _getList('/clubs', token: token);
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

  Future<AuditLogsPage> getAuditLogs(
    String token, {
    String? keyword,
    String? userId,
    String? clubId,
    String? action,
    String? module,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 25,
  }) async {
    final data = await _getObject(
      '/audit/logs',
      token: token,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        if (clubId != null && clubId.trim().isNotEmpty) 'clubId': clubId.trim(),
        if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
        if (module != null && module.trim().isNotEmpty) 'module': module.trim(),
        if (entityType != null && entityType.trim().isNotEmpty)
          'entityType': entityType.trim(),
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
    return AuditLogsPage.fromJson(data);
  }

  Future<AuditStatsModel> getAuditStats(String token) async {
    final data = await _getObject('/audit/stats', token: token);
    return AuditStatsModel.fromJson(data);
  }

  Future<List<ChatUserModel>> getChatUsers(
    String token, {
    String? search,
  }) async {
    final response = await _client.get(
      _buildUri('/conversations/users', {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decoded = _decodeDynamic(response);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ChatUserModel.fromJson)
        .toList();
  }

  Future<List<ConversationModel>> getConversations(
    String token, {
    String? search,
    String? type,
    int page = 1,
    int limit = 30,
  }) async {
    final data = await _getObject(
      '/conversations',
      token: token,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final items = (data['items'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
        .toList();
  }

  Future<ConversationModel> createDirectConversation(
    String token,
    String targetUserId,
  ) async {
    final data = await _post('/conversations/private', {
      'targetUserId': targetUserId,
    }, token: token);
    return ConversationModel.fromJson(data);
  }

  Future<ConversationModel> createGroupConversation({
    required String token,
    required List<String> participantIds,
    String? title,
    String? teamId,
  }) async {
    final uniqueParticipantIds = participantIds.toSet().toList();
    final data = await _post('/conversations/group', {
      'participantIds': uniqueParticipantIds,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (teamId != null && teamId.trim().isNotEmpty) 'teamId': teamId.trim(),
    }, token: token);
    return ConversationModel.fromJson(data);
  }

  Future<List<ChatMessageModel>> getMessages(
    String token,
    String conversationId, {
    int limit = 40,
    DateTime? before,
  }) async {
    final data = await _getObject(
      '/messages/$conversationId',
      token: token,
      query: {
        'limit': '$limit',
        if (before != null) 'before': before.toIso8601String(),
      },
    );

    final items = (data['items'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();
  }

  Future<ChatMessageModel> sendChatMessage({
    required String token,
    required String conversationId,
    String? text,
    UploadedDocumentModel? file,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedText = text?.trim() ?? '';
    if (normalizedText.isEmpty && file == null) {
      throw Exception('Message content cannot be empty');
    }

    final payload = <String, dynamic>{};
    if (file != null) {
      payload['content'] = file.url;
      payload['type'] = 'file';
      payload['metadata'] = <String, dynamic>{...?metadata, ...file.toJson()};
    } else {
      payload['content'] = normalizedText;
      payload['type'] = 'text';
      if (metadata != null) {
        payload['metadata'] = metadata;
      }
    }
    final data = await _post(
      '/messages/$conversationId',
      payload,
      token: token,
    );
    return ChatMessageModel.fromJson(data);
  }

  Future<void> registerCallPushToken({
    required String token,
    required String pushToken,
    String? platform,
    String? deviceId,
  }) async {
    await _post('/calls/push-token', {
      'token': pushToken,
      if (platform != null && platform.trim().isNotEmpty)
        'platform': platform.trim(),
      if (deviceId != null && deviceId.trim().isNotEmpty)
        'deviceId': deviceId.trim(),
    }, token: token);
  }

  Future<void> removeCallPushToken({
    required String token,
    required String pushToken,
  }) async {
    await _post('/calls/push-token/remove', {'token': pushToken}, token: token);
  }

  Future<Map<String, dynamic>> issueCallToken({
    required String token,
    required String callId,
  }) async {
    return _post('/calls/token', {'callId': callId}, token: token);
  }

  Future<void> deleteChatMessage({
    required String token,
    required String messageId,
    required String scope,
  }) async {
    throw Exception('Delete message is not available on the new messaging API');
  }

  io.Socket connectMessagingSocket({
    required String token,
    void Function()? onConnect,
    void Function(dynamic error)? onConnectError,
    void Function(dynamic reason)? onDisconnect,
  }) {
    final socket = io.io(
      '${AppConfig.baseUrl}/messaging',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(999999)
          .enableForceNew()
          .build(),
    );

    if (onConnect != null) {
      socket.onConnect((_) => onConnect());
    }
    if (onConnectError != null) {
      socket.onConnectError(onConnectError);
    }
    if (onDisconnect != null) {
      socket.onDisconnect(onDisconnect);
    }

    return socket;
  }

  io.Socket connectWebrtcSocket({
    required String token,
    void Function()? onConnect,
    void Function(dynamic error)? onConnectError,
    void Function(dynamic reason)? onDisconnect,
  }) {
    final socket = io.io(
      '${AppConfig.baseUrl}/webrtc',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(999999)
          .enableForceNew()
          .build(),
    );

    if (onConnect != null) {
      socket.onConnect((_) => onConnect());
    }
    if (onConnectError != null) {
      socket.onConnectError(onConnectError);
    }
    if (onDisconnect != null) {
      socket.onDisconnect(onDisconnect);
    }

    return socket;
  }

  io.Socket connectAuditSocket({
    required String token,
    void Function()? onConnect,
    void Function(dynamic error)? onConnectError,
    void Function(dynamic reason)? onDisconnect,
    void Function(AuditLogModel log)? onAuditLogCreated,
  }) {
    final socket = io.io(
      '${AppConfig.baseUrl}/audit',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(999999)
          .enableForceNew()
          .build(),
    );

    if (onConnect != null) {
      socket.onConnect((_) => onConnect());
    }
    if (onConnectError != null) {
      socket.onConnectError(onConnectError);
    }
    if (onDisconnect != null) {
      socket.onDisconnect(onDisconnect);
    }
    if (onAuditLogCreated != null) {
      socket.on('audit_log_created', (payload) {
        if (payload is Map) {
          onAuditLogCreated(
            AuditLogModel.fromJson(Map<String, dynamic>.from(payload)),
          );
        }
      });
    }

    return socket;
  }

  Future<void> sendAnnouncement({
    required String token,
    required String title,
    required String text,
    List<String>? targetUserIds,
    List<String>? targetRoles,
  }) async {
    List<String> participantIds = [];

    if (targetUserIds != null && targetUserIds.isNotEmpty) {
      participantIds = targetUserIds.toSet().toList();
    } else {
      final users = await getChatUsers(token, search: null);
      final roleSet = targetRoles?.map((role) => role.toUpperCase()).toSet();
      participantIds = users
          .where(
            (user) =>
                roleSet == null || roleSet.contains(user.role.toUpperCase()),
          )
          .map((user) => user.id)
          .toSet()
          .toList();
    }

    if (participantIds.isEmpty) {
      throw Exception('No recipients found for announcement');
    }

    final conversation = await createGroupConversation(
      token: token,
      participantIds: participantIds,
      title: title,
    );

    await sendChatMessage(
      token: token,
      conversationId: conversation.id,
      text: text,
      metadata: {'announcement': true, 'title': title},
    );
  }

  Future<List<NotificationModel>> getNotifications(
    String token, {
    bool unreadOnly = false,
    String? type,
    int limit = 80,
  }) async {
    final response = await _client.get(
      _buildUri('/notifications', {
        'unreadOnly': unreadOnly.toString(),
        'limit': '$limit',
        if (type != null && type.isNotEmpty) 'type': type,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final decoded = _decodeDynamic(response);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<void> markNotificationsRead(
    String token,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) {
      return;
    }
    await _post('/notifications/mark-read', {
      'notificationIds': notificationIds,
    }, token: token);
  }

  Future<void> deleteNotification(String token, String notificationId) async {
    await _delete('/notifications/$notificationId', token: token);
  }

  Future<void> createEmergencyNotification({
    required String token,
    required String title,
    required String body,
    String severity = 'HIGH',
    List<String>? targetUserIds,
    List<String>? targetRoles,
  }) async {
    await _post('/notifications/emergency', {
      'title': title,
      'body': body,
      'severity': severity,
      if (targetUserIds != null && targetUserIds.isNotEmpty)
        'targetUserIds': targetUserIds,
      if (targetRoles != null && targetRoles.isNotEmpty)
        'targetRoles': targetRoles,
    }, token: token);
  }

  Future<void> createMedicalAlert({
    required String token,
    required String title,
    required String body,
    required List<String> targetPlayerIds,
    String severity = 'MEDIUM',
    bool includeCoaches = true,
    bool includeResponsables = false,
    bool confidential = true,
  }) async {
    await _post('/notifications/medical-alert', {
      'title': title,
      'body': body,
      'severity': severity,
      'targetPlayerIds': targetPlayerIds,
      'includeCoaches': includeCoaches,
      'includeResponsables': includeResponsables,
      'confidential': confidential,
    }, token: token);
  }

  Future<void> createTrainingReminder({
    required String token,
    required String title,
    required String body,
    required DateTime scheduleAt,
    List<String>? targetUserIds,
    List<String>? targetRoles,
    String? trainingId,
  }) async {
    await _post('/notifications/training-reminder', {
      'title': title,
      'body': body,
      'scheduleAt': scheduleAt.toIso8601String(),
      if (trainingId != null && trainingId.isNotEmpty) 'trainingId': trainingId,
      if (targetUserIds != null && targetUserIds.isNotEmpty)
        'targetUserIds': targetUserIds,
      if (targetRoles != null && targetRoles.isNotEmpty)
        'targetRoles': targetRoles,
    }, token: token);
  }

  Future<UploadedDocumentModel> uploadDocument({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri('/uploads'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final data = _decode(response);
    return UploadedDocumentModel.fromJson(data);
  }

  Stream<Map<String, dynamic>> subscribeSse({
    required String token,
    required String path,
  }) async* {
    final request = http.Request('GET', _buildUri(path));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });

    final streamed = await _client.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Failed to open stream on $path');
    }

    await for (final line
        in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) {
        continue;
      }
      final raw = line.replaceFirst('data:', '').trim();
      if (raw.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      } catch (_) {
        // ignore malformed stream lines
      }
    }
  }

  dynamic _decodeDynamic(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    }
    throw Exception(_extractError(response));
  }
}
