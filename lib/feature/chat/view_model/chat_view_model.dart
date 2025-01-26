import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class ChatViewModel extends ChangeNotifier {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  String currentFilter = "All";
  String username = "Unknown User";

  bool isRecording = false;
  bool isPlaying = false;
  String? recordedFilePath;
  String? attachedFilePath;
  String? attachedFileName;
  String? currentPlayingPath;
  Duration recordingDuration = Duration.zero;
  Duration audioProgress = Duration.zero;

  ChatViewModel() {
    _initRecorder();
    _player.openPlayer();
    _fetchUsername();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsername() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? "Unknown User";
    notifyListeners();
  }

  Future<void> _initRecorder() async {
    final micPermission = await Permission.microphone.request();
    if (micPermission != PermissionStatus.granted) {
      throw RecordingPermissionException("Microphone permission not granted");
    }
    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 200));
  }

  Future<void> startRecording() async {
    if (!_recorder.isRecording) {
      final directory = Directory.systemTemp;
      final filePath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      recordedFilePath = filePath;
      isRecording = true;
      recordingDuration = Duration.zero;
      notifyListeners();

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      _recorder.onProgress?.listen((event) {
        recordingDuration = event.duration;
        notifyListeners();
      });
    }
  }

  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
      isRecording = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecording() async {
    if (recordedFilePath != null) {
      final file = File(recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      recordedFilePath = null;
      isRecording = false;
      recordingDuration = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> playAudio(String filePath) async {
    if (!isPlaying || currentPlayingPath != filePath) {
      if (isPlaying && currentPlayingPath != filePath) {
        await stopAudio();
      }

      isPlaying = true;
      currentPlayingPath = filePath;
      audioProgress = Duration.zero;
      notifyListeners();

      await _player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          isPlaying = false;
          currentPlayingPath = null;
          audioProgress = Duration.zero;
          notifyListeners();
        },
      );

      _player.onProgress?.listen((event) {
        audioProgress = event.position;
        notifyListeners();
      });
    }
  }

  Future<void> stopAudio() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      isPlaying = false;
      currentPlayingPath = null;
      audioProgress = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      attachedFilePath = result.files.single.path!;
      attachedFileName = result.files.single.name;
      notifyListeners();
    }
  }

  void removeFileMessage(Map<String, dynamic> message) {
    messages.remove(message);
    notifyListeners();
  }

  void clearAttachedFile() {
    attachedFilePath = null;
    attachedFileName = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> getFilteredMessages() {
    if (currentFilter == "All") return messages;
    if (currentFilter == "Unread") {
      return messages.where((msg) => msg["isRead"] == false).toList();
    }
    return messages.where((msg) => msg["status"] == currentFilter).toList();
  }

  void setFilter(String filter) {
    currentFilter = filter;
    notifyListeners();
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void sendMessage(String type) {
    bool messageAdded = false;

    if (messageController.text.trim().isNotEmpty) {
      messages.add({
        "type": "text",
        "content": messageController.text.trim(),
        "timestamp": _currentTimestamp(),
        "isSent": true,
        "status": "Pending",
        "isRead": false,
        "messageType": type,
      });
      messageController.clear();
      messageAdded = true;
    }

    if (recordedFilePath != null) {
      messages.add({
        "type": "voice",
        "filePath": recordedFilePath!,
        "timestamp": _currentTimestamp(),
        "isSent": true,
        "status": "Pending",
        "duration": recordingDuration.inSeconds,
        "messageType": type,
        if (type == "order") ...{
          "transcript":
              "Wanted To place an order forr a few minutes.Here's what i need First, 50 units of the classic leather wallet in balck,",
          "orderList": [
            {"item": "Milk", "quantity": "5 Packets"},
            {"item": "Butter", "quantity": "5 kg"},
            {"item": "Cheese", "quantity": "3 Crates"},
          ],
          "orderNo": "15544",
          "approvalTime": "02:30 PM, 15/07/2024",
        }
      });
      recordedFilePath = null;
      recordingDuration = Duration.zero;
      messageAdded = true;
    }

    if (attachedFilePath != null && attachedFileName != null) {
      messages.add({
        "type": "file",
        "fileName": attachedFileName ?? "Unknown File",
        "timestamp": _currentTimestamp(),
        "isSent": true,
        "status": "Pending",
        "messageType": type,
      });
      attachedFilePath = null;
      attachedFileName = null;
      messageAdded = true;
    }

    if (messageAdded) {
      notifyListeners();
      _updateMessageStatus(
          messages.length - 1, "Sent", const Duration(seconds: 1));
      _updateMessageStatus(
          messages.length - 1, "Approved", const Duration(seconds: 3));
    }
  }

  void _updateMessageStatus(int index, String newStatus, Duration delay) {
    Future.delayed(delay, () {
      if (index < messages.length) {
        messages[index]["status"] = newStatus;
        notifyListeners();
      }
    });
  }

  String _currentTimestamp() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  void shareOrderDetails(Map<String, dynamic> message) {
    final orderDetails = '''
Order No: ${message["orderNo"]}
Transcript: ${message["transcript"] ?? "N/A"}
Items:
${(message["orderList"] as List<dynamic>?)?.map((item) => "${item["item"]}: ${item["quantity"]}").join("\n") ?? "No items"}
Approval Time: ${message["approvalTime"] ?? "N/A"}
  ''';

    Share.share(orderDetails);
  }

  bool shouldShowSendButtons() {
    return messageController.text.trim().isNotEmpty ||
        recordedFilePath != null ||
        attachedFilePath != null;
  }
}
