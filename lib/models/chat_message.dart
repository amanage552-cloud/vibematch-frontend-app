class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final String time;

  ChatMessage({
    required this.sender,
    required this.message,
    DateTime? timestamp,
    String? time,
  })  : timestamp = timestamp ?? DateTime.now(),
        time = time ?? formatTime(timestamp ?? DateTime.now());

  static String formatTime(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now();

    return ChatMessage(
      sender: json['sender']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      timestamp: timestamp,
      time: json['time']?.toString() ?? formatTime(timestamp),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'time': time,
    };
  }
}
