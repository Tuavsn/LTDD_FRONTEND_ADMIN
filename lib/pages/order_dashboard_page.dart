import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/auth_service.dart';
import 'package:intl/intl.dart';
import './dashboard_service.dart';
import './sidebar_menu.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String _currentUsername = 'Admin';
  Map<String, dynamic>? _selectedOrder;
  String? _selectedOrderId;

  // Filter state
  String _filterStatus = 'Tất cả';
  final List<String> _statusOptions = [
    'Tất cả',
    'Đang xử lý',
    'Đang giao',
    'Đã giao',
    'Đã hủy',
  ];
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await DashboardService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentUsername = profile['name'] ?? 'Admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await DashboardService.getAllOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  List<dynamic> _getFilteredOrders() {
    return _orders.where((order) {
      if (_searchQuery.isNotEmpty) {
        final orderId = order['_id']?.toString().toLowerCase() ?? '';
        final customerName =
            order['customerName']?.toString().toLowerCase() ?? '';
        final customerPhone =
            order['customerPhone']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();

        if (!orderId.contains(searchLower) &&
            !customerName.contains(searchLower) &&
            !customerPhone.contains(searchLower)) {
          return false;
        }
      }

      if (_filterStatus != 'Tất cả' &&
          order['state']?.toLowerCase() != _filterStatus.toLowerCase()) {
        return false;
      }

      if (_startDate != null || _endDate != null) {
        final orderDate =
            order['createdAt'] != null
                ? DateTime.parse(order['createdAt'])
                : null;
        if (orderDate == null) return true;

        if (_startDate != null && orderDate.isBefore(_startDate!)) {
          return false;
        }

        if (_endDate != null) {
          final endDate = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day + 1,
          );
          if (orderDate.isAfter(endDate)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadOrderDetails(dynamic order) async {
    try {
      if (order == null) return;

      // 1. Xác định orderId
      late final String orderId;
      if (order is Map<String, dynamic>) {
        orderId = order['_id']?.toString() ?? '';
      } else if (order is String) {
        orderId = order;
      } else {
        orderId = order['_id']?.toString() ?? order.toString();
      }

      // 2. Gọi API bên ngoài setState
      final fetchedOrder = await DashboardService.getOrderById(orderId);

      // 3. Cập nhật state dựa trên kết quả
      if (mounted) {
        if (fetchedOrder != null) {
          setState(() {
            _selectedOrder = fetchedOrder;
            _selectedOrderId = orderId;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy thông tin đơn hàng')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi tải thông tin đơn hàng: $e'),
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (_selectedOrderId == null) return;

    try {
      final success = await DashboardService.updateOrderStatus(
        _selectedOrderId!,
        newStatus,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái đơn hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrders();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái đơn hàng'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearSelectedOrder() {
    setState(() {
      _selectedOrder = null;
      _selectedOrderId = null;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _startDate && mounted) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _endDate && mounted) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _filterStatus = 'Tất cả';
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật danh sách đơn hàng'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _exportOrderData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng xuất dữ liệu đang được phát triển'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            currentUsername: _currentUsername,
            selectedIndex: 3,
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
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildOrdersContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersContent() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 16),
          _buildFilterBar(),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrdersListHeader(),
                          const SizedBox(height: 16),
                          Expanded(child: _buildOrdersList()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child:
                          _selectedOrder != null
                              ? _buildOrderDetails()
                              : _buildEmptyDetailsPlaceholder(),
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

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quản lý đơn hàng',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _exportOrderData,
              icon: const Icon(Icons.download),
              label: const Text('Xuất dữ liệu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _refreshOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc đơn hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo mã đơn, tên KH, SĐT...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items:
                        _statusOptions.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _filterStatus = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Từ ngày',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Chọn ngày bắt đầu',
                        style: TextStyle(
                          color:
                              _startDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Đến ngày',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Chọn ngày kết thúc',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Đặt lại bộ lọc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersListHeader() {
    final filteredOrders = _getFilteredOrders();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Danh sách đơn hàng (${filteredOrders.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _getFilteredOrders();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy đơn hàng nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredOrders.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final id = order['_id'] ?? '';
        final orderStatus = order['state'] ?? 'Đang xử lý';
        final orderDate =
            order['createdAt'] != null
                ? DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(DateTime.parse(order['createdAt']))
                : 'N/A';
        final customerName = order['customerName'] ?? 'Khách hàng';

        return InkWell(
          onTap: () => _loadOrderDetails(order),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedOrderId == id ? Colors.blue.shade50 : null,
              borderRadius: BorderRadius.circular(8),
              border:
                  _selectedOrderId == id
                      ? Border.all(color: Colors.blue, width: 1)
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(orderStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getOrderStatusIcon(orderStatus),
                    color: _getOrderStatusColor(orderStatus),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng #$id',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      orderDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'đ',
                      ).format(order['totalPrice'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(orderStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    orderStatus,
                    style: TextStyle(
                      color: _getOrderStatusColor(orderStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildEmptyDetailsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chọn một đơn hàng để xem chi tiết',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final order = _selectedOrder!;
    final orderStatus = order['state'] ?? 'Đang xử lý';
    final orderDate =
        order['createdAt'] != null
            ? DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(order['createdAt']))
            : 'N/A';
    final totalPrice = order['totalPrice'] ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final dynamic userRaw = order['user'];
    Map<String, dynamic>? user;
    if (userRaw is Map<String, dynamic>) {
      user = userRaw;
    } else if (userRaw is String && userRaw.trim().startsWith('{')) {
      try {
        user = jsonDecode(userRaw) as Map<String, dynamic>;
      } catch (e) {
        user = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết đơn hàng #${order['_id']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getOrderStatusColor(
                          orderStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getOrderStatusIcon(orderStatus),
                            size: 14,
                            color: _getOrderStatusColor(orderStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            orderStatus,
                            style: TextStyle(
                              color: _getOrderStatusColor(orderStatus),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ngày đặt: $orderDate',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelectedOrder,
              tooltip: 'Đóng',
            ),
          ],
        ),
        const Divider(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Thông tin khách hàng',
                  icon: Icons.person,
                  content: Column(
                    children: [
                      _buildInfoRow('Khách hàng', user?['fullname'] ?? 'N/A'),
                      _buildInfoRow('Điện thoại', order['phone'] ?? 'N/A'),
                      _buildInfoRow('Địa chỉ', order['address'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Sản phẩm đã đặt',
                  icon: Icons.shopping_bag,
                  content: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Sản phẩm',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'SL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Đơn giá',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Thành tiền',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Không có sản phẩm nào trong đơn hàng này',
                          ),
                        )
                      else
                        ...items
                            .map((item) => _buildOrderItemRow(item))
                            .toList(),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        'Tổng cộng',
                        totalPrice,
                        isBold: true,
                        textColor: Colors.blue[800],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (orderStatus.toLowerCase() != 'đã hủy' &&
            orderStatus.toLowerCase() != 'đã giao')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (orderStatus.toLowerCase() == 'đang xử lý')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('Đang giao'),
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Xác nhận giao hàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (orderStatus.toLowerCase() == 'đang giao')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('Đã giao'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Đánh dấu đã giao'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus('Đã hủy'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Hủy đơn hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(Map<String, dynamic> item) {
  // 1. Lấy object product và quantity
  final product = item['product'] as Map<String, dynamic>? ?? {};
  final quantity = item['quantity'] as int? ?? 1;

  // 2. Lấy tên và giá từ product
  final name = product['name'] as String? ?? 'Sản phẩm';
  final price = (product['price'] as num?)?.toDouble() ?? 0.0;
  final total = quantity * price;

  // 3. Lấy variant nếu có (nếu bạn có trường variant trong product)
  final variant = product['variant'] as String?;

  // 4. Xử lý lấy URL hình ảnh một cách chính xác
  String? imageUrl;
  if (product['image'] is List && (product['image'] as List).isNotEmpty) {
    var imageData = (product['image'] as List).first;
    if (imageData is Map<String, dynamic> && imageData.containsKey('url')) {
      imageUrl = imageData['url'] as String?;
    }
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        // Icon hoặc ảnh thumbnail
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Icon(Icons.inventory_2, color: Colors.grey[500], size: 20)
              : null,
        ),

        const SizedBox(width: 12),

        // Tên và variant
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (variant != null)
                Text(
                  variant,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),

        // Số lượng
        Expanded(
          flex: 1,
          child: Text(quantity.toString(), textAlign: TextAlign.center),
        ),

        // Đơn giá
        Expanded(
          flex: 2,
          child: Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price),
            textAlign: TextAlign.right,
          ),
        ),

        // Thành tiền
        Expanded(
          flex: 2,
          child: Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(total),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSummaryRow(
    String label,
    num amount, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOrderStatusIcon(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return Icons.plus_one;
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'delivering':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.cancel;
      case 'canceled':
      default:
        return Icons.pending;
    }
  }

  Color _getOrderStatusColor(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return Colors.blueGrey;
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'delivering':
        return Colors.blue;
      case 'delivered':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}
