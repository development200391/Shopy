import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product/seller_product_detail.dart';
import '../models/product/seller_product_summary.dart';
import '../services/category_api_service.dart';
import '../services/seller_product_api_service.dart';
import 'auth_provider.dart';

final sellerProductApiServiceProvider = Provider<SellerProductApiService>((ref) {
  return SellerProductApiService(ref.watch(apiClientProvider));
});

final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  return CategoryApiService(ref.watch(apiClientProvider));
});

typedef ProductListFilter = ({String status, String? search});

final sellerProductsProvider = FutureProvider.autoDispose
    .family<List<SellerProductSummary>, ProductListFilter>((ref, filter) async {
      final result = await ref
          .watch(sellerProductApiServiceProvider)
          .getProducts(status: filter.status, search: filter.search);
      return result.items;
    });

final sellerProductDetailProvider = FutureProvider.autoDispose.family<SellerProductDetail, String>((
  ref,
  id,
) {
  return ref.watch(sellerProductApiServiceProvider).getProduct(id);
});

/// Label "Root" (kalau tidak punya anak) atau "Root > Anak" — lihat keputusan
/// TASKSELLER.md Fase 3 soal picker kategori flat (bukan drill-down 2 langkah).
class CategoryOption {
  final String id;
  final String label;

  const CategoryOption({required this.id, required this.label});
}

final categoryOptionsProvider = FutureProvider.autoDispose<List<CategoryOption>>((ref) async {
  final api = ref.watch(categoryApiServiceProvider);
  final roots = await api.getRootCategories();
  final options = <CategoryOption>[];

  for (final root in roots) {
    final children = await api.getChildCategories(root.slug);
    if (children.isEmpty) {
      options.add(CategoryOption(id: root.id, label: root.name));
    } else {
      for (final child in children) {
        options.add(CategoryOption(id: child.id, label: '${root.name} > ${child.name}'));
      }
    }
  }

  return options;
});
