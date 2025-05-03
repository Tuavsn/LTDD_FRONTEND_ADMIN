import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text: 'vkq265@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'qwerty');
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await StorageService.readToken();
    if (token != null && token.isNotEmpty) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final success = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success) {
        // Lấy thông tin người dùng nếu cần
        final userInfoResponse = await AuthService.getWithAuth('user');
        if (userInfoResponse.statusCode == 200) {
          final userInfo = json.decode(userInfoResponse.body);
          // Có thể lưu thông tin người dùng vào nơi khác nếu cần
        }
        
        _navigateToHome();
      } else {
        // Kiểm tra nếu API trả về json có suggestEnterOtp
        try {
          // Thực hiện một POST riêng để kiểm tra trạng thái tài khoản
          final checkAccountResponse = await AuthService.postWithAuth(
            'check-account', 
            {'email': _emailController.text}
          );
          
          final checkData = json.decode(checkAccountResponse.body);
          
          if (checkData['suggestEnterOtp'] == true) {
            Navigator.pushNamed(
              context, 
              '/confirm-otp',
              arguments: {'email': _emailController.text}
            );
          } else {
            setState(() {
              _errorMessage = 'Thông tin đăng nhập không chính xác';
            });
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Thông tin đăng nhập không chính xác';
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi login: $e');
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi kết nối';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRegisterClick() {
    Navigator.pushNamed(context, '/register');
  }

  void _handleForgotPasswordClick() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('../../assets/images/login-background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
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
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
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
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: _isLoading 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 16),
                          ),
                    ),
                    SizedBox(height: 14),
                    TextButton(
                      onPressed: _handleRegisterClick,
                      child: Text(
                        'Đăng ký tài khoản',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 6),
                    TextButton(
                      onPressed: _handleForgotPasswordClick,
                      child: Text(
                        'Quên mật khẩu?',
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
    _passwordController.dispose();
    super.dispose();
  }
}