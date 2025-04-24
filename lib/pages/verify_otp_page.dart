// verify_otp_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerifyOtpPage extends StatefulWidget {
  final String email;
  VerifyOtpPage({required this.email});

  @override
  _VerifyOtpPageState createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _otpController = TextEditingController();

  Future<void> verifyOtp() async {
    final response = await http.post(
      Uri.parse('http://yourserver.com/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': widget.email,
        'otp': _otpController.text,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      // Chuyển đến màn hình đăng nhập
      Navigator.pushNamed(context, '/login');
    } else {
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Xác minh OTP')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Nhập mã OTP đã gửi đến email: ${widget.email}'),
            TextField(controller: _otpController, decoration: InputDecoration(labelText: 'OTP')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: verifyOtp, child: Text('Xác minh')),
          ],
        ),
      ),
    );
  }
}
