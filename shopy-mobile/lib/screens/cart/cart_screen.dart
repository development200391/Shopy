import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/cart/cart_checkout_bar.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/cart/delete_confirm_sheet.dart';
import '../../widgets/cart/empty_cart_view.dart';
import '../../widgets/cart/promo_code_section.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../home/home_screen.dart';
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
      body: cart.isEmpty
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
      case AppTab.kategori:
      case AppTab.profil:
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
          for (final item in cart.items) CartItemCard(item: item),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          const PromoCodeSection(),
          const SizedBox(height: AppSpacing.md),
          _SummaryLine(label: 'Subtotal Produk', value: formatRupiah(cart.subtotal)),
          _SummaryLine(label: 'Ongkos Kirim', value: formatRupiah(cart.shippingCost)),
          if (cart.hasPromo)
            _SummaryLine(
              label: 'Diskon Voucher',
              value: '-${formatRupiah(cart.promoDiscount)}',
              valueColor: AppColors.primary,
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryLine({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
