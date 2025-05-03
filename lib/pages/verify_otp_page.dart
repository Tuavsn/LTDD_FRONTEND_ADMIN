import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class VerifyOtpPage extends StatefulWidget {
  final Map<String, dynamic> arguments;
  
  const VerifyOtpPage({Key? key, required this.arguments}) : super(key: key);

  @override
  _VerifyOtpPageState createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  int _timer = 0;
  Timer? _countdownTimer;
  late String _email;
  late String _nextPathname;

  @override
  void initState() {
    super.initState();
    _email = widget.arguments['email'] as String;
    _nextPathname = widget.arguments['nextPathname'] as String? ?? '/login';
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSubmitOTP() async {
    try {
      final response = await http.post(
        Uri.parse('http://yourserver.com/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'otp': _otpController.text,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xác thực OTP thành công'))
        );
        
        // Chuyển đến màn hình tiếp theo dựa vào nextPathname
        Navigator.pushReplacementNamed(
          context, 
          _nextPathname,
          arguments: {'email': _email}
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Xác thực OTP thất bại'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi kết nối'))
      );
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() {
      _timer = 60;
    });
    
    try {
      final response = await http.post(
        Uri.parse('http://yourserver.com/api/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
        }),
      );

      final data = json.decode(response.body);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Đã gửi lại OTP'))
      );
      
      _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_timer > 0) {
            _timer--;
          } else {
            timer.cancel();
          }
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi kết nối'))
      );
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  Widget _buildOTPResendButton() {
    if (_timer == 0) {
      return TextButton(
        onPressed: _handleResendOTP,
        child: Text('Gửi lại OTP'),
      );
    } else {
      return TextButton(
        onPressed: null,
        child: Text('Gửi lại OTP trong $_timer giây'),
      );
    }
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: Text(
                        'Xác thực OTP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // OTP Input
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Mã OTP',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    
                    // Resend OTP Button
                    _buildOTPResendButton(),
                    
                    SizedBox(height: 8),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _handleSubmitOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Cancel Button
                    TextButton(
                      onPressed: _handleCancel,
                      child: Text(
                        'Hủy',
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
}