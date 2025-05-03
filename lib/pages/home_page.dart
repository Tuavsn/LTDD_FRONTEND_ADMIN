import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _email = '';
  String _name = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load user info from secure storage or API
      final token = await StorageService.readToken();
      // In a real app, you would decode JWT or call a profile API
      
      // For demo purposes, we'll use placeholder data
      setState(() {
        _email = 'admin@example.com';
        _name = 'Admin User';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildWelcomeContent(),
    );
  }

  Widget _buildWelcomeContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.store,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            'Chào mừng, ${_name}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Quản lý cửa hàng của bạn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bảng điều khiển giúp bạn quản lý sản phẩm, danh mục, đơn hàng và các mã giảm giá một cách hiệu quả.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            icon: const Icon(Icons.dashboard),
            label: const Text('Truy cập bảng điều khiển'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}