import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/app_config.dart';
import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../communication_theme.dart';
import '../models/communication_models.dart';

enum _CallUiState { connecting, ringing, incoming, active, ended, failed }

class WebrtcCallScreen extends StatefulWidget {
  const WebrtcCallScreen.outgoing({
    super.key,
    required this.api,
    required this.session,
    required this.conversationId,
    required this.peerUserId,
    required this.peerDisplayName,
    required this.isVideo,
    this.turnServerUrl,
    this.turnUsername,
    this.turnCredential,
  }) : incomingEvent = null,
       isIncoming = false;

  const WebrtcCallScreen.incoming({
    super.key,
    required this.api,
    required this.session,
    required this.incomingEvent,
    this.turnServerUrl,
    this.turnUsername,
    this.turnCredential,
  }) : conversationId = null,
       peerUserId = null,
       peerDisplayName = null,
       isVideo = null,
       isIncoming = true;

  final UserManagementApi api;
  final SessionModel session;

  final bool isIncoming;
  final IncomingCallEvent? incomingEvent;

  final String? conversationId;
  final String? peerUserId;
  final String? peerDisplayName;
  final bool? isVideo;

  final String? turnServerUrl;
  final String? turnUsername;
  final String? turnCredential;

  @override
  State<WebrtcCallScreen> createState() => _WebrtcCallScreenState();
}

