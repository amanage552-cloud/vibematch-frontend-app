import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/match_request.dart';
import '../services/socket_service.dart';

class MatchProvider extends ChangeNotifier {
  final SocketService _socketService;
  StreamSubscription<SocketEvent>? _socketSubscription;
  Timer? _matchTimeout;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController chatController = TextEditingController();
  final List<ChatMessage> _chatHistory = [];
  String _selectedGender = 'Male';
  String _selectedPreference = 'All';
  bool _isSearching = false;
  bool _socketConnected = false;
  bool _partnerTyping = false;
  String _statusMessage = 'Find Your Perfect Vibe ✨';
  String _serverStatus = 'Disconnected';
  String? _matchRoomId;
  Uint8List? _profileImageBytes;
  String? _incomingCallRoomId;
  String? _incomingCallPartnerName;
  String? _incomingCallPartnerImageBase64;

  MatchProvider({SocketService? socketService})
      : _socketService = socketService ?? SocketService();

  bool get isSearching => _isSearching;
  bool get socketConnected => _socketConnected;
  String get statusMessage => _statusMessage;
  String get serverStatus => _serverStatus;
  String? get matchRoomId => _matchRoomId;
  String get selectedGender => _selectedGender;
  String get selectedPreference => _selectedPreference;
  TextEditingController get chatTextController => chatController;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  bool get partnerTyping => _partnerTyping;
  Uint8List? get profileImageBytes => _profileImageBytes;
  String? get profileImageBase64 =>
      _profileImageBytes == null ? null : base64Encode(_profileImageBytes!);
  bool get hasIncomingCall => _incomingCallRoomId != null;
  String? get incomingCallPartnerName => _incomingCallPartnerName;
  String? get incomingCallPartnerImageBase64 => _incomingCallPartnerImageBase64;
  Uint8List? get incomingCallPartnerImageBytes {
    final imageBase64 = _incomingCallPartnerImageBase64;
    if (imageBase64 == null || imageBase64.isEmpty) {
      return null;
    }

    try {
      return base64Decode(imageBase64);
    } catch (_) {
      return null;
    }
  }

  void init() {
    _socketService.init();
    _subscribeSocketEvents();
    _updateConnectionStatus(false, 'Disconnected');
    _socketService.connect();
  }

  void _subscribeSocketEvents() {
    _socketSubscription = _socketService.events.listen((event) {
      switch (event.type) {
        case SocketEventType.connected:
          _handleConnected();
          break;
        case SocketEventType.disconnected:
          _handleDisconnected();
          break;
        case SocketEventType.connectError:
          _handleConnectError(event.data);
          break;
        case SocketEventType.genericError:
          _handleGenericError(event.data);
          break;
        case SocketEventType.matchFound:
          _handleMatchFound(event.data);
          break;
        case SocketEventType.callAccepted:
          _handleCallAccepted(event.data);
          break;
        case SocketEventType.callRejected:
          _handleCallRejected(event.data);
          break;
        case SocketEventType.roomLeft:
          _handleRoomLeft(event.data);
          break;
        case SocketEventType.chatMessage:
          _handleChatMessage(event.data);
          break;
        case SocketEventType.typing:
          _handleTyping();
          break;
        case SocketEventType.stopTyping:
          _handleStopTyping();
          break;
      }
    });
  }

  void _handleConnected() {
    _cancelMatchTimeout();
    _updateConnectionStatus(true, 'Connected');
    if (!_isSearching) {
      _statusMessage = 'Connected. Enter details to find your vibe.';
    }
    notifyListeners();
  }

  void _handleDisconnected() {
    _cancelMatchTimeout();
    _updateConnectionStatus(false, 'Disconnected');
    if (_isSearching) {
      _isSearching = false;
      _statusMessage = 'Connection lost while searching. Please retry.';
    }
    notifyListeners();
  }

  void _handleConnectError(dynamic error) {
    _cancelMatchTimeout();
    _updateConnectionStatus(false, 'Disconnected');
    _isSearching = false;
    _statusMessage = 'Unable to connect to match server. Please try again.';
    notifyListeners();
  }

  void _handleGenericError(dynamic error) {
    _cancelMatchTimeout();
    _isSearching = false;
    _statusMessage = 'A socket error occurred. Please retry.';
    notifyListeners();
  }

  void _handleMatchFound(dynamic data) {
    _cancelMatchTimeout();
    _isSearching = false;
    _statusMessage = 'Incoming call...';

    if (data is Map) {
      _incomingCallRoomId = data['roomID']?.toString();
      _incomingCallPartnerName = data['partnerName']?.toString();
      _incomingCallPartnerImageBase64 = data['partnerImageBase64']?.toString();
    } else {
      _incomingCallRoomId = data?.toString();
      _incomingCallPartnerName = null;
      _incomingCallPartnerImageBase64 = null;
    }

    notifyListeners();
  }

  void _handleCallAccepted(dynamic data) {
    final roomId = data is Map ? data['roomID']?.toString() : data?.toString();
    if (roomId == null || roomId.isEmpty) {
      return;
    }

    _matchRoomId = roomId;
    _incomingCallRoomId = null;
    _incomingCallPartnerName = null;
    _incomingCallPartnerImageBase64 = null;
    _statusMessage = 'Call connected';
    notifyListeners();
  }

