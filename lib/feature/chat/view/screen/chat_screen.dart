import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  String currentFilter = "All";

  bool isRecording = false;
  bool isPlaying = false;
  String? recordedFilePath;
  String? attachedFilePath;
  String? attachedFileName;
  String? currentPlayingPath; // Tracks the current audio being played
  Duration recordingDuration = Duration.zero;
  Duration audioProgress = Duration.zero;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final micPermission = await Permission.microphone.request();
    if (micPermission != PermissionStatus.granted) {
      throw RecordingPermissionException("Microphone permission not granted");
    }
    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 200));
  }

  Future<void> _startRecording() async {
    if (!_recorder.isRecording) {
      final directory = Directory.systemTemp;
      final filePath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      setState(() {
        recordedFilePath = filePath;
        isRecording = true;
        recordingDuration = Duration.zero;
      });

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      _recorder.onProgress?.listen((event) {
        setState(() {
          recordingDuration = event.duration;
        });
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
      setState(() {
        isRecording = false;
      });
    }
  }

  Future<void> _playAudio(String filePath) async {
    if (!isPlaying || currentPlayingPath != filePath) {
      // Stop current audio if a different file is being played
      if (isPlaying && currentPlayingPath != filePath) {
        await _stopAudio();
      }

      setState(() {
        isPlaying = true;
        currentPlayingPath = filePath; // Update currently playing file
        audioProgress = Duration.zero;
      });

      await _player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            isPlaying = false;
            currentPlayingPath = null; // Reset when playback finishes
            audioProgress = Duration.zero;
          });
        },
      );

      _player.onProgress?.listen((event) {
        setState(() {
          audioProgress = event.position;
        });
      });
    }
  }

  Future<void> _stopAudio() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() {
        isPlaying = false;
        currentPlayingPath = null; // Reset when audio is stopped
        audioProgress = Duration.zero;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        attachedFilePath = result.files.single.path;
        attachedFileName = result.files.single.name;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case "Pending":
        return const Icon(Icons.access_time, color: Colors.orange, size: 14);
      case "Sent":
        return const Icon(Icons.check, color: Colors.blue, size: 14);
      case "Unread":
        return const Icon(Icons.done_all, color: Colors.grey, size: 14);
      case "Approved":
        return const Icon(Icons.done_all, color: Colors.green, size: 14);
      case "Declined":
        return const Icon(Icons.close, color: Colors.red, size: 14);
      default:
        return const Icon(Icons.check, color: Colors.green, size: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Michael Knight",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Active now",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredMessages().length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final message = _filteredMessages()[index];
                if (message["type"] == "voice") {
                  return _buildVoiceMessage(message);
                } else if (message["type"] == "file") {
                  return _buildFileMessage(message);
                } else {
                  return _buildTextMessage(message);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildInputSection(),
          ),
          if (_shouldShowSendButtons())
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _sendMessage("chat");
                  },
                  child: const Text("Send as Chat"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _sendMessage("order");
                  },
                  child: const Text("Send as Order"),
                ),
              ],
            ),
            const SizedBox(height: 15,)
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Unread", "Approved", "Declined", "Pending"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            Color backgroundColor;
            Color textColor;
            switch (filter) {
              case "All":
                backgroundColor = Colors.black;
                textColor = Colors.white;
                break;
              case "Unread":
                backgroundColor = Colors.white;
                textColor = Colors.black;
                break;
              case "Approved":
                backgroundColor = Colors.green.withOpacity(0.2);
                textColor = Colors.green;
                break;
              case "Declined":
                backgroundColor = Colors.red.withOpacity(0.5);
                textColor = Colors.red;
                break;
              case "Pending":
                backgroundColor = Colors.orange.withOpacity(0.3);
                textColor = Colors.orange;
                break;
              default:
                backgroundColor = Colors.grey;
                textColor = Colors.white;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(color: textColor),
                ),
                selected: currentFilter == filter,
                selectedColor: backgroundColor,
                backgroundColor: backgroundColor,
                onSelected: (_) {
                  setState(() {
                    currentFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredMessages() {
    if (currentFilter == "All") return messages;
    if (currentFilter == "Unread") {
      return messages.where((msg) => msg["isRead"] == false).toList();
    }
    return messages.where((msg) => msg["status"] == currentFilter).toList();
  }

  Widget _buildTextMessage(Map<String, dynamic> message) {
    return GestureDetector(
      onLongPress: () {
        _showActionMenu(message);
      },
      child: Align(
        alignment:
            message["isSent"] ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: message["isSent"] ? Colors.white : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(2, 2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message["content"],
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message["timestamp"],
                    style: const TextStyle(color: Colors.black, fontSize: 10),
                  ),
                  const SizedBox(width: 5),
                  _getStatusIcon(message["status"]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionMenu(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reorder),
              title: const Text('Quick Reorder'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Assign to Salesmen'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVoiceMessage(Map<String, dynamic> message) {
    return Align(
      alignment:
          message["isSent"] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying && currentPlayingPath == message["filePath"]
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.blue,
              ),
              onPressed: () {
                if (isPlaying && currentPlayingPath == message["filePath"]) {
                  _stopAudio();
                } else {
                  _playAudio(message["filePath"]);
                }
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value:
                        (isPlaying && currentPlayingPath == message["filePath"])
                            ? audioProgress.inSeconds / message["duration"]
                            : 0.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(audioProgress),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(Duration(seconds: message["duration"])),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            _getStatusIcon(message["status"]),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(Map<String, dynamic> message) {
    return GestureDetector(
      onLongPress: () {
        _showActionMenu(message);
      },
      child: Align(
        alignment:
            message["isSent"] ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message["fileName"] ?? "Attached File",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    message["timestamp"] ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(width: 5),
                  _getStatusIcon(message["status"]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(2, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type here...",
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.blue),
            onPressed: _pickFile,
          ),
          IconButton(
            icon: Icon(
              isRecording ? Icons.stop : Icons.mic,
              color: Colors.blue,
            ),
            onPressed: () {
              if (isRecording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            },
          ),
          
        ],
      ),
    );
  }

  bool _shouldShowSendButtons() {
    return _messageController.text.trim().isNotEmpty ||
        attachedFilePath != null ||
        recordedFilePath != null;
  }

  void _sendMessage(String type) {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add({
          "type": "text",
          "content": _messageController.text.trim(),
          "timestamp": _currentTimestamp(),
          "isSent": true,
          "status": "Pending",
          "isRead": false,
          "messageType": type,
        });
        _messageController.clear();
      });
    }

    if (recordedFilePath != null) {
      setState(() {
        messages.add({
          "type": "voice",
          "filePath": recordedFilePath,
          "timestamp": _currentTimestamp(),
          "isSent": true,
          "status": "Pending",
          "duration": recordingDuration.inSeconds,
          "messageType": type,
        });
        recordedFilePath = null;
        recordingDuration = Duration.zero;
      });
    }

    if (attachedFilePath != null) {
      setState(() {
        messages.add({
          "type": "file",
          "fileName": attachedFileName,
          "timestamp": _currentTimestamp(),
          "isSent": true,
          "status": "Pending",
          "messageType": type,
        });
        attachedFilePath = null;
        attachedFileName = null;
      });
    }

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.last["status"] = "Sent";
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        messages.last["status"] = "Approved";
      });
    });
  }

  String _currentTimestamp() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }
}
