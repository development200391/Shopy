import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopy_mobile/models/auth/auth_user.dart';
import 'package:shopy_mobile/models/catalog/category.dart';
import 'package:shopy_mobile/models/catalog/product_summary.dart';
import 'package:shopy_mobile/providers/auth_provider.dart';
import 'package:shopy_mobile/providers/auth_state.dart';
import 'package:shopy_mobile/providers/cart_provider.dart';
import 'package:shopy_mobile/providers/cart_state.dart';
import 'package:shopy_mobile/providers/catalog_provider.dart';
import 'package:shopy_mobile/providers/notification_provider.dart';
import 'package:shopy_mobile/providers/wishlist_provider.dart';
import 'package:shopy_mobile/providers/wishlist_state.dart';
import 'package:shopy_mobile/screens/home/home_screen.dart';

/// Auth sudah authenticated dari awal, jadi test tidak perlu mock
/// `flutter_secure_storage` (yang butuh platform channel) lewat [AuthNotifier.bootstrap].
class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.authenticated(
    AuthUser(id: 'user-1', email: 'ramdan@example.com', fullName: 'Ramdan Nur'),
  );
}

/// Cart & wishlist sekarang fetch dari backend saat provider dibuat —
/// di-override dengan state tetap supaya test tidak memicu network call asli.
class _FakeCartNotifier extends CartNotifier {
  @override
  CartState build() => const CartState(items: []);
}

class _FakeWishlistNotifier extends WishlistNotifier {
  @override
  WishlistState build() => const WishlistState(items: []);
}

final _authOverride = authProvider.overrideWith(_FakeAuthNotifier.new);
final _cartOverride = cartProvider.overrideWith(_FakeCartNotifier.new);
final _wishlistOverride = wishlistProvider.overrideWith(_FakeWishlistNotifier.new);

void main() {
  testWidgets('HomeScreen menampilkan sapaan, kategori, dan produk populer', (tester) async {
    const categories = [
      Category(id: 'cat-1', name: 'Elektronik', slug: 'elektronik'),
      Category(id: 'cat-2', name: 'Fashion', slug: 'fashion'),
    ];
    const products = [
      ProductSummary(
        id: 'prod-1',
        name: 'Smartphone X100',
        slug: 'smartphone-x100',
        price: 2999000,
        ratingAverage: 4.5,
        ratingCount: 120,
        categoryId: 'cat-1',
        categoryName: 'Elektronik',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _authOverride,
          _cartOverride,
          _wishlistOverride,
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
          homeCategoriesProvider.overrideWith((ref) async => categories),
          popularProductsProvider.overrideWith((ref) async => products),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Halo, Ramdan'), findsOneWidget);
    expect(find.text('Elektronik'), findsOneWidget);
    expect(find.text('Smartphone X100'), findsOneWidget);
    expect(find.text('Rp2.999.000'), findsOneWidget);
  });

  testWidgets('HomeScreen menampilkan pesan error & tombol coba lagi saat produk gagal dimuat', (
    tester,
  ) async {
    const categories = [Category(id: 'cat-1', name: 'Elektronik', slug: 'elektronik')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _authOverride,
          _cartOverride,
          _wishlistOverride,
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
          homeCategoriesProvider.overrideWith((ref) async => categories),
          popularProductsProvider.overrideWith(
            (ref) => Future<List<ProductSummary>>.error(Exception('network error')),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Gagal memuat produk populer'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
