import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../providers/seller_chat_provider.dart';
import '../../providers/seller_dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../order/order_list_screen.dart';
import '../product/product_list_screen.dart';
import '../store/store_profile_screen.dart';

/// Shell navigasi utama seller — bottom nav 5 tab (TASKSELLER.md Fase 8),
/// menggantikan navigasi push-only dari `StoreProfileScreen` sebagai satu-satunya
/// halaman utama sejak Fase 0-7.
class SellerHomeShell extends ConsumerStatefulWidget {
  const SellerHomeShell({super.key});

  @override
  ConsumerState<SellerHomeShell> createState() => _SellerHomeShellState();
}

class _SellerHomeShellState extends ConsumerState<SellerHomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pushNotificationServiceProvider).initialize());
  }

  static const _tabs = [
    DashboardScreen(),
    ProductListScreen(),
    OrderListScreen(),
    ChatListScreen(),
    StoreProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final newOrders = ref.watch(sellerDashboardProvider).value?.needsFollowUp.newOrders ?? 0;
    final unreadChats = ref.watch(sellerChatRoomsProvider).value?.fold<int>(0, (sum, r) => sum + r.unreadCount) ?? 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Produk'),
          NavigationDestination(
            icon: _BadgedIcon(count: newOrders, icon: Icons.receipt_long_outlined),
            selectedIcon: _BadgedIcon(count: newOrders, icon: Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: _BadgedIcon(count: unreadChats, icon: Icons.chat_bubble_outline),
            selectedIcon: _BadgedIcon(count: unreadChats, icon: Icons.chat_bubble),
            label: 'Chat',
          ),
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Toko'),
        ],
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  final int count;
  final IconData icon;

  const _BadgedIcon({required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
