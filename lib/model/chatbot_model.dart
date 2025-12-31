import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? videoUrl;

  ChatMessage({
    required this.text,
    required this.isBot,
    DateTime? timestamp,
    this.videoUrl,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isBot': isBot,
      'timestamp': timestamp.toIso8601String(),
      'videoUrl': videoUrl,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'],
      isBot: map['isBot'],
      videoUrl: map['videoUrl'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source));
}
