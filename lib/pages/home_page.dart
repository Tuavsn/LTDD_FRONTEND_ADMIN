import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    // Giả sử email được lưu trong secure storage cùng token
    final token = await StorageService.readToken();
    // Bạn có thể giải mã JWT để lấy email, hoặc gọi API getProfile
    // Ở đây đơn giản set email tùy ý
    setState(() {
      _email = 'manager@example.com'; // Thay bằng giá trị thực
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Xin chào,',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _email.isNotEmpty ? _email : 'Loading...',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                child: Text('Thông tin tài khoản'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}