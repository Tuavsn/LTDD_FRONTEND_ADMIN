import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class AuthService {
  static const _baseUrl = 'http://localhost:8082/api/v1/auth';

  // Gửi login, lưu token vào secure storage
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await StorageService.writeToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Thêm header Authorization nếu token tồn tại
  static Future<http.Response> getWithAuth(String path) async {
    final token = await StorageService.readToken();
    return http.get(
      Uri.parse('$_baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // Ví dụ POST có Auth
  static Future<http.Response> postWithAuth(String path, Map<String, dynamic> body) async {
    final token = await StorageService.readToken();
    return http.post(
      Uri.parse('$_baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  // Đăng xuất: xóa token
  static Future<void> logout() async {
    await StorageService.deleteToken();
  }
  
  // Kiểm tra xem người dùng đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    final token = await StorageService.readToken();
    return token != null && token.isNotEmpty;
  }
  
  // Kiểm tra token có hợp lệ không bằng cách gọi một API endpoint
  static Future<bool> validateToken() async {
    try {
      final response = await getWithAuth('validate-token');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}