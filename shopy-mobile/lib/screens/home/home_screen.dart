import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/catalog/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/products/product_card.dart';
import '../../widgets/shared/app_bottom_nav.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../notifications/notification_history_screen.dart';
import '../orders/order_history_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/product_search_screen.dart';
import '../wishlist/wishlist_screen.dart';

/// Halaman Home — listing produk & kategori. Desain terpilih: **Bold &
/// Colorful** (lihat `design/assets/home-bold-colorful.png`).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: minta izin notifikasi & daftarkan device token begitu
    // user sampai di Home (selalu berarti sudah login). Gagal dengan aman
    // kalau Firebase belum dikonfigurasi (lihat `firebase_options.dart`).
    Future.microtask(() => ref.read(pushNotificationServiceProvider).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final cartCount = ref.watch(cartItemCountProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).maybeWhen(data: (v) => v, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeCategoriesProvider);
            ref.invalidate(popularProductsProvider);
            await ref.read(popularProductsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _HomeHeader(
                fullName: user?.fullName,
                cartCount: cartCount,
                unreadNotificationCount: unreadCount,
                onLogout: () => _logout(context, ref),
              ),
              const SizedBox(height: AppSpacing.md),
              _SearchBar(
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProductSearchScreen())),
              ),
              const SizedBox(height: AppSpacing.md),
              const _PromoBanner(),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle(title: 'Kategori'),
              const SizedBox(height: AppSpacing.sm),
              const _CategoryRow(),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Produk Populer',
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProductSearchScreen()),
                  ),
                  child: const Text('Lihat Semua'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PopularProductsGrid(),
              const SizedBox(height: AppSpacing.xl),
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

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _onTabTap(BuildContext context, AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return;
      case AppTab.keranjang:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CartScreen()));
        return;
      case AppTab.wishlist:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const WishlistScreen()));
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

class _HomeHeader extends StatelessWidget {
  final String? fullName;
  final int cartCount;
  final int unreadNotificationCount;
  final VoidCallback onLogout;

  const _HomeHeader({
    required this.fullName,
    required this.cartCount,
    required this.unreadNotificationCount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = (fullName ?? '').trim();
    final firstName = trimmed.isEmpty ? '' : trimmed.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $firstName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Mau belanja apa hari ini?', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          onPressed: onLogout,
          tooltip: 'Logout',
          icon: const Icon(Icons.logout, color: AppColors.textSecondary),
        ),
        _IconWithBadge(
          icon: Icons.notifications_none,
          count: unreadNotificationCount,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationHistoryScreen())),
        ),
        _IconWithBadge(
          icon: Icons.shopping_cart_outlined,
          count: cartCount,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ],
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _IconWithBadge({required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: AppColors.textPrimary)),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('Cari produk favoritmu...', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const Icon(Icons.tune, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diskon Spesial', style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 4),
                Text(
                  'Hingga 50%',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Berlaku untuk semua kategori', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Positioned(right: -30, top: -20, child: _blob(120, Colors.black.withValues(alpha: 0.08))),
          Positioned(right: -10, bottom: -30, child: _blob(90, Colors.black.withValues(alpha: 0.08))),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return SizedBox(
      height: 88,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InlineError(
          message: 'Gagal memuat kategori',
          onRetry: () => ref.invalidate(homeCategoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryItem(
                category: category,
                highlighted: index == 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductSearchScreen(categoryId: category.id, categoryName: category.name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final bool highlighted;
  final VoidCallback onTap;

  const _CategoryItem({required this.category, required this.highlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: highlighted ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconForCategory(category.slug), color: highlighted ? Colors.white : AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String slug) {
    switch (slug) {
      case 'elektronik':
        return Icons.devices_other;
      case 'fashion':
        return Icons.checkroom;
      case 'rumah-tangga':
        return Icons.chair_outlined;
      case 'olahraga':
        return Icons.sports_soccer;
      default:
        return Icons.category_outlined;
    }
  }
}

class _PopularProductsGrid extends ConsumerWidget {
  const _PopularProductsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(popularProductsProvider);

    return productsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: _InlineError(
          message: 'Gagal memuat produk populer',
          onRetry: () => ref.invalidate(popularProductsProvider),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('Belum ada produk', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug))),
            );
          },
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
