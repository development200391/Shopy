import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog/product_summary.dart';
import '../models/store/store_public_profile.dart';
import '../services/store_api_service.dart';
import 'auth_provider.dart';

final storeApiServiceProvider = Provider<StoreApiService>((ref) {
  return StoreApiService(ref.watch(apiClientProvider));
});

/// Retry otomatis Riverpod dimatikan — halaman Profil Toko pakai tombol
/// "Coba lagi" manual sendiri, sama pola seperti `catalog_provider.dart`.
Duration? _noRetry(int retryCount, Object error) => null;

final storeProfileProvider = FutureProvider.family<StorePublicProfile, String>((ref, slug) {
  return ref.watch(storeApiServiceProvider).getStoreBySlug(slug);
}, retry: _noRetry);

final storeProductsProvider = FutureProvider.family<List<ProductSummary>, String>((ref, slug) async {
  final result = await ref.watch(storeApiServiceProvider).getStoreProducts(slug, pageSize: 20);
  return result.items;
}, retry: _noRetry);
