import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/auth_service.dart';
import './dashboard_service.dart';
import './sidebar_menu.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _isLoading = true;
  List<dynamic> _categories = [];
  String _currentUsername = 'Admin';
  String? _selectedCategoryId;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await DashboardService.getUserProfile();
      if (profile != null) {
        setState(() {
          _currentUsername = profile['name'] ?? 'Admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await DashboardService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _clearForm() {
    setState(() {
      _selectedCategoryId = null;
      _nameController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _deleteCategory(String id) async {
    try {
      final success = await DashboardService.deleteCategory(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa danh mục thành công')),
        );
        _loadCategories();
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa danh mục')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final category = {
      'name': _nameController.text,
      'description': _descriptionController.text,
    };

    try {
      bool success;
      
      if (_selectedCategoryId != null) {
        // Update existing category
        success = await DashboardService.updateCategory(_selectedCategoryId!, category);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật danh mục thành công')),
          );
        }
      } else {
        // Create new category
        success = await DashboardService.createCategory(category);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm danh mục thành công')),
          );
        }
      }

      if (success) {
        _loadCategories();
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu danh mục')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _editCategory(String id) async {
    try {
      final category = await DashboardService.getCategoryById(id);
      
      if (category != null) {
        setState(() {
          _selectedCategoryId = id;
          _nameController.text = category['name'] ?? '';
          _descriptionController.text = category['description'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin danh mục')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa danh mục này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCategory(id);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar menu
          SidebarMenu(
            currentUsername: _currentUsername,
            selectedIndex: 2,  // Categories is at index 2
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/products');
                  break;
                case 2:
                  // Stay on Categories
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/orders');
                  break;
                case 4:
                  Navigator.pushReplacementNamed(context, '/discounts');
                  break;
                case 5:
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
              }
            },
            onLogout: _handleLogout,
          ),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCategoriesContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quản lý danh mục',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _clearForm,
                icon: const Icon(Icons.add),
                label: const Text('Thêm danh mục mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category list
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danh sách danh mục',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildCategoriesList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Category form
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategoryId != null ? 'Sửa danh mục' : 'Thêm danh mục mới',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text('Không có danh mục nào'),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final id = category['_id'] ?? '';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(
              category['name'] ?? 'Không có tên',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              category['description'] ?? 'Không có mô tả',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editCategory(id),
                  tooltip: 'Sửa',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(id),
                  tooltip: 'Xóa',
                ),
              ],
            ),
            onTap: () => _editCategory(id),
          ),
        );
      },
    );
  }

  Widget _buildCategoryForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên danh mục',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tên danh mục';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_selectedCategoryId != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
              if (_selectedCategoryId != null)
                const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_selectedCategoryId != null ? 'Cập nhật' : 'Thêm mới'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}