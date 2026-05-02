import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/app_config.dart';
import '../../ui/components/empty_state.dart';
import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../communication_theme.dart';
import '../models/communication_models.dart';
import '../permissions.dart';
import 'call_screen.dart';
import 'chat_room_screen.dart';

enum _ConversationFilter { all, private, team, club }

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({
    super.key,
    required this.api,
    required this.session,
    this.onOpenNotifications,
    this.onLogout,
    this.embedded = false,
  });

  final UserManagementApi api;
  final SessionModel session;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onLogout;
  final bool embedded;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ChatUserModel> _users = [];
  List<ConversationModel> _conversations = [];
  final Set<String> _onlineUserIds = <String>{};
  bool _loading = true;
  String? _error;
  io.Socket? _socket;
  io.Socket? _webrtcSocket;
  final Set<String> _handledIncomingCallIds = <String>{};
  _ConversationFilter _filter = _ConversationFilter.all;

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscribeRealtime();
    _subscribeWebrtc();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _webrtcSocket?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        widget.api.getChatUsers(
          widget.session.token,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
        widget.api.getConversations(
          widget.session.token,
          type: _apiTypeFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = futures[0] as List<ChatUserModel>;
        _conversations = futures[1] as List<ConversationModel>;
        _onlineUserIds.removeWhere(
          (id) => !_users.any((user) => user.id == id),
        );
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribeRealtime() {
    _socket?.dispose();
    _socket = widget.api.connectMessagingSocket(
      token: widget.session.token,
      onConnect: _refresh,
    );

    _socket?.on('presence_snapshot', (payload) {
      if (!mounted || payload is! Map) {
        return;
      }
      _applyPresenceSnapshot(Map<String, dynamic>.from(payload));
    });

    _socket?.on('conversation_updated', (payload) {
      if (!mounted) {
        return;
      }
      if (payload is Map && payload['type'] == 'presence') {
        _applyPresenceUpdate(Map<String, dynamic>.from(payload));
        return;
      }
      _refresh();
    });

    _socket?.on('new_message', (payload) {
      if (!mounted) {
        return;
      }
      _showRealtimeMessageNotification(payload);
      _refresh();
    });
  }

  void _subscribeWebrtc() {
    _webrtcSocket?.dispose();
    _webrtcSocket = widget.api.connectWebrtcSocket(
      token: widget.session.token,
      onConnect: () {},
    );

    _webrtcSocket?.on('incoming_call', (payload) {
      if (!mounted) {
        return;
      }

      IncomingCallEvent event;
      try {
        event = IncomingCallEvent.fromSocket(payload);
      } catch (_) {
        return;
      }

      if (event.callId.isEmpty ||
          _handledIncomingCallIds.contains(event.callId)) {
        return;
      }

      _handledIncomingCallIds.add(event.callId);
      _presentIncomingCall(event);
    });
  }

  Future<void> _presentIncomingCall(IncomingCallEvent event) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CommunicationPalette.card(context),
          title: Text(
            'Incoming ${event.isVideo ? 'video' : 'audio'} call',
            style: CommunicationPalette.titleStyle(size: 20),
          ),
          content: Text(
            '${event.fromDisplayName} is calling you.',
            style: CommunicationPalette.bodyStyle(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (accepted != true) {
      _webrtcSocket?.emit('reject_call', {
        'callId': event.callId,
        'reason': 'rejected',
      });
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebrtcCallScreen.incoming(
          api: widget.api,
          session: widget.session,
          incomingEvent: event,
        ),
      ),
    );
  }

  void _applyPresenceSnapshot(Map<String, dynamic> payload) {
    final rawUsers = payload['onlineUserIds'];
    if (rawUsers is! List) {
      return;
    }

    final updated = rawUsers
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();

    if (!mounted) {
      return;
    }

    setState(() {
      _onlineUserIds
        ..clear()
        ..addAll(updated);
    });
  }

  void _applyPresenceUpdate(Map<String, dynamic> payload) {
    final userId = (payload['userId'] ?? '').toString().trim();
    final status = (payload['status'] ?? '').toString().trim().toLowerCase();
    if (userId.isEmpty || (status != 'online' && status != 'offline')) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (status == 'online') {
        _onlineUserIds.add(userId);
      } else {
        _onlineUserIds.remove(userId);
      }
    });
  }

  Future<void> _openDirect(ChatUserModel user) async {
    try {
      final conversation = await widget.api.createDirectConversation(
        widget.session.token,
        user.id,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            api: widget.api,
            session: widget.session,
            conversationId: conversation.id,
            title: conversation.displayTitle,
            peerUserId: user.id,
            peerDisplayName: user.displayName,
            conversationType: conversation.type,
            participantDisplayNames: <String, String>{
              if (widget.session.userId.isNotEmpty)
                widget.session.userId:
                    '${widget.session.firstName ?? ''} ${widget.session.lastName ?? ''}'
                        .trim(),
              user.id: user.displayName,
            },
          ),
        ),
      );

      _refresh();
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    }
  }

  Future<void> _openConversation(ConversationModel conversation) async {
    final peer = _resolvePeerInPrivateConversation(conversation);
    final participantDisplayNames = <String, String>{
      for (final participant in conversation.participants)
        participant.userId: '${participant.firstName} ${participant.lastName}'
            .trim(),
    };

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          api: widget.api,
          session: widget.session,
          conversationId: conversation.id,
          title: conversation.displayTitle,
          peerUserId: peer?.userId,
          peerDisplayName: peer == null
              ? null
              : '${peer.firstName} ${peer.lastName}'.trim(),
          conversationType: conversation.type,
          participantDisplayNames: participantDisplayNames,
        ),
      ),
    );

    _refresh();
  }

  ConversationParticipantModel? _resolvePeerInPrivateConversation(
    ConversationModel conversation,
  ) {
    if (conversation.type.toLowerCase() != 'private') {
      return null;
    }

    for (final participant in conversation.participants) {
      if (participant.userId != widget.session.userId) {
        return participant;
      }
    }

    return null;
  }

  String? _resolveMediaUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:')) {
      return value;
    }
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  String? _conversationAvatarUrl(ConversationModel conversation) {
    final peer = _resolvePeerInPrivateConversation(conversation);
    final peerUrl = _resolveMediaUrl(peer?.photoUrl);
    if (peerUrl != null) {
      return peerUrl;
    }

    for (final participant in conversation.participants) {
      if (participant.userId == widget.session.userId) {
        continue;
      }
      final url = _resolveMediaUrl(participant.photoUrl);
      if (url != null) {
        return url;
      }
    }

    return null;
  }

  Future<void> _openQuickActions() async {
    final role = widget.session.role;
    final choices = <String>['group'];
    if (CommunicationPermissions.canSendAnnouncement(role)) {
      choices.add('announcement');
      choices.add('training');
    }
    if (CommunicationPermissions.canSendMedicalAlert(role)) {
      choices.add('medical');
    }
    if (CommunicationPermissions.canSendEmergency(role)) {
      choices.add('emergency');
    }

    if (choices.isEmpty) {
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CommunicationPalette.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final textColor = CommunicationPalette.textPrimary(context);

        return SafeArea(
          child: Wrap(
            children: [
              if (choices.contains('group'))
                ListTile(
                  leading: const Icon(Icons.group_add_rounded),
                  title: Text(
                    'Create group conversation',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'group'),
                ),
              if (choices.contains('announcement'))
                ListTile(
                  leading: const Icon(Icons.campaign_rounded),
                  title: Text(
                    'Coach announcement',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'announcement'),
                ),
              if (choices.contains('training'))
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(
                    'Training reminder',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'training'),
                ),
              if (choices.contains('medical'))
                ListTile(
                  leading: const Icon(Icons.medical_information_rounded),
                  title: Text(
                    'Medical alert',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'medical'),
                ),
              if (choices.contains('emergency'))
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(
                    'Emergency notification',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'emergency'),
                ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case 'group':
        await _composeGroupConversation();
      case 'announcement':
        await _composeAnnouncement();
      case 'training':
        await _composeTrainingReminder();
      case 'medical':
        await _composeMedicalAlert();
      case 'emergency':
        await _composeEmergency();
      default:
        break;
    }
  }

  Future<void> _composeGroupConversation() async {
    if (_users.isEmpty) {
      _showInfo('No available members in this club yet');
      return;
    }

    final titleController = TextEditingController();
    final searchController = TextEditingController();
    final actorTeamId = widget.session.teamId;
    final selected = <String>{};
    var teamOnly = false;
    var search = '';

    final result = await showModalBottomSheet<_GroupComposerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final visibleUsers = _users.where((user) {
              if (teamOnly && actorTeamId != null && actorTeamId.isNotEmpty) {
                if (user.teamId != actorTeamId) {
                  return false;
                }
              }

              if (search.trim().isEmpty) {
                return true;
              }

              final q = search.toLowerCase();
              final name = '${user.firstName} ${user.lastName}'.toLowerCase();
              return name.contains(q) ||
                  user.role.toLowerCase().contains(q) ||
                  (user.email ?? '').toLowerCase().contains(q);
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: CommunicationPalette.card(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border.all(color: CommunicationPalette.border(context)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Group Conversation',
                      style: CommunicationPalette.titleStyle(size: 20),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      style: CommunicationPalette.bodyStyle(),
                      decoration: const InputDecoration(
                        hintText: 'Group title (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      style: CommunicationPalette.bodyStyle(),
                      onChanged: (value) {
                        setModalState(() => search = value);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    if (actorTeamId != null && actorTeamId.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Team-only group (my team)',
                              style: CommunicationPalette.bodyStyle(
                                color: CommunicationPalette.textMuted(context),
                              ),
                            ),
                          ),
                          Switch(
                            value: teamOnly,
                            onChanged: (value) {
                              setModalState(() {
                                teamOnly = value;
                                if (teamOnly) {
                                  selected.removeWhere((userId) {
                                    final user = _users.firstWhere(
                                      (candidate) => candidate.id == userId,
                                      orElse: () => ChatUserModel(
                                        id: '',
                                        firstName: '',
                                        lastName: '',
                                        role: '',
                                      ),
                                    );
                                    return user.id.isNotEmpty &&
                                        user.teamId != actorTeamId;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Select members (${selected.length})',
                      style: CommunicationPalette.bodyStyle(
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 320),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CommunicationPalette.border(context),
                          ),
                        ),
                        child: visibleUsers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Text(
                                    'No members found for this filter',
                                    style: CommunicationPalette.bodyStyle(
                                      color: CommunicationPalette.textMuted(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final user = visibleUsers[index];
                                  final checked = selected.contains(user.id);
                                  return CheckboxListTile(
                                    value: checked,
                                    activeColor: CommunicationPalette.primary,
                                    title: Text(
                                      user.displayName,
                                      style: CommunicationPalette.bodyStyle(),
                                    ),
                                    subtitle: Text(
                                      user.role,
                                      style: CommunicationPalette.bodyStyle(
                                        size: 12,
                                        color: CommunicationPalette.textMuted(
                                          context,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        if (value == true) {
                                          selected.add(user.id);
                                        } else {
                                          selected.remove(user.id);
                                        }
                                      });
                                    },
                                  );
                                },
                                separatorBuilder: (_, __) => Divider(
                                  color: CommunicationPalette.border(context),
                                  height: 1,
                                ),
                                itemCount: visibleUsers.length,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(
                                      context,
                                      _GroupComposerResult(
                                        title: titleController.text.trim(),
                                        participantIds: selected.toList(),
                                        teamOnly: teamOnly,
                                      ),
                                    );
                                  },
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      final created = await widget.api.createGroupConversation(
        token: widget.session.token,
        participantIds: result.participantIds,
        title: result.title.isEmpty ? null : result.title,
        teamId: result.teamOnly ? widget.session.teamId : null,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            api: widget.api,
            session: widget.session,
            conversationId: created.id,
            title: created.displayTitle,
            conversationType: created.type,
            participantDisplayNames: <String, String>{
              for (final user in _users)
                if (result.participantIds.contains(user.id))
                  user.id: user.displayName,
              if (widget.session.userId.isNotEmpty)
                widget.session.userId:
                    '${widget.session.firstName ?? ''} ${widget.session.lastName ?? ''}'
                        .trim(),
            },
          ),
        ),
      );
      _refresh();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeAnnouncement() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final approved = await _composeDialog(
      title: 'New announcement',
      titleController: titleController,
      bodyController: bodyController,
    );

    if (!approved) {
      return;
    }

    try {
      await widget.api.sendAnnouncement(
        token: widget.session.token,
        title: titleController.text.trim(),
        text: bodyController.text.trim(),
        targetRoles: const ['JOUEUR'],
      );
      _showInfo('Announcement sent');
      _refresh();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeEmergency() async {
    final titleController = TextEditingController(text: 'Emergency');
    final bodyController = TextEditingController();
    final approved = await _composeDialog(
      title: 'Emergency message',
      titleController: titleController,
      bodyController: bodyController,
    );
    if (!approved) {
      return;
    }

    try {
      await widget.api.createEmergencyNotification(
        token: widget.session.token,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        severity: 'HIGH',
      );
      _showInfo('Emergency notification sent');
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeMedicalAlert() async {
    final players = _users.where((u) => u.role == 'JOUEUR').toList();
    if (players.isEmpty) {
      _showInfo('No players available in this club');
      return;
    }

    final titleController = TextEditingController(text: 'Medical alert');
    final bodyController = TextEditingController();
    final approved = await _composeDialog(
      title: 'Medical alert',
      titleController: titleController,
      bodyController: bodyController,
    );
    if (!approved) {
      return;
    }

    try {
      await widget.api.createMedicalAlert(
        token: widget.session.token,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        targetPlayerIds: players.map((e) => e.id).toList(),
      );
      _showInfo('Medical alert sent');
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeTrainingReminder() async {
    final titleController = TextEditingController(text: 'Training reminder');
    final bodyController = TextEditingController();

    final approved = await _composeDialog(
      title: 'Training reminder',
      titleController: titleController,
      bodyController: bodyController,
    );
    if (!approved) {
      return;
    }

    try {
      await widget.api.createTrainingReminder(
        token: widget.session.token,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        scheduleAt: DateTime.now().add(const Duration(minutes: 2)),
        targetRoles: const ['JOUEUR'],
      );
      _showInfo('Training reminder scheduled');
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<bool> _composeDialog({
    required String title,
    required TextEditingController titleController,
    required TextEditingController bodyController,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final card = CommunicationPalette.card(context);
        final textColor = CommunicationPalette.textPrimary(context);
        return AlertDialog(
          backgroundColor: card,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    return confirmed == true &&
        titleController.text.trim().isNotEmpty &&
        bodyController.text.trim().isNotEmpty;
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String raw) {
    _showInfo(raw.replaceFirst('Exception: ', ''));
  }

  void _showRealtimeMessageNotification(dynamic payload) {
    if (payload is! Map) {
      _showInfo('New message received');
      return;
    }

    final payloadMap = Map<String, dynamic>.from(payload);
    final messageRaw = payloadMap['message'];
    if (messageRaw is! Map) {
      _showInfo('New message received');
      return;
    }

    final message = Map<String, dynamic>.from(messageRaw);
    final senderId = (message['senderId'] ?? '').toString();
    if (senderId.isNotEmpty && senderId == widget.session.userId) {
      return;
    }

    final senderName = _extractSenderName(message);
    final preview = _extractMessagePreview(message);
    _showInfo(
      senderName.isEmpty ? 'New message: $preview' : '$senderName: $preview',
    );
  }

  String _extractSenderName(Map<String, dynamic> message) {
    final direct = (message['senderName'] ?? '').toString().trim();
    if (direct.isNotEmpty) {
      return direct;
    }

    final senderRaw = message['sender'];
    if (senderRaw is Map) {
      final sender = Map<String, dynamic>.from(senderRaw);
      final fullName =
          '${(sender['firstName'] ?? '').toString().trim()} ${(sender['lastName'] ?? '').toString().trim()}'
              .trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }

    return '';
  }

  String _extractMessagePreview(Map<String, dynamic> message) {
    final text = (message['text'] ?? message['content'] ?? '')
        .toString()
        .trim();
    if (text.isNotEmpty) {
      return text;
    }
    return 'Attachment';
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        Container(decoration: CommunicationPalette.backgroundDecoration()),
        SafeArea(
          child: _loading
              ? const _ChatsSkeleton()
              : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: CommunicationPalette.bodyStyle(
                      color: CommunicationPalette.textMuted(context),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: CommunicationPalette.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 14),
                      _buildFilters(),
                      const SizedBox(height: 18),
                      _buildContactsRow(),
                      const SizedBox(height: 20),
                      Text(
                        'Recent conversations',
                        style: CommunicationPalette.titleStyle(size: 33),
                      ),
                      const SizedBox(height: 10),
                      ..._buildConversationCards(),
                    ],
                  ),
                ),
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: _FloatingComposerButton(onTap: _openQuickActions),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      body: body,
      floatingActionButton: widget.onLogout == null
          ? null
          : FloatingActionButton.small(
              onPressed: widget.onLogout,
              tooltip: 'Logout',
              backgroundColor: CommunicationPalette.card(context),
              child: const Icon(Icons.logout_rounded),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: CommunicationPalette.glassCard(
        radius: BorderRadius.circular(24),
        color: const Color(0xFF1E3554).withValues(alpha: 0.9),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _refresh(),
        style: CommunicationPalette.bodyStyle(),
        decoration: InputDecoration(
          hintText: 'Search members, squads, or tactics...',
          hintStyle: CommunicationPalette.bodyStyle(
            color: CommunicationPalette.textMuted(context),
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF7D91AE)),
          suffixIcon: IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF7D91AE)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterChip(label: 'All', value: _ConversationFilter.all),
        _filterChip(label: 'Private', value: _ConversationFilter.private),
        _filterChip(label: 'Team', value: _ConversationFilter.team),
        _filterChip(label: 'Club', value: _ConversationFilter.club),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required _ConversationFilter value,
  }) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _refresh();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: selected
              ? CommunicationPalette.primary
              : CommunicationPalette.cardBlueSoft.withValues(alpha: 0.9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: CommunicationPalette.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: CommunicationPalette.titleStyle(
            size: 16,
            weight: FontWeight.w600,
            color: selected
                ? Colors.white
                : CommunicationPalette.textPrimary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsRow() {
    final onlineUsers = _users
        .where((user) => _onlineUserIds.contains(user.id))
        .toList();
    if (_users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent contacts',
              style: CommunicationPalette.titleStyle(size: 18),
            ),
            const Spacer(),
            Text(
              '${onlineUsers.length} ACTIVE NOW',
              style: CommunicationPalette.titleStyle(
                size: 13,
                color: CommunicationPalette.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (onlineUsers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: CommunicationPalette.glassCard(
              radius: BorderRadius.circular(20),
              color: const Color(0xFF112744).withValues(alpha: 0.9),
            ),
            child: Text(
              'No members online right now',
              style: CommunicationPalette.bodyStyle(
                size: 14,
                color: CommunicationPalette.textMuted(context),
              ),
            ),
          )
        else
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final user = onlineUsers[index];
                final userAvatarUrl = _resolveMediaUrl(user.photoUrl);
                return GestureDetector(
                  onTap: () => _openDirect(user),
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                    decoration: CommunicationPalette.glassCard(
                      radius: BorderRadius.circular(20),
                      color: const Color(0xFF112744).withValues(alpha: 0.95),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor:
                                  CommunicationPalette.cardBlueSoft,
                              backgroundImage: userAvatarUrl == null
                                  ? null
                                  : NetworkImage(userAvatarUrl),
                              child: userAvatarUrl == null
                                  ? Text(
                                      user.displayName.isEmpty
                                          ? '?'
                                          : user.displayName[0].toUpperCase(),
                                      style: CommunicationPalette.titleStyle(
                                        size: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 1,
                              bottom: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: CommunicationPalette.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CommunicationPalette.deepBlue,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CommunicationPalette.bodyStyle(size: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: onlineUsers.length.clamp(0, 12),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildConversationCards() {
    final rows = _filteredConversations;
    if (rows.isEmpty) {
      return const [
        EmptyState(
          title: 'No conversations yet',
          message: 'Start a direct conversation from recent contacts.',
          icon: Icons.forum_outlined,
        ),
      ];
    }

    return rows.map((conversation) {
      final hasUnread = conversation.unreadCount > 0;
      final avatarUrl = _conversationAvatarUrl(conversation);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _openConversation(conversation),
          child: Stack(
            children: [
              Container(
                decoration: CommunicationPalette.glassCard(
                  radius: BorderRadius.circular(24),
                  color: const Color(0xFF102846).withValues(alpha: 0.96),
                  highlight: hasUnread,
                ),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF17375A),
                          backgroundImage: avatarUrl == null
                              ? null
                              : NetworkImage(avatarUrl),
                          child: avatarUrl == null
                              ? Text(
                                  conversation.displayTitle.isEmpty
                                      ? '?'
                                      : conversation.displayTitle[0]
                                            .toUpperCase(),
                                  style: CommunicationPalette.titleStyle(
                                    size: 24,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: CommunicationPalette.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CommunicationPalette.deepBlue,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CommunicationPalette.titleStyle(size: 21),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            conversation.lastMessagePreview.isEmpty
                                ? 'No messages yet'
                                : conversation.lastMessagePreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CommunicationPalette.bodyStyle(
                              size: 18,
                              color: CommunicationPalette.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _timeLabel(conversation.lastMessageAt),
                          style: CommunicationPalette.bodyStyle(
                            size: 14,
                            color: CommunicationPalette.textMuted(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (hasUnread)
                          Container(
                            width: 31,
                            height: 31,
                            decoration: BoxDecoration(
                              color: CommunicationPalette.secondary,
                              borderRadius: BorderRadius.circular(15.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${conversation.unreadCount}',
                              style: CommunicationPalette.titleStyle(
                                size: 14,
                                color: const Color(0xFF032138),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasUnread)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: CommunicationPalette.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<ConversationModel> get _filteredConversations {
    return _conversations.where((conversation) {
      final type = conversation.type.toLowerCase();
      final isPrivate = type == 'private' || type == 'direct';
      final hasTeam = (conversation.teamId ?? '').isNotEmpty;
      final inferredTeam = conversation.displayTitle.toLowerCase().contains(
        'team',
      );

      switch (_filter) {
        case _ConversationFilter.private:
          return isPrivate;
        case _ConversationFilter.team:
          return !isPrivate && (hasTeam || inferredTeam);
        case _ConversationFilter.club:
          return !isPrivate && !hasTeam;
        case _ConversationFilter.all:
          return true;
      }
    }).toList();
  }

  String? get _apiTypeFilter {
    switch (_filter) {
      case _ConversationFilter.private:
        return 'private';
      case _ConversationFilter.team:
      case _ConversationFilter.club:
        return 'group';
      case _ConversationFilter.all:
        return null;
    }
  }

  String _timeLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return '--:--';
    }
    final now = DateTime.now();
    final isToday =
        now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    if (!isToday) {
      return 'Yesterday';
    }

    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _ChatsSkeleton extends StatelessWidget {
  const _ChatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final box = CommunicationPalette.glassCard(
      radius: BorderRadius.circular(18),
      color: CommunicationPalette.cardBlueSoft.withValues(alpha: 0.8),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Row(
          children: [
            Container(width: 56, height: 56, decoration: box),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 42, decoration: box)),
          ],
        ),
        const SizedBox(height: 16),
        Container(height: 56, decoration: box),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
                height: 42,
                decoration: box,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: 5,
            itemBuilder: (_, __) => Container(width: 82, decoration: box),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 96,
            decoration: box,
          ),
        ),
      ],
    );
  }
}

class _GroupComposerResult {
  _GroupComposerResult({
    required this.title,
    required this.participantIds,
    required this.teamOnly,
  });

  final String title;
  final List<String> participantIds;
  final bool teamOnly;
}

class _FloatingComposerButton extends StatelessWidget {
  const _FloatingComposerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E90FF), Color(0xFF4B7FE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4B8DFF).withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(
          Icons.mark_chat_unread_outlined,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}
