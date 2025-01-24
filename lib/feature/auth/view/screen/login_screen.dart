import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/feature/auth/view_model/login_view_model.dart';
import 'package:chat_app/configs/routes/routes_name.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loginInputContainer(
              controller: _usernameController,
              labelText: 'Username',
              isPassword: false,
            ),
            const SizedBox(height: 20),

            loginInputContainer(
              controller: _passwordController,
              labelText: 'Password',
              isPassword: true,
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                String username = _usernameController.text.trim();
                String password = _passwordController.text.trim();

                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill in both fields")),
                  );
                  return;
                }

             
                await context.read<LoginViewModel>().loginUser(username);
                Navigator.pushReplacementNamed(context, RoutesName.chat);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }


  Widget loginInputContainer({
    required TextEditingController controller,
    required String labelText,
    required bool isPassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.tealAccent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none, 
        ),
      ),
    );
  }
}
