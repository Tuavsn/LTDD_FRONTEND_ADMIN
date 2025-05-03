import 'package:flutter/material.dart';

class SidebarMenu extends StatelessWidget {
  final String currentUsername;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const SidebarMenu({
    Key? key,
    required this.currentUsername,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.blueGrey[800],
      child: Column(
        children: [
          _buildHeader(),
          _buildMenuItems(),
          const Spacer(),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentUsername,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quản trị viên',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {'icon': Icons.dashboard, 'title': 'Tổng quan'},
      {'icon': Icons.inventory, 'title': 'Sản phẩm'},
      {'icon': Icons.category, 'title': 'Danh mục'},
      {'icon': Icons.shopping_cart, 'title': 'Đơn hàng'},
      {'icon': Icons.local_offer, 'title': 'Khuyến mãi'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = selectedIndex == index;

        return ListTile(
          leading: Icon(
            item['icon'] as IconData,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          title: Text(
            item['title'] as String,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          tileColor: isSelected ? Colors.blue.withOpacity(0.3) : null,
          onTap: () => onItemSelected(index),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: Colors.white70,
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        onTap: onLogout,
      ),
    );
  }
}