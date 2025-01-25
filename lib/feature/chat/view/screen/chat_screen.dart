import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Duration recordingDuration = Duration.zero;

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
      final filePath = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
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
    if (!isPlaying) {
      setState(() {
        isPlaying = true;
      });
      await _player.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          setState(() {
            isPlaying = false;
          });
        },
      );
    }
  }

  Future<void> _stopAudio() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() {
        isPlaying = false;
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
        return const Icon(Icons.access_time, color: Colors.orange, size: 14); // Clock icon
      case "Sent":
        return const Icon(Icons.check, color: Colors.blue, size: 14); // One tick
      case "Unread":
        return const Icon(Icons.done_all, color: Colors.grey, size: 14); // Double tick (unread)
      case "Approved":
        return const Icon(Icons.done_all, color: Colors.green, size: 14); // Double tick (approved)
      case "Declined":
        return const Icon(Icons.close, color: Colors.red, size: 14); // Cross icon
      default:
        return const Icon(Icons.check, color: Colors.green, size: 14); // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              // backgroundImage: AssetImage('assets/images/profile.png'),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Michael Knight", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Active now", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Messages List
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final message = messages[index];
                if (message["type"] == "voice") {
                  return _buildVoiceMessage(message);
                } else {
                  return _buildTextMessage(message);
                }
              },
            ),
          ),

          // Input Section
          _buildInputSection(),
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(filter),
                selected: currentFilter == filter,
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

  Widget _buildTextMessage(Map<String, dynamic> message) {
    return Align(
      alignment: message["isSent"] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: message["isSent"] ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message["content"],
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message["timestamp"],
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(width: 5),
                _getStatusIcon(message["status"]), // Status Icon
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(Map<String, dynamic> message) {
    return Align(
      alignment: message["isSent"] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white),
              onPressed: () {
                if (isPlaying) {
                  _stopAudio();
                } else {
                  _playAudio(message["filePath"]);
                }
              },
            ),
            const SizedBox(width: 10),
            Text(
              "Voice (${_formatDuration(Duration(seconds: message["duration"]))})",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 5),
            _getStatusIcon(message["status"]), // Status Icon
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.blue),
            onPressed: () {
              if (isRecording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            },
          ),
          if (recordedFilePath != null)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      recordedFilePath = null;
                      recordingDuration = Duration.zero;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () {
                    if (recordedFilePath != null) {
                      setState(() {
                        messages.add({
                          "type": "voice",
                          "filePath": recordedFilePath!,
                          "timestamp": _currentTimestamp(),
                          "isSent": true,
                          "status": "Pending",
                          "duration": recordingDuration.inSeconds,
                        });
                        recordedFilePath = null;
                        recordingDuration = Duration.zero;
                      });

                      // Simulate status updates for voice messages
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
                  },
                ),
              ],
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                setState(() {
                  messages.add({
                    "type": "text",
                    "content": _messageController.text.trim(),
                    "timestamp": _currentTimestamp(),
                    "isSent": true,
                    "status": "Pending",
                    "isRead": false,
                  });
                });
                _messageController.clear();

                // Simulate status updates for text messages
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
            },
          ),
        ],
      ),
    );
  }

  String _currentTimestamp() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }
}
