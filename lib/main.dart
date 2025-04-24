import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manager App',
      initialRoute: '/',
      routes: {
        '/': (ctx) => SplashScreen (),
        '/login': (ctx) => LoginPage(),
      },
    );
  }
}
