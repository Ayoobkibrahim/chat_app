class ChatMessage {
  final String type; // "text", "voice", or "file"
  final String? content; // For text messages
  final String? filePath; // For voice and file messages
  final String? fileName; // For file messages
  final String timestamp;
  final bool isSent;
  final String status; // "Pending", "Sent", "Approved", etc.
  final bool isRead;
  final String messageType; // "chat" or "order"
  final Duration? duration; // For voice messages
  final String? transcript; // For voice messages
  final List<OrderItem>? orderList; // For voice messages
  final String? orderNo; // For order messages
  final String? approvalTime; // For approved orders

  ChatMessage({
    required this.type,
    this.content,
    this.filePath,
    this.fileName,
    required this.timestamp,
    required this.isSent,
    required this.status,
    required this.isRead,
    required this.messageType,
    this.duration,
    this.transcript,
    this.orderList,
    this.orderNo,
    this.approvalTime,
  });
}

class OrderItem {
  final String item;
  final String quantity;
  final int time; // Time duration in seconds

  OrderItem({
    required this.item,
    required this.quantity,
    required this.time,
  });
}
