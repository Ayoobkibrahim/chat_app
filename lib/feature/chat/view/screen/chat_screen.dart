import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/feature/auth/view_model/login_view_model.dart';
import 'package:chat_app/configs/routes/routes_name.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<LoginViewModel>().logoutUser();
              Navigator.pushReplacementNamed(context, RoutesName.login);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to the Chat Screen!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
