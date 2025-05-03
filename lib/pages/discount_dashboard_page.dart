import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './dashboard_service.dart';
import './storage_service.dart';
import './sidebar_menu.dart';

class DiscountsPage extends StatefulWidget {
  const DiscountsPage({Key? key}) : super(key: key);

  @override
  _DiscountsPageState createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  bool _isLoading = true;
  String _currentUsername = 'Admin';
  List<dynamic> _discounts = [];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _discountType = 'percentage'; // percentage or FIXED
  bool _isActive = true;
  int _usageLimit = 100;

  // Editing state
  bool _isEditing = false;
  String? _editingDiscountId;

  // Search functionality
  final _searchController = TextEditingController();
  List<dynamic> _filteredDiscounts = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDiscounts();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _minimumOrderController.dispose();
    _searchController.dispose();
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

  Future<void> _loadDiscounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final discounts = await DashboardService.getAllDiscounts();
      setState(() {
        _discounts = discounts;
        _filteredDiscounts = discounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading discounts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await StorageService.deleteToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _codeController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _minimumOrderController.clear();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));
    _discountType = 'percentage';
    _isActive = true;
    _usageLimit = 100;
    _isEditing = false;
    _editingDiscountId = null;
  }

  void _editDiscount(dynamic discount) {
    setState(() {
      _isEditing = true;
      _editingDiscountId = discount['id'];
      _codeController.text = discount['code'] ?? '';
      _descriptionController.text = discount['description'] ?? '';
      _amountController.text = (discount['amount'] ?? 0).toString();
      _minimumOrderController.text = (discount['minimumOrder'] ?? 0).toString();
      _discountType = discount['type'] ?? 'percentage';
      _isActive = discount['isActive'] ?? true;
      _usageLimit = discount['usageLimit'] ?? 100;
      
      // Parse dates if available
      if (discount['startDate'] != null) {
        _startDate = DateTime.parse(discount['startDate']);
      }
      if (discount['endDate'] != null) {
        _endDate = DateTime.parse(discount['endDate']);
      }
    });
  }

  Future<void> _saveDiscount() async {
    if (_formKey.currentState!.validate()) {
      final discountData = {
        'code': _codeController.text,
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'minimumOrder': double.parse(_minimumOrderController.text),
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'type': _discountType,
        'isActive': _isActive,
        'usageLimit': _usageLimit,
      };

      try {
        bool success;
        if (_isEditing && _editingDiscountId != null) {
          // Update existing discount
          success = await DashboardService.updateDiscount(_editingDiscountId!, discountData);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật mã giảm giá thành công')),
            );
          }
        } else {
          // Create new discount
          success = await DashboardService.createDiscount(discountData);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thêm mã giảm giá thành công')),
            );
          }
        }

        if (success) {
          _resetForm();
          _loadDiscounts();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _deleteDiscount(String id) async {
    try {
      final success = await DashboardService.deleteDiscount(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa mã giảm giá thành công')),
        );
        _loadDiscounts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa mã giảm giá')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _searchDiscounts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDiscounts = _discounts;
      } else {
        _filteredDiscounts = _discounts.where((discount) {
          final code = discount['code']?.toString().toLowerCase() ?? '';
          final description = discount['description']?.toString().toLowerCase() ?? '';
          return code.contains(query.toLowerCase()) || 
                 description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDiscountValue(dynamic discount) {
    final amount = discount['percentage'] ?? 0;
    final type = discount['type'] ?? 'percentage';
    
    if (type == 'percentage') {
      return '$amount%';
    } else {
      return '$amount VNĐ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar menu
          SidebarMenu(
            currentUsername: _currentUsername,
            selectedIndex: 4, // Discounts tab
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/products');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/categories');
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/orders');
                  break;
                case 4:
                  // Stay on Discounts
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
                : _buildDiscountsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quản lý mã giảm giá',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(_isEditing ? Icons.close : Icons.add),
                label: Text(_isEditing ? 'Hủy' : 'Thêm mã giảm giá'),
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
                    // Show add discount form
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Discount form (visible when editing or adding)
          if (_isEditing) _buildDiscountForm(),
          
          const SizedBox(height: 20),
          
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm mã giảm giá...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: _searchDiscounts,
          ),
          
          const SizedBox(height: 20),
          
          // Discounts table
          Expanded(
            child: _buildDiscountsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountForm() {
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
                _isEditing && _editingDiscountId != null ? 'Chỉnh sửa mã giảm giá' : 'Thêm mã giảm giá mới',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Mã giảm giá',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mã giảm giá';
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
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        // Date range
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Ngày bắt đầu',
                                selectedDate: _startDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Ngày kết thúc',
                                selectedDate: _endDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right column
                  Expanded(
                    child: Column(
                      children: [
                        // Discount type
                        DropdownButtonFormField<String>(
                          value: _discountType,
                          decoration: const InputDecoration(
                            labelText: 'Loại giảm giá',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'percentage',
                              child: Text('Phần trăm (%)'),
                            ),
                            DropdownMenuItem(
                              value: 'FIXED',
                              child: Text('Số tiền cố định (VNĐ)'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _discountType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Giá trị giảm giá',
                            border: const OutlineInputBorder(),
                            suffixText: _discountType == 'percentage' ? '%' : 'VNĐ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập giá trị giảm giá';
                            }
                            try {
                              final amount = double.parse(value);
                              if (_discountType == 'percentage' && (amount < 0 || amount > 100)) {
                                return 'Giá trị phần trăm phải từ 0-100%';
                              }
                            } catch (e) {
                              return 'Giá trị không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _minimumOrderController,
                          decoration: const InputDecoration(
                            labelText: 'Giá trị đơn hàng tối thiểu',
                            border: OutlineInputBorder(),
                            suffixText: 'VNĐ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập giá trị đơn hàng tối thiểu';
                            }
                            try {
                              double.parse(value);
                            } catch (e) {
                              return 'Giá trị không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _usageLimit.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Giới hạn sử dụng',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập giới hạn sử dụng';
                                  }
                                  try {
                                    int.parse(value);
                                  } catch (e) {
                                    return 'Giá trị không hợp lệ';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _usageLimit = int.tryParse(value) ?? 100;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SwitchListTile(
                                title: const Text('Kích hoạt'),
                                value: _isActive,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _resetForm();
                      });
                    },
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveDiscount,
                    child: Text(_isEditing && _editingDiscountId != null ? 'Cập nhật' : 'Thêm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountsTable() {
    if (_filteredDiscounts.isEmpty) {
      return const Center(
        child: Text(
          'Không có mã giảm giá nào',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Mã giảm giá')),
            DataColumn(label: Text('Giá trị')),
            DataColumn(label: Text('Thời gian')),
            DataColumn(label: Text('Trạng thái')),
            DataColumn(label: Text('Thao tác')),
          ],
          rows: _filteredDiscounts.map((discount) {
            final isActive = discount['active'] ?? false;
            final now = DateTime.now();
            bool isExpired = false;
            
            if (discount['expiration_date'] != null) {
              final endDate = DateTime.parse(discount['expiration_date']);
              isExpired = now.isAfter(endDate);
            }
            
            final status = isExpired 
                ? 'Hết hạn' 
                : (isActive ? 'Đang hoạt động' : 'Không hoạt động');
            
            final statusColor = isExpired 
                ? Colors.red 
                : (isActive ? Colors.green : Colors.orange);
            
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        discount['code'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        discount['description'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                DataCell(Text(_formatDiscountValue(discount))),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Đến: ${_formatDate(discount['expiration_date'])}'),
                    ],
                  ),
                ),
                DataCell(
                  Chip(
                    label: Text(status),
                    backgroundColor: statusColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editDiscount(discount),
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: const Text('Bạn có chắc chắn muốn xóa mã giảm giá này không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteDiscount(discount['id']);
                                    },
                                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}