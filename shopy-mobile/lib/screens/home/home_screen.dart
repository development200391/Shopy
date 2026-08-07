import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../wishlist/wishlist_screen.dart';

/// Placeholder Home — listing produk & kategori asli baru dikerjakan di
/// Fase 2 (Flutter: halaman Home, lihat TASKS.md). Tombol Keranjang/Wishlist
/// di bawah ini sengaja ditambahkan sementara supaya kedua halaman yang
/// sudah jadi (Fase 3) bisa dicoba sebelum Home asli ada.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Halo, ${user?.fullName ?? ''} \u{1F44B}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Halaman Home asli (listing produk & kategori) belum dikerjakan — '
                'lihat Fase 2 di TASKS.md.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: AppTab.home,
        onTap: (tab) => _onTabTap(context, tab),
      ),
    );
  }

  void _onTabTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return;
      case AppTab.keranjang:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CartScreen()));
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
