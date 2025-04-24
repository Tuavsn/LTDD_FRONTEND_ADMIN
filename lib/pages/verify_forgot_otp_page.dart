// verify_forgot_otp_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerifyForgotOtpPage extends StatefulWidget {
  final String email;
  VerifyForgotOtpPage({required this.email});

  @override
  _VerifyForgotOtpPageState createState() => _VerifyForgotOtpPageState();
}

class _VerifyForgotOtpPageState extends State<VerifyForgotOtpPage> {
  final _otpController = TextEditingController();

  Future<void> verifyForgotOtp() async {
    final res = await http.post(
      Uri.parse('http://yourserver.com/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': widget.email, 'otp': _otpController.text}),
    );

    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      // Nếu OTP hợp lệ cho reset, chuyển đến màn hình đặt lại mật khẩu
      Navigator.pushNamed(context, '/reset-password', arguments: widget.email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Xác minh OTP (Quên mật khẩu)')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Nhập mã OTP đã gửi tới email ${widget.email}'),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'OTP'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: verifyForgotOtp, child: Text('Xác minh OTP')),
          ],
        ),
      ),
    );
  }
}
