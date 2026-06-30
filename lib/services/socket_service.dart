import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../models/match_request.dart';

enum SocketEventType {
  connected,
  disconnected,
  connectError,
  matchFound,
  callAccepted,
  callRejected,
  roomLeft,
  chatMessage,
  typing,
  stopTyping,
  genericError,
}

class SocketEvent {
  final SocketEventType type;
  final dynamic data;

  SocketEvent(this.type, [this.data]);
}

class SocketService {
  io.Socket? _socket;
  final _controller = StreamController<SocketEvent>.broadcast();

  Stream<SocketEvent> get events => _controller.stream;

  bool get isConnected => _socket?.connected ?? false;

  void init() {
    if (_socket != null) {
      return;
    }

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.on('connect', (_) {
      _controller.add(SocketEvent(SocketEventType.connected));
    });

    _socket?.on('disconnect', (_) {
      _controller.add(SocketEvent(SocketEventType.disconnected));
    });

    _socket?.on('connect_error', (error) {
      _controller.add(SocketEvent(SocketEventType.connectError, error));
    });

    _socket?.on('error', (error) {
      _controller.add(SocketEvent(SocketEventType.genericError, error));
    });

    _socket?.on('match_found', (data) {
      _controller.add(SocketEvent(SocketEventType.matchFound, data));
    });

    _socket?.on('call_accepted', (data) {
      _controller.add(SocketEvent(SocketEventType.callAccepted, data));
    });

    _socket?.on('call_rejected', (data) {
      _controller.add(SocketEvent(SocketEventType.callRejected, data));
    });

    _socket?.on('room_left', (data) {
      _controller.add(SocketEvent(SocketEventType.roomLeft, data));
    });

    _socket?.on('receive_message', (data) {
      _controller.add(SocketEvent(SocketEventType.chatMessage, data));
    });

    _socket?.on('typing', (data) {
      _controller.add(SocketEvent(SocketEventType.typing, data));
    });

    _socket?.on('stop_typing', (data) {
      _controller.add(SocketEvent(SocketEventType.stopTyping, data));
    });
  }

  void connect() {
    if (_socket == null) {
      init();
    }
    if (_socket?.connected != true) {
      _socket?.connect();
    }
  }

  void disconnect() {
    if (_socket?.connected == true) {
      _socket?.disconnect();
    }
  }

  void emitFindMatch(MatchRequest request) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('find_match', request.toJson());
  }

  void emitAcceptCall(String roomID) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('accept_call', {'roomID': roomID});
  }

  void emitRejectCall(String roomID) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('reject_call', {'roomID': roomID});
  }

  void emitLeaveRoom(String roomID) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('leave_room', {'roomID': roomID});
  }

  void emitChatMessage(String roomID, Map<String, dynamic> message) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('send_message', {
      'roomID': roomID,
      ...message,
    });
  }

  void emitTyping(String roomID) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('typing', {'roomID': roomID});
  }

  void emitStopTyping(String roomID) {
    if (_socket == null) {
      throw StateError('SocketService has not been initialized.');
    }

    if (!_socket!.connected) {
      throw StateError('Socket is not connected.');
    }

    _socket?.emit('stop_typing', {'roomID': roomID});
  }

  void dispose() {
    _socket?.dispose();
    _controller.close();
  }
}
