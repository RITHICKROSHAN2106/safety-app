class AiChatMessage {
  final String role;
  final String text;
  final DateTime timestamp;

  const AiChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => role == 'user';

  Map<String, String> toJson() => {
        'role': role,
        'text': text,
      };
}