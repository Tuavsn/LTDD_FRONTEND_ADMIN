import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/forget_password_page.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:flutter_application_1/pages/regist_page.dart';
import 'package:flutter_application_1/pages/reset_password_page.dart';
import 'package:flutter_application_1/pages/verify_forgot_otp_page.dart';
import 'package:flutter_application_1/pages/verify_otp_page.dart';
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
        '/register': (_) => RegisterPage(),
        '/verify-otp': (ctx) => VerifyOtpPage(email: ModalRoute.of(ctx)!.settings.arguments as String),
        '/forgot-password': (_) => ForgotPasswordPage(),
        '/verify-forgot-otp': (ctx) => VerifyForgotOtpPage(email: ModalRoute.of(ctx)!.settings.arguments as String),
        '/reset-password': (ctx) => ResetPasswordPage(email: ModalRoute.of(ctx)!.settings.arguments as String),
        '/home': (_) => HomePage(),  // trang chính sau login
      },
    );
  }
}
