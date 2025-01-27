class ChatMessage {
  final String type; 
  final String? content; 
  final String? filePath; 
  final String? fileName; 
  final String timestamp;
  final bool isSent;
  final String status; 
  final bool isRead;
  final String messageType; 
  final Duration? duration; 
  final String? transcript; 
  final List<OrderItem>? orderList; 
  final String? orderNo; 
  final String? approvalTime; 

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
  final int time; 

  OrderItem({
    required this.item,
    required this.quantity,
    required this.time,
  });
}