  void _handleCallRejected(dynamic data) {
    _clearIncomingCallState();
    _matchRoomId = null;
    _chatHistory.clear();
    _partnerTyping = false;
    _statusMessage = 'Partner declined. Looking for another match...';
    notifyListeners();
    startMatching();
  }

  void _handleRoomLeft(dynamic data) {
    _clearIncomingCallState();
    _matchRoomId = null;
    _chatHistory.clear();
    _partnerTyping = false;
    _statusMessage = 'Partner left. Finding another match...';
    notifyListeners();
    startMatching();
  }

  void _handleChatMessage(dynamic data) {
    if (data is Map) {
      final chatMessage = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      _chatHistory.add(chatMessage);
      notifyListeners();
    }
  }

  void _handleTyping() {
    if (!_partnerTyping) {
      _partnerTyping = true;
      notifyListeners();
    }
  }

  void _handleStopTyping() {
    if (_partnerTyping) {
      _partnerTyping = false;
      notifyListeners();
    }
  }

  void startMatching() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _statusMessage = 'Please enter your name first.';
      notifyListeners();
      return;
    }

    if (!_socketConnected) {
      _statusMessage = 'Not connected. Retry the connection and try again.';
      notifyListeners();
      _socketService.connect();
      return;
    }

    final request = MatchRequest(
      name: name,
      gender: _selectedGender,
      preference: _selectedPreference,
      profileImageBase64: profileImageBase64,
    );

    _isSearching = true;
    _statusMessage = 'Searching based on your filters... 🔍';
    notifyListeners();

    try {
      _socketService.emitFindMatch(request);
    } catch (error) {
      _isSearching = false;
      _statusMessage = 'Unable to start matching. Please retry.';
      notifyListeners();
      return;
    }

    _startMatchTimeout();
  }

  void _startMatchTimeout() {
    _cancelMatchTimeout();
    _matchTimeout = Timer(const Duration(seconds: 15), () {
      _isSearching = false;
      _statusMessage = 'No match found yet. Please try again or adjust filters.';
      notifyListeners();
    });
  }

  void _cancelMatchTimeout() {
    _matchTimeout?.cancel();
    _matchTimeout = null;
  }

  void retryConnection() {
    _statusMessage = 'Retrying connection...';
    notifyListeners();
    _socketService.connect();
  }

  void sendChatMessage() {
    final matchRoom = _matchRoomId;
    final text = chatController.text.trim();
    final sender = nameController.text.trim().isEmpty ? 'You' : nameController.text.trim();

    if (matchRoom == null || text.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final message = ChatMessage(
      sender: sender,
      message: text,
      timestamp: now,
      time: ChatMessage.formatTime(now),
    );
    _chatHistory.add(message);
    notifyListeners();

    _socketService.emitChatMessage(matchRoom, message.toJson());
    chatController.clear();
    if (matchRoom.isNotEmpty) {
      _socketService.emitStopTyping(matchRoom);
    }
  }

  void updateGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void updatePreference(String preference) {
    _selectedPreference = preference;
    notifyListeners();
  }

  void setProfileImageBytes(Uint8List? bytes) {
    _profileImageBytes = bytes;
    notifyListeners();
  }

  void acceptIncomingCall() {
    final roomId = _incomingCallRoomId;
    if (roomId == null || roomId.isEmpty) {
      return;
    }

    _statusMessage = 'Connecting to partner...';
    notifyListeners();
    _socketService.emitAcceptCall(roomId);
  }

  void rejectIncomingCall() {
    final roomId = _incomingCallRoomId;
    if (roomId != null && roomId.isNotEmpty) {
      _socketService.emitRejectCall(roomId);
    }

    _clearIncomingCallState();
    _matchRoomId = null;
    _chatHistory.clear();
    _partnerTyping = false;
    _statusMessage = 'Waiting for partner...';
    notifyListeners();
    startMatching();
  }

  void nextVibe() {
    final roomId = _matchRoomId;
    if (roomId != null && roomId.isNotEmpty) {
      _socketService.emitLeaveRoom(roomId);
    }

    _matchRoomId = null;
    _chatHistory.clear();
    chatController.clear();
    _partnerTyping = false;
    _clearIncomingCallState();
    _isSearching = true;
    _statusMessage = 'Finding your next vibe...';
    notifyListeners();
    startMatching();
  }

  void nextPartner() => nextVibe();

  void clearMatch() {
    _matchRoomId = null;
    _chatHistory.clear();
    chatController.clear();
    _partnerTyping = false;
    _clearIncomingCallState();
    notifyListeners();
  }

  void _clearIncomingCallState() {
    _incomingCallRoomId = null;
    _incomingCallPartnerName = null;
    _incomingCallPartnerImageBase64 = null;
  }

  @override
  void dispose() {
    _matchTimeout?.cancel();
    _socketSubscription?.cancel();
    _socketService.dispose();
    nameController.dispose();
    chatController.dispose();
    super.dispose();
  }

  void _updateConnectionStatus(bool connected, String status) {
    _socketConnected = connected;
    _serverStatus = status;
  }

  void emitTypingIfNeeded() {
    final matchRoom = _matchRoomId;
    if (matchRoom != null && matchRoom.isNotEmpty) {
      _socketService.emitTyping(matchRoom);
    }
  }

  void emitStopTypingIfNeeded() {
    final matchRoom = _matchRoomId;
    if (matchRoom != null && matchRoom.isNotEmpty) {
      _socketService.emitStopTyping(matchRoom);
    }
  }
}
