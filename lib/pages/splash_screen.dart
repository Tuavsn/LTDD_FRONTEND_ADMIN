import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Thời gian hiển thị 10 giây rồi chuyển sang Login
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 10), () {
      Navigator.pushReplacementNamed(context, '/login');
    }); // Timer from dart:async :contentReference[oaicite:16]{index=16}
  }

  @override
  Widget build(BuildContext context) {
    final members = [
      'Trình Học Tuấn - 21110340',
      'Vũ Khánh Quốc - 21110848',
      // thêm tên thành viên …
    ];
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: members
              .map((name) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(name,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
