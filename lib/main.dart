import 'package:chat_app/configs/routes/routes_manager.dart';
import 'package:chat_app/configs/routes/routes_name.dart';
import 'package:chat_app/feature/auth/view_model/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Chat App',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: RoutesName.login,
        onGenerateRoute: RoutesManager.generateRoute,
      ),
    );
  }
}
