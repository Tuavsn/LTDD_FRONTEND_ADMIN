import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import './dashboard_service.dart';
import './storage_service.dart';
import './sidebar_menu.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _userProfile = {};
  String _currentUsername = 'Admin';

  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _orders = [];
  List<dynamic> _discounts = [];
  
  // Thống kê doanh thu theo ngày trong tuần
  List<double> _revenueByDayOfWeek = List.filled(7, 0);
  double _totalRevenue = 0;
  int _completedOrdersCount = 0;
  int _pendingOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDashboardData();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await DashboardService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _currentUsername = profile['name'] ?? 'Admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await DashboardService.getAllProducts();
      final categories = await DashboardService.getAllCategories();
      final orders = await DashboardService.getAllOrders();
      final discounts = await DashboardService.getAllDiscounts();

      // Tính toán thống kê từ dữ liệu đơn hàng
      _calculateStats(orders);

      setState(() {
        _products = products;
        _categories = categories;
        _orders = orders;
        _discounts = discounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStats(List<dynamic> orders) {
    // Reset thống kê
    _revenueByDayOfWeek = List.filled(7, 0);
    _totalRevenue = 0;
    _completedOrdersCount = 0;
    _pendingOrdersCount = 0;

    // Chỉ tính toán từ đơn hàng đã được chấp nhận (accepted)
    final acceptedOrders = orders.where((order) => order['state'] == 'accepted').toList();
    
    for (var order in acceptedOrders) {
      // Tính tổng doanh thu
      _totalRevenue += (order['totalPrice'] as num).toDouble();
      
      // Tính doanh thu theo ngày trong tuần
      if (order['createdAt'] != null) {
        final orderDate = DateTime.parse(order['createdAt']);
        final dayOfWeek = orderDate.weekday - 1; // 0 = Thứ 2, 6 = Chủ nhật
        _revenueByDayOfWeek[dayOfWeek] += (order['totalPrice'] as num).toDouble();
      }
    }

    // Đếm số đơn hàng theo trạng thái
    for (var order in orders) {
      String state = order['state'].toString().toLowerCase();
      if (state == 'accepted' || state == 'delivered') {
        _completedOrdersCount++;
      } else if (state == 'new' || state == 'pending' || state == 'delivering') {
        _pendingOrdersCount++;
      }
    }
  }

  Future<void> _handleLogout() async {
    await StorageService.deleteToken();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            currentUsername: _currentUsername,
            selectedIndex: 0,
            onItemSelected: (index) {
              switch (index) {
                case 0:
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
                    : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    // Format số tiền với đơn vị VND
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                'Tổng sản phẩm',
                '${_products.length}',
                Icons.inventory,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Tổng doanh thu',
                formatCurrency.format(_totalRevenue),
                Icons.monetization_on,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Đơn hoàn thành',
                '$_completedOrdersCount',
                Icons.check_circle,
                Colors.teal,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Đơn đang xử lý',
                '$_pendingOrdersCount',
                Icons.pending_actions,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng quan doanh thu (theo ngày)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: _buildRevenueChart()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đơn hàng gần đây',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: _buildRecentOrdersList()),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    // Chuyển đổi doanh thu thành triệu đồng để hiển thị trên biểu đồ
    final revenueInMillions = _revenueByDayOfWeek.map((e) => e / 1000000).toList();
    
    final spots = List.generate(7, (index) {
      return FlSpot(index.toDouble(), revenueInMillions[index]);
    });

    // Tìm giá trị lớn nhất để làm tròn maxY
    double maxRevenue = revenueInMillions.isEmpty ? 1 : revenueInMillions.reduce((a, b) => a > b ? a : b);
    double roundedMaxY = (maxRevenue * 1.2).ceilToDouble() + 1; // Thêm 20% và làm tròn lên

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double value, TitleMeta meta) {
                const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                final idx = value.toInt();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    (idx >= 0 && idx < days.length) ? days[idx] : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toStringAsFixed(1)}tr',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: roundedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList() {
    // Lấy tối đa 5 đơn hàng gần nhất, sắp xếp theo thời gian giảm dần
    final sortedOrders = List.of(_orders);
    
    // Sắp xếp đơn hàng theo thời gian giảm dần (mới nhất lên đầu)
    sortedOrders.sort((a, b) {
      final aDate = DateTime.parse(a['createdAt']);
      final bDate = DateTime.parse(b['createdAt']);
      return bDate.compareTo(aDate);
    });
    
    final recentOrders = sortedOrders.take(5).toList();

    if (recentOrders.isEmpty) {
      return const Center(
        child: Text('Không có đơn hàng gần đây'),
      );
    }

    return ListView.builder(
      itemCount: recentOrders.length,
      padding: EdgeInsets.zero, // Loại bỏ padding mặc định
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        final orderStatus = order['state'] ?? 'pending';
        final orderDate = order['createdAt'] != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['createdAt']))
            : 'N/A';
        final orderTotal = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order['totalPrice'] ?? 0);

        return ListTile(
          leading: Icon(
            _getOrderStatusIcon(orderStatus),
            color: _getOrderStatusColor(orderStatus),
          ),
          title: Text('Đơn #${order['_id']?.toString().substring(order['_id'].toString().length - 6) ?? 'N/A'}'),
          subtitle: Text('$orderDate - $orderTotal'),
          trailing: Chip(
            label: Text(_getOrderStatusText(orderStatus)),
            backgroundColor: _getOrderStatusColor(orderStatus).withOpacity(0.1),
            labelStyle: TextStyle(color: _getOrderStatusColor(orderStatus)),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/orders', arguments: order['_id']);
          },
        );
      },
    );
  }

  IconData _getOrderStatusIcon(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return Icons.fiber_new;
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'delivering':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getOrderStatusColor(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'delivering':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getOrderStatusText(String state) {
    switch (state.toLowerCase()) {
      case 'new':
        return 'Mới';
      case 'accepted':
        return 'Đã xác nhận';
      case 'pending':
        return 'Đang xử lý';
      case 'delivering':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'canceled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }
}