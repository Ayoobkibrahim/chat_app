import 'package:chat_app/feature/chat/view/widgets/expandable_selection_widget.dart';
import 'package:chat_app/feature/chat/view_model/chat_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatViewModel>(
          builder: (context, viewModel, child) {
            return Row(
              children: [
                const CircleAvatar(),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Active now",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildMessageList(),
          _buildInputSection(),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        final currentFilter = viewModel.currentFilter;
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
                      viewModel.setFilter(filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        final messages = viewModel.getFilteredMessages();
        return Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              final message = messages[index];

              if (message["type"] == "voice") {
                return _buildVoiceMessage(context, message, viewModel);
              } else if (message["type"] == "file") {
                final filePath = message["filePath"];
                final fileName = message["fileName"];
                return _buildSelectedFilePreview(
                  context,
                  filePath,
                  fileName,
                  () {
                    viewModel.removeFileMessage(message);
                  },
                );
              } else {
                return _buildTextMessage(context, message);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedFilePreview(
    BuildContext context,
    String? filePath,
    String? fileName,
    VoidCallback onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName ?? "Unknown File",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context, Map<String, dynamic> message) {
    return GestureDetector(
      onLongPress: () {},
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
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
                message["content"] ?? "",
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message["timestamp"] ?? "",
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
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
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          final isRecording = viewModel.isRecording;
          final recordedFilePath = viewModel.recordedFilePath;
          final messageController = viewModel.messageController;
          final shouldShowSendButtons = viewModel.shouldShowSendButtons();
          final attachedFilePath = viewModel.attachedFilePath;
          final attachedFileName = viewModel.attachedFileName;

          return Column(
            children: [
              if (attachedFilePath != null && attachedFileName != null)
                _buildSelectedFilePreview(
                  context,
                  attachedFilePath,
                  attachedFileName,
                  viewModel.clearAttachedFile,
                ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                child: Column(
                  children: [
                    if (isRecording || recordedFilePath != null)
                      _buildAudioRecordingUI(viewModel),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: const InputDecoration(
                                hintText: "Type here...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon:
                              const Icon(Icons.attach_file, color: Colors.blue),
                          onPressed: () {
                            viewModel.pickFile();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (isRecording) {
                              viewModel.stopRecording();
                            } else {
                              viewModel.startRecording();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (shouldShowSendButtons) _buildSendButtons(viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSendButtons(ChatViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            viewModel.sendMessage("chat");
          },
          icon: const Icon(Icons.send, color: Colors.white),
          label: const Text("Send as Chat"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            viewModel.sendMessage("order");
          },
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: const Text("Send as Order"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceMessage(BuildContext context, Map<String, dynamic> message,
      ChatViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        _showActionMenu(context, message, viewModel);
      },
      child: Align(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      viewModel.isPlaying &&
                              viewModel.currentPlayingPath ==
                                  message["filePath"]
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      if (viewModel.isPlaying &&
                          viewModel.currentPlayingPath == message["filePath"]) {
                        viewModel.stopAudio();
                      } else {
                        viewModel.playAudio(message["filePath"]);
                      }
                    },
                  ),
                  Expanded(
                    child: _buildVoiceWave(
                      isRecording: viewModel.isRecording,
                      isPlaying: viewModel.isPlaying &&
                          viewModel.currentPlayingPath == message["filePath"],
                    ),
                  ),
                  Text(
                    _formatDuration(message["duration"]),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              if (message["messageType"] == "order") ...[
                const Divider(),
                const SizedBox(height: 10),
                if (message["transcript"] != null)
                  ExpandableSection(
                    title: "Transcript",
                    content: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message["transcript"]!,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ),
                const Divider(),
                const SizedBox(height: 10),
                if (message["messageType"] == "order" &&
                    message["orderList"] != null)
                  ExpandableSection(
                    title: "Order List",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (message["orderList"] as List<dynamic>)
                          .map((order) => _buildOrderListItem(order))
                          .toList(),
                    ),
                  ),
                const Divider(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_rounded),
                      Text(
                        "Order Number: ${message["orderNo"] ?? "N/A"}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (message["messageType"] == "order")
                  const SizedBox(height: 5),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Approved by DP on ${message["approvalTime"] ?? "N/A"}",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "v.1",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                const Divider(),
                const SizedBox(height: 5),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message["timestamp"] ?? "",
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 10),
                    ),
                    const SizedBox(width: 5),
                    _getStatusIcon(message["status"]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListItem(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              order["item"] ?? "Unknown Item",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              order["quantity"]?.toString() ?? "0",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 14, color: Colors.blue),
                const SizedBox(width: 5),
                Text(
                  order["time"]?.toString() ?? "0",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              // Handle edit action
            },
            child: const Icon(Icons.edit, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAudioRecordingUI(ChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              viewModel.isRecording
                  ? Icons.stop
                  : (viewModel.isPlaying ? Icons.pause : Icons.play_arrow),
              color: Colors.red,
            ),
            onPressed: () {
              if (viewModel.isRecording) {
                viewModel.stopRecording();
              } else if (viewModel.recordedFilePath != null) {
                if (viewModel.isPlaying) {
                  viewModel.stopAudio();
                } else {
                  viewModel.playAudio(viewModel.recordedFilePath!);
                }
              } else {
                viewModel.startRecording();
              }
            },
          ),
          if (viewModel.isRecording || viewModel.recordedFilePath != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoiceWave(
                    isRecording: viewModel.isRecording,
                    isPlaying: viewModel.isPlaying,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    viewModel.isRecording
                        ? viewModel.formatDuration(viewModel.recordingDuration)
                        : viewModel.formatDuration(viewModel.audioProgress),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          if (viewModel.recordedFilePath != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: viewModel.deleteRecording,
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceWave({
    required bool isRecording,
    required bool isPlaying,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final numberOfDots = (width / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            numberOfDots,
            (index) => AnimatedContainer(
              duration: Duration(milliseconds: 100 + (index % 5) * 50),
              curve: Curves.easeInOut,
              height: isRecording
                  ? _getWaveHeightForRecording(index)
                  : (isPlaying ? _getWaveHeightForPlayback(index) : 4),
              width: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isRecording || isPlaying ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getWaveHeightForRecording(int index) {
    final heights = [10.0, 16.0, 20.0, 16.0, 10.0];
    return heights[index % heights.length];
  }

  double _getWaveHeightForPlayback(int index) {
    final heights = [12.0, 18.0, 24.0, 18.0, 12.0];
    return heights[index % heights.length];
  }

  void _showActionMenu(BuildContext context, Map<String, dynamic> message,
      ChatViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.shareOrderDetails(message);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.insert_drive_file_rounded,
                          color: Colors.black),
                      SizedBox(width: 15),
                      Text(
                        'Quick Order',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_forward_sharp, color: Colors.black),
                      SizedBox(width: 15),
                      Text(
                        'Assign To Salesman',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.share, color: Colors.black),
                      SizedBox(width: 15),
                      Text(
                        'Share',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.black),
                      SizedBox(width: 15),
                      Text(
                        'Export',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getStatusIcon(String status) {
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
}
