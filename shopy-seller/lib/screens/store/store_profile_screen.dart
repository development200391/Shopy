import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store/store_detail.dart';
import '../../models/store/store_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../providers/store_settings_provider.dart';
import '../../services/api_client.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_screen.dart';
import '../finance/finance_screen.dart';
import '../order/order_list_screen.dart';
import '../promo/promo_voucher_screen.dart';
import '../product/product_list_screen.dart';
import 'bank_accounts_screen.dart';
import 'edit_store_profile_screen.dart';
import 'store_addresses_screen.dart';

/// Halaman utama seller setelah toko `Active` — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/profil-toko-seller-bold-colorful.png`).
class StoreProfileScreen extends ConsumerWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(storeDetailProvider)),
        data: (store) => _StoreProfileBody(store: store),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat profil toko', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _StoreProfileBody extends ConsumerWidget {
  final StoreDetail store;

  const _StoreProfileBody({required this.store});

  void _notAvailableYet(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia.')));
  }

  Future<void> _toggleOpen(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await ref.read(sellerApiServiceProvider).setStoreOpen(value);
      ref.invalidate(storeDetailProvider);
    } on SellerException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _Header(store: store),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  _StatsCard(store: store),
                  const SizedBox(height: AppSpacing.md),
                  _OpenToggleCard(
                    isOpen: store.isOpen,
                    onChanged: (value) => _toggleOpen(context, ref, value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OrdersCard(
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderListScreen())),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProductsCard(
                    productCount: store.productCount,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const ProductListScreen())),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MenuCard(
                    onEditProfile: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const EditStoreProfileScreen())),
                    onAddresses: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const StoreAddressesScreen())),
                    onBankAccounts: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const BankAccountsScreen())),
                    onFinance: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceScreen())),
                    onPromo: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PromoVoucherScreen())),
                    onNotAvailable: () => _notAvailableYet(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Keluar Akun'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StoreDetail store;

  const _Header({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xxl),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.onPrimary.withValues(alpha: 0.15),
            backgroundImage: store.logoUrl == null
                ? null
                : NetworkImage('${resolveApiBaseUrl()}${store.logoUrl}'),
            child: store.logoUrl == null
                ? const Icon(Icons.storefront_outlined, color: AppColors.onPrimary, size: 40)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            store.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
          ),
          if (store.status == StoreStatus.active) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Toko Terverifikasi',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final StoreDetail store;

  const _StatsCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          _Stat(label: 'Produk', value: '${store.productCount}'),
          const _StatDivider(),
          _Stat(label: 'Pengikut', value: '${store.followerCount}'),
          const _StatDivider(),
          _Stat(label: 'Rating', value: store.ratingAverage.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 32, child: VerticalDivider(color: AppColors.divider));
  }
}

class _OpenToggleCard extends StatelessWidget {
  final bool isOpen;
  final ValueChanged<bool> onChanged;

  const _OpenToggleCard({required this.isOpen, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Icon(Icons.power_settings_new, color: isOpen ? AppColors.success : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Toko Buka', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isOpen ? 'Pesanan masuk otomatis diterima' : 'Toko sedang tutup',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: isOpen, activeThumbColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  final int productCount;
  final VoidCallback onTap;

  const _ProductsCard({required this.productCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Produk Saya', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$productCount produk terdaftar', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _OrdersCard extends StatelessWidget {
  final VoidCallback onTap;

  const _OrdersCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Kelola pesanan dari pembeli', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onAddresses;
  final VoidCallback onBankAccounts;
  final VoidCallback onFinance;
  final VoidCallback onPromo;
  final VoidCallback onNotAvailable;

  const _MenuCard({
    required this.onEditProfile,
    required this.onAddresses,
    required this.onBankAccounts,
    required this.onFinance,
    required this.onPromo,
    required this.onNotAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.storefront_outlined, 'Edit Profil Toko', 'Nama, logo, deskripsi', onEditProfile),
      (Icons.location_on_outlined, 'Alamat & Pengiriman', 'Alamat pickup, kurir aktif', onAddresses),
      (Icons.account_balance_outlined, 'Rekening Bank', 'Buat pencairan dana', onBankAccounts),
      (Icons.payments_outlined, 'Keuangan & Pencairan', 'Saldo & riwayat pencairan', onFinance),
      (Icons.show_chart, 'Statistik Penjualan', 'Omzet, produk terlaris', onNotAvailable),
      (Icons.local_offer_outlined, 'Promo & Voucher', 'Kelola promo toko', onPromo),
      (Icons.star_outline, 'Ulasan Produk', 'Balas ulasan pembeli', onNotAvailable),
      (Icons.notifications_outlined, 'Pengaturan Notifikasi', 'Pesanan, chat, promo', onNotAvailable),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(items[i].$1, color: AppColors.primary, size: 20),
                  ),
                  title: Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(items[i].$3),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: items[i].$4,
                ),
                if (i < items.length - 1) const Divider(height: 1, indent: 72),
              ],
            ),
        ],
      ),
    );
  }
}
