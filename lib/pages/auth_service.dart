// auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class AuthService {
  static const _baseUrl = 'http://yourserver.com/api/auth';

  // Gửi login, lưu token vào secure storage
  static Future<bool> login(String email, String pass) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': pass}),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      await StorageService.writeToken(data['token']);
      return true;
    }
    return false;
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
  static Future<http.Response> postWithAuth(String path, Map body) async {
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
}
