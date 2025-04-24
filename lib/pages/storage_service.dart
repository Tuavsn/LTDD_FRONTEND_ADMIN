// storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';

  static Future<void> writeToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  static Future<String?> readToken() =>
      _storage.read(key: _keyToken);

  static Future<void> deleteToken() =>
      _storage.delete(key: _keyToken);
}
