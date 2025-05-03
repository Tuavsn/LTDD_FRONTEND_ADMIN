import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/forget_password_page.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:flutter_application_1/pages/regist_page.dart';
import 'package:flutter_application_1/pages/reset_password_page.dart';
import 'package:flutter_application_1/pages/verify_forgot_otp_page.dart';
import 'package:flutter_application_1/pages/verify_otp_page.dart';
import 'package:flutter_application_1/pages/dashboard_page.dart';
import 'package:flutter_application_1/pages/product_dashboard_page.dart';
import 'package:flutter_application_1/pages/category_dashboard_page.dart';
import 'package:flutter_application_1/pages/order_dashboard_page.dart';
import 'package:flutter_application_1/pages/discount_dashboard_page.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => SplashScreen(),
        '/login': (ctx) => LoginPage(),
        '/register': (_) => RegisterPage(),
        '/forgot-password': (_) => ForgotPasswordPage(),
        '/home': (_) => HomePage(),  // trang chính sau login
        '/dashboard': (_) => DashboardPage(),
        '/products': (_) => ProductsPage(),
        '/categories': (_) => CategoriesPage(),
        '/orders': (_) => OrdersPage(),
        '/discounts': (_) => DiscountsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verify-otp') {
          // Handle VerifyOtpPage with required arguments structure
          final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VerifyOtpPage(arguments: args),
          );
        } else if (settings.name == '/verify-forgot-otp') {
          // Convert string argument to map format for VerifyForgotOtpPage
          final String email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => VerifyForgotOtpPage(email: email),
          );
        } else if (settings.name == '/reset-password') {
          // Handle ResetPasswordPage
          final String email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordPage(email: email),
          );
        }
        // Return null to allow the routes above to handle other routes
        return null;
      },
    );
  }
}