import 'package:flutter/material.dart';
import '../model/chat_model.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final List<ChatMessage> _filteredMessages = [];
  String _currentFilter = "All";

  List<ChatMessage> get messages => _filteredMessages.isEmpty ? _messages : _filteredMessages;
  String get currentFilter => _currentFilter;

  // Add a new message
  void addMessage(String content, String type, {String? filePath, String status = 'Pending'}) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      filePath: filePath,
      status: status,
      timestamp: DateTime.now(),
    );
    _messages.add(message);
    applyFilter(_currentFilter);
    notifyListeners();
  }

  // Apply a filter to messages
  void applyFilter(String filter) {
    _currentFilter = filter;
    if (filter == "All") {
      _filteredMessages.clear();
    } else {
      _filteredMessages.clear();
      _filteredMessages.addAll(
        _messages.where((msg) => msg.status == filter),
      );
    }
    notifyListeners();
  }

  // Delete a message by ID
  void deleteMessage(String id) {
    _messages.removeWhere((msg) => msg.id == id);
    notifyListeners();
  }
}
