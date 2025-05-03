import 'package:flutter/material.dart';
import './dashboard_service.dart';
import './storage_service.dart';
import './sidebar_menu.dart';
import 'package:intl/intl.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _isLoading = true;
  String _currentUsername = 'Admin';
  List<dynamic> _products = [];
  List<dynamic> _categories = [];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  String? _selectedCategoryId;

  // Editing state
  bool _isEditing = false;
  String? _editingProductId;

  // Search functionality
  final _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  // Image preview state
  bool _isValidImageUrl = false;
  List<Map<String, dynamic>> _productImages = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadProducts();
    _loadCategories();

    // Add listener to validate image URL
    _imageUrlController.addListener(_validateImageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _ratingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Method to validate image URL
  void _validateImageUrl() {
    final imageUrl = _imageUrlController.text;
    if (imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      setState(() {
        _isValidImageUrl = true;
      });
    } else {
      setState(() {
        _isValidImageUrl = false;
      });
    }
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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await DashboardService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DashboardService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _handleLogout() async {
    await StorageService.deleteToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear();
    _imageUrlController.clear();
    _ratingController.clear();
    _selectedCategoryId = null;
    _isEditing = false;
    _editingProductId = null;
    setState(() {
      _isValidImageUrl = false;
      _productImages = [];
    });
  }

  void _editProduct(dynamic product) {
    setState(() {
      _isEditing = true;
      _editingProductId = product['_id'];
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = (product['price'] ?? 0).toString();
      _stockController.text = (product['soldCount'] ?? 0).toString();
      _ratingController.text = (product['rating'] ?? 0).toString();
      _selectedCategoryId = product['category']?['_id'];

      // Handle images
      _productImages = [];
      if (product['image'] != null && product['image'] is List) {
        for (var img in product['image']) {
          _productImages.add({
            'url': img['url'] ?? '',
            'isPrimary': img['isPrimary'] ?? false,
          });
        }
      }

      // Set the first image URL to the controller
      if (_productImages.isNotEmpty) {
        // Find primary image if exists
        final primaryImage = _productImages.firstWhere(
          (img) => img['isPrimary'] == true,
          orElse: () => _productImages.first,
        );
        _imageUrlController.text = primaryImage['url'];
      } else {
        _imageUrlController.text = '';
      }

      // Validate the image URL
      _validateImageUrl();
    });
  }

  void _addImage() {
    if (_imageUrlController.text.isNotEmpty && _isValidImageUrl) {
      setState(() {
        final isPrimary = _productImages.isEmpty;
        _productImages.add({
          'url': _imageUrlController.text,
          'isPrimary': isPrimary,
        });
        _imageUrlController.clear();
        _isValidImageUrl = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removedImage = _productImages.removeAt(index);

      // If we removed the primary image, set the first remaining image as primary
      if (removedImage['isPrimary'] && _productImages.isNotEmpty) {
        _productImages[0]['isPrimary'] = true;
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() {
      for (int i = 0; i < _productImages.length; i++) {
        _productImages[i]['isPrimary'] = (i == index);
      }
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_productImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng thêm ít nhất một hình ảnh')),
        );
        return;
      }

      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'soldCount': int.parse(_stockController.text),
        'rating': double.parse(_ratingController.text),
        'image': _productImages,
        'category': {'_id': _selectedCategoryId},
      };

      try {
        bool success;
        if (_isEditing && _editingProductId != null) {
          // Update existing product
          success = await DashboardService.updateProduct(
            _editingProductId!,
            productData,
          );
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật sản phẩm thành công')),
            );
          }
        } else {
          // Create new product
          success = await DashboardService.createProduct(productData);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thêm sản phẩm thành công')),
            );
          }
        }

        if (success) {
          _resetForm();
          _loadProducts();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      final success = await DashboardService.deleteProduct(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa sản phẩm thành công')),
        );
        _loadProducts();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể xóa sản phẩm')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts =
            _products.where((product) {
              final name = product['name']?.toString().toLowerCase() ?? '';
              final description =
                  product['description']?.toString().toLowerCase() ?? '';
              return name.contains(query.toLowerCase()) ||
                  description.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  // Method to view full image in a dialog
  void _viewFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Xem hình ảnh'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Không thể tải hình ảnh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryName(dynamic category) {
    if (category == null) return 'Không có';

    if (category is Map) {
      return category['name'] ?? 'Không xác định';
    }

    final categoryObj = _categories.firstWhere(
      (cat) => cat['_id'] == category,
      orElse: () => {'name': 'Không xác định'},
    );

    return categoryObj['name'] ?? 'Không xác định';
  }

  String _getPrimaryImageUrl(dynamic product) {
    if (product['image'] != null &&
        product['image'] is List &&
        product['image'].isNotEmpty) {
      // Try to find primary image
      final primaryImage = product['image'].firstWhere(
        (img) => img['isPrimary'] == true,
        orElse: () => product['image'][0],
      );

      return primaryImage['url'] ?? '';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar menu
          SidebarMenu(
            currentUsername: _currentUsername,
            selectedIndex: 1, // Products tab
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  // Stay on Products
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/categories');
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
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildProductsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quản lý sản phẩm',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: Icon(_isEditing ? Icons.close : Icons.add),
                label: Text(_isEditing ? 'Hủy' : 'Thêm sản phẩm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.grey : Colors.blue,
                ),
                onPressed: () {
                  if (_isEditing) {
                    // Cancel editing
                    setState(() {
                      _resetForm();
                    });
                  } else {
                    // Show add product form
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Product form (visible when editing or adding)
          if (_isEditing) _buildProductForm(),

          const SizedBox(height: 20),

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
            onChanged: _searchProducts,
          ),

          const SizedBox(height: 20),

          // Products table
          Expanded(child: _buildProductsTable()),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing && _editingProductId != null
                    ? 'Chỉnh sửa sản phẩm'
                    : 'Thêm sản phẩm mới',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Form fields
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tên sản phẩm',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.shopping_bag),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập tên sản phẩm';
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
                                      alignLabelWithHint: true,
                                      prefixIcon: Icon(Icons.description),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _imageUrlController,
                                    decoration: InputDecoration(
                                      labelText: 'Đường dẫn hình ảnh',
                                      border: const OutlineInputBorder(),
                                      hintText: 'https://example.com/image.jpg',
                                      prefixIcon: const Icon(Icons.image),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.add_photo_alternate,
                                        ),
                                        onPressed:
                                            _isValidImageUrl ? _addImage : null,
                                        tooltip: 'Thêm vào danh sách',
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return null; // Optional
                                      }
                                      if (!value.startsWith('http://') &&
                                          !value.startsWith('https://')) {
                                        return 'Vui lòng nhập đường dẫn hợp lệ (http:// hoặc https://)';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right column
                            Expanded(
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    decoration: const InputDecoration(
                                      labelText: 'Danh mục',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.category),
                                    ),
                                    hint: const Text('Chọn danh mục'),
                                    items:
                                        _categories.map((category) {
                                          return DropdownMenuItem<String>(
                                            value: category['_id'] as String,
                                            child: Text(
                                              category['name'] as String,
                                            ),
                                          );
                                        }).toList(),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Vui lòng chọn danh mục';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategoryId = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _priceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Giá',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.monetization_on),
                                      suffixText: 'VNĐ',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập giá';
                                      }
                                      try {
                                        double.parse(value);
                                      } catch (e) {
                                        return 'Giá không hợp lệ';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _stockController,
                                          decoration: const InputDecoration(
                                            labelText: 'Đã bán',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.sell),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Vui lòng nhập số lượng';
                                            }
                                            try {
                                              int.parse(value);
                                            } catch (e) {
                                              return 'Số lượng không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ratingController,
                                          decoration: const InputDecoration(
                                            labelText: 'Đánh giá',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.star),
                                            hintText: '0-5',
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Vui lòng nhập đánh giá';
                                            }
                                            try {
                                              final rating = double.parse(
                                                value,
                                              );
                                              if (rating < 0 || rating > 5) {
                                                return 'Đánh giá phải từ 0-5';
                                              }
                                            } catch (e) {
                                              return 'Đánh giá không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_productImages.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Danh sách hình ảnh:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _productImages.length,
                                  itemBuilder: (context, index) {
                                    final image = _productImages[index];
                                    final isPrimary =
                                        image['isPrimary'] == true;

                                    return Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              isPrimary
                                                  ? Colors.blue
                                                  : Colors.grey,
                                          width: isPrimary ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Image
                                          InkWell(
                                            onTap:
                                                () => _viewFullImage(
                                                  image['url'],
                                                ),
                                            child: Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              padding: const EdgeInsets.all(4),
                                              child: Image.network(
                                                image['url'],
                                                fit: BoxFit.contain,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.red,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          // Primary badge
                                          if (isPrimary)
                                            Positioned(
                                              top: 4,
                                              left: 4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'Chính',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Actions
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  if (!isPrimary)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed:
                                                          () =>
                                                              _setPrimaryImage(
                                                                index,
                                                              ),
                                                      tooltip:
                                                          'Đặt làm ảnh chính',
                                                    )
                                                  else
                                                    const SizedBox(width: 16),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed:
                                                        () =>
                                                            _removeImage(index),
                                                    tooltip: 'Xóa ảnh',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Right column - Image preview
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xem trước hình ảnh:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _imageUrlController.text.isNotEmpty &&
                                        _isValidImageUrl
                                    ? InkWell(
                                      onTap:
                                          () => _viewFullImage(
                                            _imageUrlController.text,
                                          ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.network(
                                            _imageUrlController.text,
                                            fit: BoxFit.contain,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Center(
                                                child: Text(
                                                  'Không thể tải hình ảnh',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Positioned.fill(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap:
                                                    () => _viewFullImage(
                                                      _imageUrlController.text,
                                                    ),
                                                splashColor: Colors.black26,
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.zoom_in,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 16),
                          if (_imageUrlController.text.isNotEmpty &&
                              _isValidImageUrl)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm vào danh sách'),
                                  onPressed: _addImage,
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Lưu ý:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Mỗi sản phẩm cần ít nhất một hình ảnh',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Hình ảnh đầu tiên sẽ là hình ảnh chính',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Hình ảnh chính sẽ hiển thị đầu tiên',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Chấp nhận định dạng JPG, PNG, WEBP',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Kích thước tối đa: 5MB mỗi hình',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Hủy'),
                    onPressed: () {
                      setState(() {
                        _resetForm();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(
                      _isEditing && _editingProductId != null
                          ? Icons.save
                          : Icons.add,
                    ),
                    label: Text(
                      _isEditing && _editingProductId != null
                          ? 'Cập nhật'
                          : 'Thêm sản phẩm',
                    ),
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isEditing && _editingProductId != null
                              ? Colors.green
                              : Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTable() {
    return Card(
      elevation: 2,
      child:
          _filteredProducts.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Không có sản phẩm nào',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
              : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 15.0,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text('Hình ảnh')),
                      DataColumn(label: Text('Tên sản phẩm')),
                      DataColumn(label: Text('Danh mục')),
                      DataColumn(label: Text('Giá')),
                      DataColumn(label: Text('Đã bán')),
                      DataColumn(label: Text('Đánh giá')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows:
                        _filteredProducts.map<DataRow>((product) {
                          // Get primary image URL
                          final imageUrl = _getPrimaryImageUrl(product);
                          // Format price with thousand separator
                          final price = NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                            decimalDigits: 0,
                          ).format(product['price'] ?? 0);

                          return DataRow(
                            cells: [
                              // Image cell
                              DataCell(
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child:
                                      imageUrl.isNotEmpty
                                          ? InkWell(
                                            onTap:
                                                () => _viewFullImage(imageUrl),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.red,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          : const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          ),
                                ),
                              ),
                              // Name cell - limit to two lines
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Tooltip(
                                    message: product['name'] ?? '',
                                    child: Text(
                                      product['name'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Category cell
                              DataCell(
                                Text(_getCategoryName(product['category'])),
                              ),
                              // Price cell
                              DataCell(Text(price)),
                              // Sold count cell
                              DataCell(Text('${product['soldCount'] ?? 0}')),
                              // Rating cell
                              DataCell(
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${product['rating'] ?? 0.0}'),
                                  ],
                                ),
                              ),
                              // Actions cell
                              DataCell(
                                Row(
                                  children: [
                                    // View button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Xem chi tiết',
                                      onPressed: () {
                                        // Navigate to product detail page
                                        // Or show a detailed dialog
                                        _showProductDetailDialog(product);
                                      },
                                    ),
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'Chỉnh sửa',
                                      onPressed: () {
                                        _editProduct(product);
                                      },
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Xóa',
                                      onPressed: () {
                                        // Show confirmation dialog
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Xác nhận xóa'),
                                              content: Text(
                                                'Bạn có chắc muốn xóa sản phẩm "${product['name']}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _deleteProduct(
                                                      product['_id'],
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Xóa',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
    );
  }

  // Method to show product detail dialog
  void _showProductDetailDialog(dynamic product) {
    final imageUrl = _getPrimaryImageUrl(product);
    final price = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(product['price'] ?? 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Chi tiết sản phẩm'),
                  centerTitle: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image gallery
                        if (product['image'] != null &&
                            product['image'] is List &&
                            product['image'].isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: product['image'].length,
                              itemBuilder: (context, index) {
                                final image = product['image'][index];
                                final isPrimary = image['isPrimary'] == true;
                                return Container(
                                  width: 180,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isPrimary
                                              ? Colors.blue
                                              : Colors.grey.shade300,
                                      width: isPrimary ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () => _viewFullImage(image['url']),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.network(
                                          image['url'],
                                          fit: BoxFit.contain,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.red,
                                              ),
                                            );
                                          },
                                        ),
                                        if (isPrimary)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Ảnh chính',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Center(
                            child: Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Product info
                        Text(
                          product['name'] ?? 'Không có tên',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getCategoryName(product['category']),
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product['rating'] ?? 0.0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Đã bán: ${product['soldCount'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        const Text(
                          'Mô tả sản phẩm:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['description'] ?? 'Không có mô tả',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Chỉnh sửa'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _editProduct(product);
                              },
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Đóng'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
