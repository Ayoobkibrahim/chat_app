import 'package:chat_app/configs/routes/routes_name.dart';
import 'package:chat_app/feature/auth/view/screen/login_screen.dart';
import 'package:chat_app/feature/chat/view/screen/chat_screen.dart';
import 'package:flutter/material.dart';

class RoutesManager {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case RoutesName.chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
