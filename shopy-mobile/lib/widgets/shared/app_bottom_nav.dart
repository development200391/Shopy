import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';

enum AppTab { home, kategori, keranjang, wishlist, profil }

/// Bottom navigation bar yang dipakai di semua halaman tab utama (Home,
/// Kategori, Keranjang, Wishlist, Profil). Ikon Keranjang otomatis menampilkan
/// badge jumlah barang lewat [cartItemCountProvider], jadi selalu sinkron
/// dengan isi keranjang di layar mana pun tanpa perlu passing state manual.
///
/// Widget ini cuma tampilan + callback [onTap] — layar pemanggil yang
/// menentukan mau navigasi ke mana (lihat `cart_screen.dart` /
/// `wishlist_screen.dart` untuk contoh pemakaian).
class AppBottomNav extends ConsumerWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;

  const AppBottomNav({super.key, required this.currentTab, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                tab: AppTab.home,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                current: currentTab,
                onTap: onTap,
              ),
              _NavItem(
                tab: AppTab.kategori,
                label: 'Kategori',
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                current: currentTab,
                onTap: onTap,
              ),
              _NavItem(
                tab: AppTab.keranjang,
                label: 'Keranjang',
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                current: currentTab,
                onTap: onTap,
                badgeCount: cartCount,
              ),
              _NavItem(
                tab: AppTab.wishlist,
                label: 'Wishlist',
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                current: currentTab,
                onTap: onTap,
              ),
              _NavItem(
                tab: AppTab.profil,
                label: 'Profil',
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                current: currentTab,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppTab tab;
  final AppTab current;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final ValueChanged<AppTab> onTap;
  final int badgeCount;

  const _NavItem({
    required this.tab,
    required this.current,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final active = tab == current;
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon, color: color, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
