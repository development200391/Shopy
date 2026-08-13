import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/cart_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/cart/cart_checkout_bar.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/cart/delete_confirm_sheet.dart';
import '../../widgets/cart/empty_cart_view.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../home/home_screen.dart';
import '../orders/order_history_screen.dart';
import '../wishlist/wishlist_screen.dart';

/// Halaman Keranjang — mencakup semua state di mockup `UI Design -
/// Keranjang, Wishlist`: terisi, kosong, promo voucher, swipe-to-delete,
/// konfirmasi hapus, dan ringkasan checkout (bottom sheet).
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        centerTitle: false,
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Kosongkan keranjang',
              onPressed: () async {
                final confirmed = await showDeleteConfirmSheet(
                  context,
                  title: 'Kosongkan keranjang?',
                  message: 'Semua produk di keranjang akan dihapus.',
                );
                if (confirmed == true) ref.read(cartProvider.notifier).clearAll();
              },
            ),
        ],
      ),
      body: cart.loading && cart.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.error != null && cart.isEmpty
          ? _CartErrorView(message: cart.error!, onRetry: () => ref.read(cartProvider.notifier).reload())
          : cart.isEmpty
          ? EmptyCartView(
              onStartShopping: () => Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen())),
            )
          : _CartBody(itemCount: cart.items.length),
      bottomNavigationBar: cart.isEmpty
          ? AppBottomNav(currentTab: AppTab.keranjang, onTap: (tab) => _onTabTap(context, tab))
          : const CartCheckoutBar(),
    );
  }

  void _onTabTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.keranjang:
        return;
      case AppTab.home:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      case AppTab.wishlist:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WishlistScreen()));
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

class _CartBody extends ConsumerWidget {
  final int itemCount;

  const _CartBody({required this.itemCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: cart.allSelected,
                activeColor: AppColors.primary,
                onChanged: (_) => notifier.toggleSelectAll(),
              ),
              Text('Pilih Semua ($itemCount barang)', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: cart.selectedCount == 0
                    ? null
                    : () async {
                        final ids = cart.selectedItems.map((item) => item.id).toList();
                        final confirmed = await showDeleteConfirmSheet(
                          context,
                          title: 'Hapus ${ids.length} produk?',
                          message: 'Produk yang dipilih akan dihapus dari keranjangmu.',
                        );
                        if (confirmed == true) {
                          for (final id in ids) {
                            notifier.removeItem(id);
                          }
                        }
                      },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Hapus'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final group in cart.storeGroups) ...[
            _StoreGroupHeader(group: group),
            const SizedBox(height: AppSpacing.xs),
            for (final item in group.items) CartItemCard(item: item),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _SummaryLine(label: 'Subtotal Produk', value: formatRupiah(cart.subtotal)),
          _SummaryLine(label: 'Ongkos Kirim', value: formatRupiah(cart.shippingCost)),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Kode voucher toko bisa dipakai di halaman Checkout.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _StoreGroupHeader extends StatelessWidget {
  final CartStoreGroup group;

  const _StoreGroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              group.storeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            formatRupiah(group.subtotal),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CartErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CartErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat keranjang', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
