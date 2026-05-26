enum ChatRole { user, assistant }

enum ChatInputType { text, voice }

class ChatMessage {
  final ChatRole role;
  final String content;
  final ChatInputType inputType;
  final DateTime timestamp;
  final int? audioDurationSeconds;

  ChatMessage({
    required this.role,
    required this.content,
    this.inputType = ChatInputType.text,
    DateTime? timestamp,
    this.audioDurationSeconds,
  }) : timestamp = timestamp ?? DateTime.now();
}
