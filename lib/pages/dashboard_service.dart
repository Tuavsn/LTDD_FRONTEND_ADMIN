import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class DashboardService {
  static const _baseUrl = 'http://localhost:8082/api/v1';

  // Các phương thức chung cho tất cả các API
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

  static Future<http.Response> postWithAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
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

  static Future<http.Response> putWithAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await StorageService.readToken();
    return http.put(
      Uri.parse('$_baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  static Future<http.Response> deleteWithAuth(String path) async {
    final token = await StorageService.readToken();
    return http.delete(
      Uri.parse('$_baseUrl/$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // API cho Category
  static Future<List<dynamic>> getAllCategories() async {
    try {
      final response = await getWithAuth('category');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getCategoryById(String id) async {
    try {
      final response = await getWithAuth('category/$id');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  static Future<bool> createCategory(Map<String, dynamic> category) async {
    try {
      final response = await postWithAuth('category', category);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }

  static Future<bool> updateCategory(
    String id,
    Map<String, dynamic> category,
  ) async {
    try {
      final response = await putWithAuth('category/$id', category);
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      final response = await deleteWithAuth('category/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // API cho Product
  static Future<List<dynamic>> getAllProducts() async {
    try {
      final response = await getWithAuth('product');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final response = await getWithAuth('product/$id');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  static Future<bool> createProduct(Map<String, dynamic> product) async {
    try {
      final response = await postWithAuth('product', product);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error creating product: $e');
      return false;
    }
  }

  static Future<bool> updateProduct(
    String id,
    Map<String, dynamic> product,
  ) async {
    try {
      final response = await putWithAuth('product/$id', product);
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await deleteWithAuth('product/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // API cho User
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await getWithAuth('user/me');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<bool> updateUserProfile(Map<String, dynamic> profile) async {
    try {
      final response = await putWithAuth('user/profile', profile);
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // API cho Order
  static Future<List<dynamic>> getAllOrders() async {
    try {
      final response = await getWithAuth('order/all');
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        // Check if response is a map with an "orders" field (as shown in the actual API response)
        if (decodedBody is Map && decodedBody.containsKey('orders')) {
          return decodedBody['orders'];
        }
        // Check if response is a map with a data field that contains the list
        if (decodedBody is Map && decodedBody.containsKey('data')) {
          return decodedBody['data'];
        }
        // If response is already a list
        if (decodedBody is List) {
          return decodedBody;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOrderById(String id) async {
    try {
      final response = await getWithAuth('order/$id');
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        return decodedBody['order'];
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  static Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final response = await putWithAuth('order/$id', {'status': status});
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // API cho Discount
  static Future<List<dynamic>> getAllDiscounts() async {
    try {
      final response = await getWithAuth('discount');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting discounts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDiscountById(String id) async {
    try {
      final response = await getWithAuth('discount/$id');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting discount: $e');
      return null;
    }
  }

  static Future<bool> createDiscount(Map<String, dynamic> discount) async {
    try {
      final response = await postWithAuth('discount', discount);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error creating discount: $e');
      return false;
    }
  }

  static Future<bool> updateDiscount(
    String id,
    Map<String, dynamic> discount,
  ) async {
    try {
      final response = await putWithAuth('discount/$id', discount);
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating discount: $e');
      return false;
    }
  }

  static Future<bool> deleteDiscount(String id) async {
    try {
      final response = await deleteWithAuth('discount/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting discount: $e');
      return false;
    }
  }

  // API cho Dashboard Stats (thống kê)
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Giả sử bạn có API endpoint cho thống kê dashboard
      final response = await getWithAuth('stats/dashboard');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {};
    }
  }
}
