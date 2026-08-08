import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/wishlist_provider.dart';
import '../../providers/wishlist_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../../widgets/wishlist/empty_wishlist_view.dart';
import '../../widgets/wishlist/wishlist_grid_card.dart';
import '../../widgets/wishlist/wishlist_list_card.dart';
import '../../widgets/wishlist/wishlist_selection_bar.dart';
import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../orders/order_history_screen.dart';

/// Halaman Wishlist — mencakup semua state di mockup `UI Design -
/// Keranjang, Wishlist`: grid, list, mode pilih (bulk hapus/tambah
/// keranjang), dan kosong.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final notifier = ref.read(wishlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(wishlist.selectionMode ? '${wishlist.selectedCount} dipilih' : 'Wishlist'),
        centerTitle: false,
        leading: wishlist.selectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: notifier.exitSelectionMode)
            : null,
        actions: wishlist.selectionMode
            ? [
                TextButton(
                  onPressed: notifier.exitSelectionMode,
                  child: const Text('Batal'),
                ),
              ]
            : [
                if (!wishlist.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Center(
                      child: Text(
                        '${wishlist.items.length} produk',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ganti tampilan',
                    icon: Icon(
                      wishlist.viewMode == WishlistViewMode.grid ? Icons.view_list_outlined : Icons.grid_view_outlined,
                    ),
                    onPressed: () => notifier.setViewMode(
                      wishlist.viewMode == WishlistViewMode.grid ? WishlistViewMode.list : WishlistViewMode.grid,
                    ),
                  ),
                ],
              ],
      ),
      body: wishlist.loading && wishlist.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : wishlist.error != null && wishlist.isEmpty
          ? _WishlistErrorView(message: wishlist.error!, onRetry: notifier.reload)
          : wishlist.isEmpty
          ? EmptyWishlistView(
              onExplore: () => Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen())),
            )
          : wishlist.viewMode == WishlistViewMode.grid
          ? _WishlistGrid(wishlist: wishlist, notifier: notifier)
          : _WishlistList(wishlist: wishlist, notifier: notifier),
      bottomNavigationBar: wishlist.selectionMode
          ? const WishlistSelectionBar()
          : AppBottomNav(currentTab: AppTab.wishlist, onTap: (tab) => _onTabTap(context, tab)),
    );
  }

  void _onTabTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.wishlist:
        return;
      case AppTab.home:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      case AppTab.keranjang:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CartScreen()));
        return;
      case AppTab.profil:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
        return;
      case AppTab.kategori:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Halaman ini belum tersedia.')));
        return;
    }
  }
}

class _WishlistGrid extends StatelessWidget {
  final WishlistState wishlist;
  final WishlistNotifier notifier;

  const _WishlistGrid({required this.wishlist, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: wishlist.items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final item = wishlist.items[index];
        return WishlistGridCard(
          item: item,
          selectionMode: wishlist.selectionMode,
          selected: wishlist.isSelected(item.id),
          onTap: () {
            if (wishlist.selectionMode) notifier.toggleSelected(item.id);
          },
          onLongPress: () {
            if (!wishlist.selectionMode) notifier.enterSelectionMode(item.id);
          },
        );
      },
    );
  }
}

class _WishlistList extends StatelessWidget {
  final WishlistState wishlist;
  final WishlistNotifier notifier;

  const _WishlistList({required this.wishlist, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: wishlist.items.length,
      itemBuilder: (context, index) {
        final item = wishlist.items[index];
        return WishlistListCard(
          item: item,
          selectionMode: wishlist.selectionMode,
          selected: wishlist.isSelected(item.id),
          onTap: () {
            if (wishlist.selectionMode) notifier.toggleSelected(item.id);
          },
          onLongPress: () {
            if (!wishlist.selectionMode) notifier.enterSelectionMode(item.id);
          },
        );
      },
    );
  }
}

class _WishlistErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WishlistErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat wishlist', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
