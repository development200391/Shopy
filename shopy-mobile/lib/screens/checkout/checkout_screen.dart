import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/address/address.dart';
import '../../models/cart/cart_item.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/cart_state.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/address/address_form_sheet.dart';
import '../../widgets/checkout/address_picker_sheet.dart';
import '../../widgets/shared/placeholder_thumbnail.dart';
import 'checkout_success_screen.dart';

/// Halaman Checkout. Desain terpilih: **Bold & Colorful** (lihat
/// `UI Design - Checkout, Payment, Notifikasi/01_checkout_utama.png`).
///
/// Cuma barang yang dicentang ("selected") di halaman Keranjang yang
/// di-checkout — konsisten dengan tombol "Checkout (N)" di [CartCheckoutBar].
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _noteController = TextEditingController();
  Address? _selectedAddress;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final items = cart.selectedItems;

    // Set alamat default begitu data alamat pertama kali datang.
    if (_selectedAddress == null && addressState.defaultAddress != null) {
      _selectedAddress = addressState.defaultAddress;
    }

    final storeGroups = cart.selectedStoreGroups;
    final subtotal = items.fold(0, (sum, item) => sum + item.subtotal);
    final shippingCost = storeGroups.length * kMockShippingCost;
    final total = subtotal + shippingCost;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: items.isEmpty
          ? const Center(
              child: Text('Tidak ada produk dipilih untuk checkout.', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const _SectionLabel('Alamat Pengiriman'),
                const SizedBox(height: AppSpacing.sm),
                _AddressCard(
                  address: _selectedAddress,
                  loading: addressState.loading && addressState.items.isEmpty,
                  onChangeTap: () async {
                    final chosen = await showAddressPickerSheet(context, selectedId: _selectedAddress?.id);
                    if (chosen != null) setState(() => _selectedAddress = chosen);
                  },
                  onAddTap: () => showAddressFormSheet(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('Produk Dipesan'),
                const SizedBox(height: AppSpacing.sm),
                for (final group in storeGroups) _StoreOrderGroup(group: group),
                const SizedBox(height: AppSpacing.sm),
                const _SectionLabel('Catatan untuk Penjual (Opsional)'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan...',
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                _SummaryRow(label: 'Subtotal Produk', value: formatRupiah(subtotal)),
                _SummaryRow(label: 'Ongkos Kirim', value: formatRupiah(shippingCost)),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pembayaran',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              formatRupiah(total),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectedAddress == null || _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Buat Pesanan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    final address = _selectedAddress;
    if (address == null) return;

    setState(() => _submitting = true);
    try {
      final order = await ref
          .read(orderApiServiceProvider)
          .checkout(
            addressId: address.id,
            cartItemIds: ref.read(cartProvider).selectedItems.map((item) => item.id).toList(),
            note: _noteController.text.trim(),
          );
      await ref.read(cartProvider.notifier).reload();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => CheckoutSuccessScreen(order: order)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address? address;
  final bool loading;
  final VoidCallback onChangeTap;
  final VoidCallback onAddTap;

  const _AddressCard({required this.address, required this.loading, required this.onChangeTap, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final address = this.address;
    if (address == null) {
      return OutlinedButton.icon(
        onPressed: onAddTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(52),
        ),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Tambah Alamat Pengiriman'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  address.label,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: onChangeTap,
                child: const Text('Ganti'),
              ),
            ],
          ),
          Text('${address.recipientName}  ${address.phoneNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            '${address.fullAddress}, ${address.city}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StoreOrderGroup extends StatelessWidget {
  final CartStoreGroup group;

  const _StoreOrderGroup({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(group.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in group.items) _OrderItemCard(item: item),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JNE Reguler · 2-3 hari', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                      'Kurir bisa disesuaikan penjual saat mengirim',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  formatRupiah(kMockShippingCost),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final CartItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56, height: 56, child: PlaceholderThumbnail()),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${item.qty}x ${formatRupiah(item.price)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
