import 'package:chat_app/feature/auth/view_model/login_view_model.dart';
import 'package:flutter/material.dart';

class LoginView extends StatelessWidget {
  final LoginViewModel viewModel = LoginViewModel();

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Column(
        children: [
          TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Username')),
          TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password')),
          ElevatedButton(
            onPressed: () async {
              if (await viewModel.login(usernameController.text, passwordController.text)) {
                Navigator.pushReplacementNamed(context, '/chat');
              }
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}
