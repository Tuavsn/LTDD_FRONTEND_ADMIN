import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _errorMessage = '';

  bool _validateData() {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (_emailController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _fullnameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin';
      });
      return false;
    }

    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = 'Email không hợp lệ';
      });
      return false;
    }

    if (!phoneRegex.hasMatch(_phoneController.text)) {
      setState(() {
        _errorMessage = 'Số điện thoại không hợp lệ';
      });
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu nhập lại không khớp';
      });
      return false;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      return false;
    }

    setState(() {
      _errorMessage = '';
    });
    return true;
  }

  Future<void> _handleRegister() async {
    if (!_validateData()) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://yourserver.com/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'phone': _phoneController.text,
          'fullname': _fullnameController.text,
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Chuyển đến màn hình nhập OTP
        Navigator.pushNamed(
          context, 
          '/confirm-otp',
          arguments: {
            'email': _emailController.text,
            'nextPathname': '/login'
          }
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Đăng ký thất bại'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi kết nối'))
      );
    }
  }

  void _handleLoginClick() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login-background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    // Email Input
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                    ),
                    
                    // Phone Input
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    
                    // Fullname Input
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _fullnameController,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Password Input
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                      ),
                    ),
                    
                    // Confirm Password Input
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    
                    SizedBox(height: 10),
                    
                    // Register Button
                    ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    
                    SizedBox(height: 10),
                    
                    // Back to Login Button
                    TextButton(
                      onPressed: _handleLoginClick,
                      child: Text(
                        'Quay lại đăng nhập',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _fullnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}