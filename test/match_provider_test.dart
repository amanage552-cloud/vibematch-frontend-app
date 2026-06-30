import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibematch_app/models/match_request.dart';
import 'package:vibematch_app/providers/match_provider.dart';
import 'package:vibematch_app/services/socket_service.dart';

class FakeSocketService extends SocketService {
  final StreamController<SocketEvent> _testController = StreamController<SocketEvent>.broadcast();
  bool connected = false;
  String? lastLeaveRoomId;
  MatchRequest? lastFindMatchRequest;

  @override
  Stream<SocketEvent> get events => _testController.stream;

  @override
  bool get isConnected => connected;

  @override
  void init() {}

  @override
  void connect() {
    connected = true;
    _testController.add(SocketEvent(SocketEventType.connected));
  }

  @override
  void disconnect() {
    connected = false;
    _testController.add(SocketEvent(SocketEventType.disconnected));
  }

  @override
  void emitFindMatch(MatchRequest request) {
    lastFindMatchRequest = request;
  }

  @override
  void emitLeaveRoom(String roomID) {
    lastLeaveRoomId = roomID;
  }

  @override
  void dispose() {
    _testController.close();
  }
}

void main() {
  group('MatchProvider', () {
    test('nextVibe tears down room state and starts a new search', () async {
      final fakeSocket = FakeSocketService();
      final provider = MatchProvider(socketService: fakeSocket);

      provider.nameController.text = 'Ada';
      provider.setProfileImageBytes(Uint8List.fromList([1, 2, 3]));
      provider.init();

      provider.startMatching();
      provider.nextVibe();

      expect(provider.matchRoomId, isNull);
      expect(provider.isSearching, isTrue);
      expect(fakeSocket.lastLeaveRoomId, isNull);
      expect(fakeSocket.lastFindMatchRequest, isNotNull);
      expect(fakeSocket.lastFindMatchRequest!.name, 'Ada');
    });
  });
}
