// reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  ResetPasswordPage({required this.email});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  Future<void> resetPassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mật khẩu không khớp')));
      return;
    }
    final res = await http.post(
      Uri.parse('http://yourserver.com/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': widget.email,
        'newPassword': _newPassCtrl.text,
      }),
    );

    final data = json.decode(res.body);
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đặt lại mật khẩu thành công')));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đặt lại mật khẩu')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Xác nhận mật khẩu'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: resetPassword, child: Text('Đặt lại mật khẩu')),
          ],
        ),
      ),
    );
  }
}
