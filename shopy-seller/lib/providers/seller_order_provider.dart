import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order/seller_order_detail.dart';
import '../models/order/seller_order_summary.dart';
import '../services/seller_order_api_service.dart';
import 'auth_provider.dart';

final sellerOrderApiServiceProvider = Provider<SellerOrderApiService>((ref) {
  return SellerOrderApiService(ref.watch(apiClientProvider));
});

/// `status`: "new" | "processing" | "shipped" | "completed" — sesuai tab di
/// Daftar Pesanan (TASKSELLER.md Fase 4).
final sellerOrdersProvider = FutureProvider.autoDispose.family<List<SellerOrderSummary>, String>((
  ref,
  status,
) async {
  final result = await ref.watch(sellerOrderApiServiceProvider).getOrders(status: status);
  return result.items;
});

final sellerOrderDetailProvider = FutureProvider.autoDispose.family<SellerOrderDetail, String>((
  ref,
  id,
) {
  return ref.watch(sellerOrderApiServiceProvider).getOrder(id);
});
