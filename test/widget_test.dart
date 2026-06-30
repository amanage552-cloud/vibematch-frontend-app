import 'package:flutter_test/flutter_test.dart';

import 'package:vibematch_app/models/chat_message.dart';

void main() {
  test('chat message payload includes a formatted time label', () {
    final timestamp = DateTime(2024, 1, 1, 11, 9);
    final message = ChatMessage(
      sender: 'You',
      message: 'Hello',
      timestamp: timestamp,
    );

    final payload = message.toJson();

    expect(payload['time'], '11:09 AM');
  });
}
