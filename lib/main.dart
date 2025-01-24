import 'package:chat_app/feature/auth/view_model/login_view_model.dart';
import 'package:chat_app/configs/routes/routes_name.dart';
import 'package:chat_app/configs/routes/routes_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isLoggedIn = await LoginViewModel().isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ],
      child: MaterialApp(
        title: 'Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        initialRoute: isLoggedIn ? RoutesName.chat : RoutesName.login,
        onGenerateRoute: RoutesManager.generateRoute,
      ),
    );
  }
}
