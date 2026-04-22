class ChatMessage {
  final String role; // 'user' or 'ai'
  final String content;
  final Map<String, dynamic>? entities;

  ChatMessage({
    required this.role,
    required this.content,
    this.entities,
  });

  bool get isUser => role == 'user';
  bool get isAi => role == 'ai';
}
