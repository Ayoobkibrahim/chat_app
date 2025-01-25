class ChatMessage {
  final String id;
  final String content;
  final String type; // 'chat', 'order', 'audio', or 'file'
  final String? filePath; // For audio or file attachments
  final String status; // 'Approved', 'Declined', 'Pending', etc.
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    this.filePath,
    required this.status,
    required this.timestamp,
  });
}
