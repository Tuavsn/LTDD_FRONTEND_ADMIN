// register_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> register() async {
    final response = await http.post(
      Uri.parse('http://yourserver.com/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fullname': _fullnameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      // Chuyển đến màn hình nhập OTP
      Navigator.pushNamed(context, '/verify-otp', arguments: _emailController.text);
    } else {
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _fullnameController, decoration: InputDecoration(labelText: 'Họ tên')),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'Số điện thoại')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text('Đăng ký')),
          ],
        ),
      ),
    );
  }
}
