import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/app_config.dart';
import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../communication_theme.dart';
import '../models/communication_models.dart';
import 'call_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.api,
    required this.session,
    required this.conversationId,
    required this.title,
    this.peerUserId,
    this.peerDisplayName,
    this.conversationType,
    this.participantDisplayNames = const {},
  });

  final UserManagementApi api;
  final SessionModel session;
  final String conversationId;
  final String title;
  final String? peerUserId;
  final String? peerDisplayName;
  final String? conversationType;
  final Map<String, String> participantDisplayNames;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();

  List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _showEmojiPanel = false;
  String? _error;

  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _composerFocusNode.addListener(_handleComposerFocusChange);
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _socket?.emit('leave_conversation', {
      'conversationId': widget.conversationId,
    });
    _socket?.dispose();
    _composerFocusNode.removeListener(_handleComposerFocusChange);
    _composerFocusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleComposerFocusChange() {
    if (!mounted) {
      return;
    }
    if (_composerFocusNode.hasFocus && _showEmojiPanel) {
      setState(() => _showEmojiPanel = false);
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await widget.api.getMessages(
        widget.session.token,
        widget.conversationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
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
      onConnect: () {
        _socket?.emit('join_conversation', {
          'conversationId': widget.conversationId,
        });
      },
    );

    _socket?.on('new_message', (payload) {
      if (!mounted || payload is! Map) {
        return;
      }
      final payloadMap = Map<String, dynamic>.from(payload);
      final conversationId = (payloadMap['conversationId'] ?? '').toString();
      if (conversationId == widget.conversationId) {
        final messageRaw = payloadMap['message'];
        if (messageRaw is Map) {
          final messageMap = Map<String, dynamic>.from(messageRaw);
          final realtimeMessage = ChatMessageModel.fromJson(messageMap);
          final inserted = _upsertMessage(realtimeMessage);
          if (inserted &&
              realtimeMessage.senderId.isNotEmpty &&
              realtimeMessage.senderId != widget.session.userId) {
            final senderLabel = _resolveSenderLabel(
              realtimeMessage.senderId,
              mine: false,
            );
            final preview = _messagePreview(messageMap);
            final label = senderLabel.isEmpty
                ? 'New message'
                : 'New message from $senderLabel';
            _showInfo('$label: $preview');
          }
        }
      }
    });

    _socket?.on('message_read', (payload) {
      if (!mounted || payload is! Map) {
        return;
      }
      final payloadMap = Map<String, dynamic>.from(payload);
      final conversationId = (payloadMap['conversationId'] ?? '').toString();
      if (conversationId == widget.conversationId) {
        final userId = (payloadMap['userId'] ?? '').toString().trim();
        if (userId.isNotEmpty) {
          _applyReadReceipt(userId);
        }
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() => _sending = true);
    try {
      final sentMessage = await widget.api.sendChatMessage(
        token: widget.session.token,
        conversationId: widget.conversationId,
        text: text,
      );
      _textController.clear();
      if (mounted) {
        _upsertMessage(sentMessage);
      }
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendAttachment() async {
    if (_sending) {
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 84,
      );
      if (file == null) {
        return;
      }

      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final uploaded = await widget.api.uploadDocument(
        token: widget.session.token,
        bytes: bytes,
        filename: file.name,
      );

      final sentMessage = await widget.api.sendChatMessage(
        token: widget.session.token,
        conversationId: widget.conversationId,
        file: uploaded,
      );
      if (mounted) {
        _upsertMessage(sentMessage);
      }
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  bool _upsertMessage(ChatMessageModel message) {
    var inserted = false;
    setState(() {
      final existingIndex = _messages.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        _messages[existingIndex] = message;
      } else {
        _messages.add(message);
        inserted = true;
      }

      _messages.sort((a, b) {
        final createdAtCompare = a.createdAt.compareTo(b.createdAt);
        if (createdAtCompare != 0) {
          return createdAtCompare;
        }
        return a.id.compareTo(b.id);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return inserted;
  }

  void _applyReadReceipt(String readerUserId) {
    if (readerUserId == widget.session.userId) {
      return;
    }

    final shouldUpdate = _messages.any(
      (message) =>
          message.senderId == widget.session.userId &&
          !message.readBy.contains(readerUserId),
    );
    if (!shouldUpdate) {
      return;
    }

    setState(() {
      _messages = _messages
          .map((message) {
            final mine = message.senderId == widget.session.userId;
            final alreadyRead = message.readBy.contains(readerUserId);
            if (!mine || alreadyRead) {
              return message;
            }

            final updatedReadBy = <String>{
              ...message.readBy,
              readerUserId,
            }.toList();
            return ChatMessageModel(
              id: message.id,
              senderId: message.senderId,
              senderRole: message.senderRole,
              contentType: message.contentType,
              createdAt: message.createdAt,
              text: message.text,
              file: message.file,
              deletedAt: message.deletedAt,
              readBy: updatedReadBy,
            );
          })
          .toList(growable: false);
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showError(String raw) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(raw.replaceFirst('Exception: ', ''))),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleEmojiPanel() {
    if (_showEmojiPanel) {
      setState(() => _showEmojiPanel = false);
      _composerFocusNode.requestFocus();
      return;
    }

    _composerFocusNode.unfocus();
    setState(() => _showEmojiPanel = true);
  }

  void _insertEmoji(String emoji) {
    final value = _textController.value;
    final start = value.selection.start;
    final end = value.selection.end;

    if (start < 0 || end < 0) {
      final text = value.text + emoji;
      _textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      return;
    }

    final selectionStart = start <= end ? start : end;
    final selectionEnd = start <= end ? end : start;
    final replaced = value.text.replaceRange(
      selectionStart,
      selectionEnd,
      emoji,
    );
    final offset = selectionStart + emoji.length;
    _textController.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  void _onComposerTap() {
    if (_showEmojiPanel) {
      setState(() => _showEmojiPanel = false);
    }
  }

  bool _isSeenByPeer(ChatMessageModel message, bool mine) {
    if (!mine) {
      return false;
    }

    final privatePeerId = widget.peerUserId?.trim();
    if (privatePeerId != null && privatePeerId.isNotEmpty) {
      return message.readBy.contains(privatePeerId);
    }

    return message.readBy.any((id) => id != widget.session.userId);
  }

  bool get _canStartCall {
    final type = (widget.conversationType ?? '').toLowerCase();
    return widget.peerUserId != null &&
        widget.peerUserId!.isNotEmpty &&
        (type.isEmpty || type == 'private');
  }

  bool get _isGroupConversation =>
      (widget.conversationType ?? '').toLowerCase() == 'group';

  String _resolveSenderLabel(String senderId, {required bool mine}) {
    if (mine) {
      return 'You';
    }

    final mapped = widget.participantDisplayNames[senderId];
    if (mapped != null && mapped.trim().isNotEmpty) {
      return mapped.trim();
    }

    if (widget.peerUserId != null &&
        widget.peerUserId == senderId &&
        widget.peerDisplayName != null &&
        widget.peerDisplayName!.trim().isNotEmpty) {
      return widget.peerDisplayName!.trim();
    }

    return 'Member';
  }

  String _messagePreview(Map<String, dynamic> message) {
    final text = (message['text'] ?? message['content'] ?? '')
        .toString()
        .trim();
    if (text.isNotEmpty) {
      return text;
    }
    return 'Attachment';
  }

  Future<void> _startCall(bool isVideo) async {
    if (!_canStartCall) {
      _showError('Audio/video calls are available for private conversations.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebrtcCallScreen.outgoing(
          api: widget.api,
          session: widget.session,
          conversationId: widget.conversationId,
          peerUserId: widget.peerUserId!,
          peerDisplayName: widget.peerDisplayName ?? widget.title,
          isVideo: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = CommunicationPalette.textMuted(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: CommunicationPalette.backgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _TopConversationBar(
                title: widget.title,
                subtitle: widget.session.clubName ?? 'ODIN ERP CLUB',
                onStartVideoCall: _canStartCall ? () => _startCall(true) : null,
                onStartAudioCall: _canStartCall
                    ? () => _startCall(false)
                    : null,
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF112741).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'TODAY  •  SOVEREIGN PROTOCOL ACTIVE',
                  style: CommunicationPalette.bodyStyle(
                    size: 13,
                    color: CommunicationPalette.textMutedBlue,
                    letterSpacing: 1.8,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? _MessagesSkeleton(
                        card: CommunicationPalette.card(context),
                      )
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: CommunicationPalette.bodyStyle(color: muted),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final mine =
                                message.senderId == widget.session.userId;

                            return _ChatBubble(
                              message: message,
                              mine: mine,
                              isSeen: _isSeenByPeer(message, mine),
                              showSenderBelow: _isGroupConversation,
                              senderLabel: _resolveSenderLabel(
                                message.senderId,
                                mine: mine,
                              ),
                              authToken: widget.session.token,
                            );
                          },
                        ),
                      ),
              ),
              _ComposerBar(
                controller: _textController,
                focusNode: _composerFocusNode,
                sending: _sending,
                onSend: _sendText,
                onAttach: _sendAttachment,
                onEmojiTap: _toggleEmojiPanel,
                onComposerTap: _onComposerTap,
              ),
              if (_showEmojiPanel) _EmojiPanel(onEmojiSelected: _insertEmoji),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopConversationBar extends StatelessWidget {
  const _TopConversationBar({
    required this.title,
    required this.subtitle,
    required this.onStartVideoCall,
    required this.onStartAudioCall,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onStartVideoCall;
  final VoidCallback? onStartAudioCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CommunicationPalette.secondary.withValues(alpha: 0.7),
                  width: 1.1,
                ),
                gradient: const RadialGradient(
                  colors: [Color(0xFF3E78DE), Color(0xFF193864)],
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CommunicationPalette.titleStyle(size: 25),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: CommunicationPalette.bodyStyle(
                    size: 13,
                    color: CommunicationPalette.textMutedBlue,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onStartVideoCall,
            icon: const Icon(Icons.videocam_outlined),
            color: onStartVideoCall == null
                ? const Color(0xFF5E6D84)
                : const Color(0xFFA2B8DD),
          ),
          IconButton(
            onPressed: onStartAudioCall,
            icon: const Icon(Icons.call_outlined),
            color: onStartAudioCall == null
                ? const Color(0xFF5E6D84)
                : const Color(0xFFA2B8DD),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.mine,
    required this.isSeen,
    required this.showSenderBelow,
    required this.senderLabel,
    required this.authToken,
  });

  final ChatMessageModel message;
  final bool mine;
  final bool isSeen;
  final bool showSenderBelow;
  final String senderLabel;
  final String authToken;

  @override
  Widget build(BuildContext context) {
    final textColor = mine ? const Color(0xFF052447) : const Color(0xFFD4E4FF);
    final hasImageAttachment =
        message.file != null && _isImageAttachment(message.file!);
    final attachmentUrl = hasImageAttachment
        ? _resolveAttachmentUrl(message.file!.url)
        : '';
    final hasRenderableText =
        (message.text ?? '').isNotEmpty &&
        !(message.contentType == 'FILE' && message.file != null);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: BoxDecoration(
                color: mine
                    ? const Color(0xFF7FA8F8)
                    : const Color(0xFF1A304C).withValues(alpha: 0.95),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(mine ? 24 : 8),
                  bottomRight: Radius.circular(mine ? 8 : 24),
                ),
                boxShadow: mine
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF5E91EE,
                          ).withValues(alpha: 0.33),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImageAttachment && attachmentUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        attachmentUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 188,
                        headers: authToken.isEmpty
                            ? null
                            : {'Authorization': 'Bearer $authToken'},
                        errorBuilder: (_, __, ___) => _FileLabel(
                          fileName: message.file!.name,
                          textColor: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  if (message.file != null) ...[
                    if (!hasImageAttachment)
                      _FileLabel(
                        fileName: message.file!.name,
                        textColor: textColor,
                      ),
                    if (!hasImageAttachment) const SizedBox(height: 7),
                  ],
                  if (hasRenderableText)
                    Text(
                      message.text!,
                      style: CommunicationPalette.bodyStyle(
                        size: 18,
                        color: textColor,
                        weight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeLabel(message.createdAt),
                    style: CommunicationPalette.bodyStyle(
                      size: 13,
                      color: CommunicationPalette.textMutedBlue,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 6),
                    Icon(
                      isSeen ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 16,
                      color: isSeen
                          ? CommunicationPalette.secondary
                          : CommunicationPalette.textMutedBlue,
                    ),
                  ],
                ],
              ),
            ),
            if (showSenderBelow)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                child: Text(
                  senderLabel,
                  style: CommunicationPalette.bodyStyle(
                    size: 12,
                    color: CommunicationPalette.textMutedBlue.withValues(
                      alpha: 0.9,
                    ),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool _isImageAttachment(UploadedDocumentModel file) {
    final mime = file.mimeType.toLowerCase();
    if (mime.startsWith('image/')) {
      return true;
    }
    final name = file.name.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp');
  }

  String _resolveAttachmentUrl(String url) {
    final raw = url.trim();
    if (raw.isEmpty ||
        raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('data:')) {
      return raw;
    }

    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;
    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '$base$normalizedPath';
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onAttach,
    required this.onEmojiTap,
    required this.onComposerTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onEmojiTap;
  final VoidCallback onComposerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A304B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: sending ? null : onAttach,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: const Color(0xFFC7D8F6),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF273E5A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onTap: onComposerTap,
                minLines: 1,
                maxLines: 4,
                style: CommunicationPalette.bodyStyle(size: 17),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Draft encrypted message...',
                  hintStyle: CommunicationPalette.bodyStyle(
                    size: 16,
                    color: CommunicationPalette.textMutedBlue,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onEmojiTap,
            icon: const Icon(Icons.emoji_emotions_outlined),
            color: const Color(0xFFC7D8F6),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E91FF), Color(0xFF5F8DE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileLabel extends StatelessWidget {
  const _FileLabel({required this.fileName, required this.textColor});

  final String fileName;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.attach_file_rounded, size: 18, color: textColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CommunicationPalette.bodyStyle(
              color: textColor,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

  static const List<String> _emojis = [
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😍',
    '😘',
    '😎',
    '🤝',
    '👏',
    '🙌',
    '💪',
    '🔥',
    '⚽',
    '🏆',
    '🎯',
    '📈',
    '📣',
    '📎',
    '✅',
    '❌',
    '⏱️',
    '🚀',
    '💙',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF112741).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: GridView.builder(
        itemCount: _emojis.length,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onEmojiSelected(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          );
        },
      ),
    );
  }
}

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton({required this.card});

  final Color card;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.all(14),
      itemBuilder: (context, index) {
        final mine = index.isEven;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 232,
            height: 56,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: card.withValues(alpha: 0.78),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(mine ? 22 : 8),
                bottomRight: Radius.circular(mine ? 8 : 22),
              ),
            ),
          ),
        );
      },
    );
  }
}