class _WebrtcCallScreenState extends State<WebrtcCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  io.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  NavigatorState? _navigator;
  Future<void>? _peerSetupFuture;
  final List<RTCIceCandidate> _pendingRemoteCandidates = <RTCIceCandidate>[];
  Timer? _autoCloseTimer;

  String? _callId;
  _CallUiState _state = _CallUiState.connecting;
  String? _statusMessage;

  bool _socketReady = false;
  bool _callRequestSent = false;
  bool _acceptedIncoming = false;
  bool _endSignalSent = false;
  bool _muted = false;
  bool _cameraOff = false;
  bool _isDisposing = false;
  bool _localOfferSent = false;
  bool _remoteDescriptionSet = false;
  bool _hasHandledTerminalState = false;
  bool _didRestartIce = false;
  MediaStream? _remoteFallbackStream;

  bool get _canUpdateUi => mounted && !_isDisposing;

  bool get _isVideoCall => widget.isIncoming
      ? (widget.incomingEvent?.isVideo ?? false)
      : (widget.isVideo ?? false);

  String get _peerName => widget.isIncoming
      ? widget.incomingEvent?.fromDisplayName ?? 'Unknown caller'
      : (widget.peerDisplayName ?? 'Teammate');

  String get _targetUserId => widget.isIncoming
      ? (widget.incomingEvent?.fromUserId ?? '')
      : (widget.peerUserId ?? '');

  String get _conversationId => widget.isIncoming
      ? (widget.incomingEvent?.conversationId ?? '')
      : (widget.conversationId ?? '');

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator ??= Navigator.of(context);
  }

  @override
  void deactivate() {
    _isDisposing = true;
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
    _socketReady = false;
    unawaited(_endCallIfNeeded(reason: 'cancelled'));
    _socket?.dispose();
    _socket = null;
    _disposePeer();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    if (!mounted) {
      return;
    }

    _callId = widget.isIncoming ? widget.incomingEvent?.callId : null;
    if (widget.isIncoming) {
      _state = _CallUiState.incoming;
      _statusMessage = 'Incoming ${_isVideoCall ? 'video' : 'audio'} call';
    } else {
      _state = _CallUiState.connecting;
      _statusMessage = 'Connecting to signaling server...';
    }

    _connectSocket();
  }

  void _connectSocket() {
    _socket?.dispose();
    _socket = widget.api.connectWebrtcSocket(
      token: widget.session.token,
      onConnect: () {
        _socketReady = true;
        if (widget.isIncoming) {
          _safeSetState(() {
            _statusMessage =
                'Incoming ${_isVideoCall ? 'video' : 'audio'} call';
          });
          return;
        }
        _startOutgoingFlow();
      },
      onConnectError: (error) {
        _safeSetState(() {
          _state = _CallUiState.failed;
          _statusMessage = 'Signaling error: $error';
        });
      },
      onDisconnect: (_) {
        _safeSetState(() {
          _socketReady = false;
          if (_state != _CallUiState.ended && _state != _CallUiState.failed) {
            _statusMessage = 'Reconnecting...';
          }
        });
      },
    );

    _bindSocketEvents();
  }

  void _bindSocketEvents() {
    _socket?.on('call_accepted', (payload) async {
      final map = _asMap(payload);
      if (!_matchesCall(map)) {
        return;
      }

      if (!mounted) {
        return;
      }

      _safeSetState(() {
        _state = _CallUiState.connecting;
        _statusMessage = 'Call accepted. Negotiating media...';
      });

      await _ensurePeerConnection(asCaller: !widget.isIncoming);
    });

    _socket?.on('call_rejected', (payload) {
      final map = _asMap(payload);
      if (!_matchesCall(map)) {
        return;
      }
      _handleRemoteEnded(
        reason: (map['reason'] ?? 'rejected').toString(),
        message: 'Call rejected',
      );
    });

    _socket?.on('call_ended', (payload) {
      final map = _asMap(payload);
      if (!_matchesCall(map)) {
        return;
      }
      _handleRemoteEnded(
        reason: (map['reason'] ?? 'ended').toString(),
        message: 'Call ended',
      );
    });

    _socket?.on('webrtc_offer', (payload) async {
      final map = _asMap(payload);
      if (!_matchesCall(map)) {
        return;
      }

      if (widget.isIncoming && !_acceptedIncoming) {
        return;
      }

      await _ensurePeerConnection(asCaller: false);
      final sdp = _asMap(map['sdp']);
      final remoteDescription = RTCSessionDescription(
        (sdp['sdp'] ?? '').toString(),
        (sdp['type'] ?? 'offer').toString(),
      );
      await _peerConnection?.setRemoteDescription(remoteDescription);
      _remoteDescriptionSet = true;
      await _flushPendingRemoteCandidates();

      final answer = await _peerConnection?.createAnswer();
      if (answer == null || _callId == null) {
        return;
      }

      await _peerConnection?.setLocalDescription(answer);
      _socket?.emit('webrtc_answer', {
        'callId': _callId,
        'sdp': answer.toMap(),
      });

      _safeSetState(() {
        _state = _CallUiState.active;
        _statusMessage = 'In call';
      });
    });

    _socket?.on('webrtc_answer', (payload) async {
      final map = _asMap(payload);
      if (!_matchesCall(map)) {
        return;
      }

      final sdp = _asMap(map['sdp']);
      final remoteDescription = RTCSessionDescription(
        (sdp['sdp'] ?? '').toString(),
        (sdp['type'] ?? 'answer').toString(),
      );
      await _peerConnection?.setRemoteDescription(remoteDescription);

      _remoteDescriptionSet = true;
      await _flushPendingRemoteCandidates();
      _safeSetState(() {
        _state = _CallUiState.active;
        _statusMessage = 'In call';
      });
    });

    _socket?.on('ice_candidate', (payload) async {
      final map = _asMap(payload);
      if (!_matchesCall(map)) {
        return;
      }

      final candidateMap = _asMap(map['candidate']);
      final candidateRaw =
          candidateMap['candidate'] ?? map['candidate'] ?? map['iceCandidate'];
      final candidate = RTCIceCandidate(
        candidateRaw?.toString(),
        (candidateMap['sdpMid'] ?? map['sdpMid'])?.toString(),
        _parseSdpMLineIndex(
          candidateMap['sdpMLineIndex'] ??
              candidateMap['sdpMlineIndex'] ??
              map['sdpMLineIndex'] ??
              map['sdpMlineIndex'],
        ),
      );

      await _addRemoteCandidate(candidate);
    });
  }

  Future<void> _startOutgoingFlow() async {
    if (_callRequestSent || !_socketReady) {
      return;
    }

    if (_targetUserId.isEmpty || _conversationId.isEmpty) {
      _safeSetState(() {
        _state = _CallUiState.failed;
        _statusMessage = 'Missing call target or conversation context';
      });
      return;
    }

    _callRequestSent = true;

    _safeSetState(() {
      _state = _CallUiState.ringing;
      _statusMessage = 'Calling $_peerName...';
    });

    _socket?.emitWithAck(
      'call_user',
      {
        'conversationId': _conversationId,
        'targetUserId': _targetUserId,
        'type': _isVideoCall ? 'video' : 'audio',
      },
      ack: (response) {
        final map = _asMap(response);
        if (map['ok'] == true && map['callId'] != null) {
          _callId = map['callId'].toString();
          return;
        }

        final message = (map['message'] ?? '').toString();
        if (message.isEmpty) {
          return;
        }

        _safeSetState(() {
          _state = _CallUiState.failed;
          _statusMessage = message;
        });
      },
    );
  }

  Future<void> _acceptIncomingCall() async {
    if (_callId == null || !_socketReady) {
      return;
    }

    _safeSetState(() {
      _acceptedIncoming = true;
      _state = _CallUiState.connecting;
      _statusMessage = 'Accepting call...';
    });

    _socket?.emit('accept_call', {'callId': _callId});
    await _ensurePeerConnection(asCaller: false);
  }

  Future<void> _rejectIncomingCall() async {
    if (_callId != null && _socketReady) {
      _socket?.emit('reject_call', {'callId': _callId, 'reason': 'rejected'});
      _endSignalSent = true;
    }

    _navigator?.maybePop();
  }

  Future<void> _ensurePeerConnection({required bool asCaller}) async {
    try {
      if (_isDisposing) {
        return;
      }

      if (_peerConnection != null) {
        if (asCaller) {
          await _createAndSendOffer();
        }
        return;
      }

      if (_peerSetupFuture != null) {
        await _peerSetupFuture;
        if (asCaller) {
          await _createAndSendOffer();
        }
        return;
      }

      final completer = Completer<void>();
      _peerSetupFuture = completer.future;
      try {
        await _initializeLocalStreamIfNeeded();
        if (_localStream == null || _isDisposing) {
          return;
        }

        await Helper.setSpeakerphoneOn(true);

        if (_isVideoCall) {
          _localRenderer.srcObject = _localStream;
        }

        final peer = await createPeerConnection(_buildPeerConfiguration());

        final existingSenders = await peer.getSenders();
        for (final track in _localStream!.getTracks()) {
          final alreadyAdded = existingSenders.any(
            (sender) => sender.track?.id == track.id,
          );
          if (alreadyAdded) {
            continue;
          }
          await peer.addTrack(track, _localStream!);
        }

        peer.onTrack = (event) async {
          if (_isDisposing) {
            return;
          }

          if (event.streams.isNotEmpty) {
            _remoteRenderer.srcObject = event.streams.first;
          } else if (event.track.kind == 'video') {
            _remoteFallbackStream ??= await createLocalMediaStream(
              'remote_fallback',
            );
            await _remoteFallbackStream!.addTrack(
              event.track,
              addToNative: true,
            );
            _remoteRenderer.srcObject = _remoteFallbackStream;
          }
          _safeSetState(() {
            _state = _CallUiState.active;
            _statusMessage = 'In call';
          });
        };

        peer.onIceCandidate = (candidate) {
          if (_callId == null || candidate.candidate == null || _isDisposing) {
            return;
          }

          _socket?.emit('ice_candidate', {
            'callId': _callId,
            'candidate': candidate.toMap(),
          });
        };

        peer.onConnectionState = (state) async {
          if (_isDisposing) {
            return;
          }

          if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _safeSetState(() {
              _state = _CallUiState.active;
              _statusMessage = 'In call';
            });
            return;
          }

          if (state ==
                  RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
              state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            _safeSetState(() {
              _statusMessage = 'Connection unstable';
            });

            if (!_didRestartIce && _peerConnection != null) {
              _didRestartIce = true;
              try {
                await _peerConnection?.restartIce();
              } catch (_) {
                // Ignore restart failures; we keep the call alive and let users retry.
              }
            }
          }
        };

        _peerConnection = peer;
        await _flushPendingRemoteCandidates();
      } finally {
        completer.complete();
        _peerSetupFuture = null;
      }

      if (asCaller) {
        await _createAndSendOffer();
      }
    } catch (error) {
      _disposePeer();
      final errorText = error.toString();
      final deniedMediaPermission =
          errorText.contains('NotAllowedError') ||
          errorText.contains('Permission') ||
          errorText.contains('permission');
      _safeSetState(() {
        _state = _CallUiState.failed;
        _statusMessage = deniedMediaPermission
            ? 'Camera/microphone permission is required'
            : 'Media setup failed';
      });
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null || _callId == null || _localOfferSent) {
      return;
    }

    final offer = await _peerConnection?.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': _isVideoCall ? 1 : 0,
    });
    if (offer == null) {
      return;
    }

    await _peerConnection?.setLocalDescription(offer);
    _localOfferSent = true;
    _socket?.emit('webrtc_offer', {'callId': _callId, 'sdp': offer.toMap()});
  }

  Future<void> _endCallFromUi() async {
    await _endCallIfNeeded(
      reason: _state == _CallUiState.ringing ? 'cancelled' : 'completed',
    );
    _navigator?.maybePop();
  }

  Future<void> _endCallIfNeeded({required String reason}) async {
    if (_endSignalSent || !_socketReady || _callId == null) {
      return;
    }

    if (_state == _CallUiState.ended) {
      return;
    }

    _endSignalSent = true;
    _socket?.emit('end_call', {'callId': _callId, 'reason': reason});
  }

  Future<void> _toggleMute() async {
    final stream = _localStream;
    if (stream == null) {
      return;
    }

    final nextMuted = !_muted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !nextMuted;
    }

    if (!mounted) {
      return;
    }
    setState(() => _muted = nextMuted);
  }

  Future<void> _toggleCamera() async {
    if (!_isVideoCall || _localStream == null) {
      return;
    }

    final nextCameraOff = !_cameraOff;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !nextCameraOff;
    }

    if (!mounted) {
      return;
    }
    setState(() => _cameraOff = nextCameraOff);
  }

  void _handleRemoteEnded({required String reason, required String message}) {
    if (_hasHandledTerminalState) {
      return;
    }
    _hasHandledTerminalState = true;

    _disposePeer();
    _safeSetState(() {
      _state = _CallUiState.ended;
      _statusMessage = '$message ($reason)';
    });

    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(milliseconds: 900), () {
      if (!_canUpdateUi) {
        return;
      }
      _navigator?.maybePop();
    });
  }

  Future<void> _initializeLocalStreamIfNeeded() async {
    if (_localStream != null) {
      return;
    }

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': _isVideoCall
          ? {
              'facingMode': 'user',
              'width': 1280,
              'height': 720,
              'frameRate': 30,
            }
          : false,
    });

    if (_isDisposing) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      await stream.dispose();
      return;
    }

    _localStream = stream;
  }

  void _disposePeer() {
    for (final track
        in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      track.stop();
    }

    _localStream?.dispose();
    _localStream = null;

    _peerConnection?.close();
    _peerConnection?.dispose();
    _peerConnection = null;
    _localOfferSent = false;
    _remoteDescriptionSet = false;
    _didRestartIce = false;
    _pendingRemoteCandidates.clear();

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _remoteFallbackStream?.dispose();
    _remoteFallbackStream = null;
  }

  Future<void> _addRemoteCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null || !_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }

    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (_) {
      _pendingRemoteCandidates.add(candidate);
    }
  }

  Future<void> _flushPendingRemoteCandidates() async {
    if (_peerConnection == null || !_remoteDescriptionSet) {
      return;
    }

    if (_pendingRemoteCandidates.isEmpty) {
      return;
    }

    final pending = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();

    for (final candidate in pending) {
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (_) {
        _pendingRemoteCandidates.add(candidate);
      }
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_canUpdateUi) {
      return;
    }
    setState(fn);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  bool _matchesCall(Map<String, dynamic> payload) {
    final callId = payload['callId']?.toString();
    if (callId == null || callId.isEmpty) {
      return false;
    }

    if (_callId == null || _callId!.isEmpty) {
      _callId = callId;
      return true;
    }

    return _callId == callId;
  }

  int? _parseSdpMLineIndex(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is int) {
      return raw;
    }

    return int.tryParse(raw.toString());
  }

  Map<String, dynamic> _buildPeerConfiguration() {
    final iceServers = <Map<String, dynamic>>[
      for (final url in AppConfig.webrtcStunUrls) {'urls': url},
    ];

    final turnUrl = widget.turnServerUrl ?? AppConfig.webrtcTurnUrl;
    final turnUsername = widget.turnUsername ?? AppConfig.webrtcTurnUsername;
    final turnCredential =
        widget.turnCredential ?? AppConfig.webrtcTurnCredential;

    if (turnUrl != null &&
        turnUrl.trim().isNotEmpty &&
        turnUsername != null &&
        turnUsername.trim().isNotEmpty &&
        turnCredential != null &&
        turnCredential.trim().isNotEmpty) {
      iceServers.add({
        'urls': turnUrl,
        'username': turnUsername,
        'credential': turnCredential,
      });
    }

    return <String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceTransportPolicy': 'all',
    };
  }

  @override
  Widget build(BuildContext context) {
    final stateLabel = _statusMessage ?? _defaultStatusLabel();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: CommunicationPalette.backgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _peerName,
                            style: CommunicationPalette.titleStyle(size: 24),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stateLabel,
                            style: CommunicationPalette.bodyStyle(
                              size: 13,
                              color: CommunicationPalette.textMutedBlue,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildRemoteSurface()),
                      if (_isVideoCall)
                        Positioned(
                          right: 12,
                          top: 12,
                          width: 124,
                          height: 170,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              color: const Color(0xFF122740),
                              child: RTCVideoView(
                                _localRenderer,
                                mirror: true,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: widget.isIncoming && !_acceptedIncoming
                    ? _IncomingActions(
                        isVideo: _isVideoCall,
                        onAccept: _acceptIncomingCall,
                        onReject: _rejectIncomingCall,
                      )
                    : _ActiveActions(
                        isVideo: _isVideoCall,
                        muted: _muted,
                        cameraOff: _cameraOff,
                        onToggleMute: _toggleMute,
                        onToggleCamera: _toggleCamera,
                        onEndCall: _endCallFromUi,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteSurface() {
    if (_isVideoCall && _remoteRenderer.srcObject != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: RTCVideoView(
          _remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF10243D).withValues(alpha: 0.95),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF213A59),
                border: Border.all(color: const Color(0xFF57D7D4), width: 1.4),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isVideoCall
                  ? 'Waiting for remote video...'
                  : 'Audio call in progress',
              style: CommunicationPalette.bodyStyle(
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _defaultStatusLabel() {
    switch (_state) {
      case _CallUiState.connecting:
        return 'Connecting...';
      case _CallUiState.ringing:
        return 'Ringing...';
      case _CallUiState.incoming:
        return 'Incoming call';
      case _CallUiState.active:
        return 'In call';
      case _CallUiState.ended:
        return 'Call ended';
      case _CallUiState.failed:
        return 'Call failed';
    }
  }
}

class _IncomingActions extends StatelessWidget {
  const _IncomingActions({
    required this.isVideo,
    required this.onAccept,
    required this.onReject,
  });

  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.call_end_rounded,
            color: const Color(0xFFE14B5A),
            label: 'Reject',
            onTap: onReject,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            color: const Color(0xFF4D90FF),
            label: 'Accept',
            onTap: onAccept,
          ),
        ),
      ],
    );
  }
}

class _ActiveActions extends StatelessWidget {
  const _ActiveActions({
    required this.isVideo,
    required this.muted,
    required this.cameraOff,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onEndCall,
  });

  final bool isVideo;
  final bool muted;
  final bool cameraOff;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: muted ? const Color(0xFF6C89A8) : const Color(0xFF27466E),
            label: muted ? 'Unmute' : 'Mute',
            onTap: onToggleMute,
          ),
        ),
        if (isVideo) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: cameraOff
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              color: cameraOff
                  ? const Color(0xFF6C89A8)
                  : const Color(0xFF27466E),
              label: cameraOff ? 'Camera on' : 'Camera off',
              onTap: onToggleCamera,
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.call_end_rounded,
            color: const Color(0xFFE14B5A),
            label: 'End',
            onTap: onEndCall,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CommunicationPalette.bodyStyle(
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
