import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promo/voucher.dart';
import '../services/seller_voucher_api_service.dart';
import 'auth_provider.dart';

final sellerVoucherApiServiceProvider = Provider<SellerVoucherApiService>((ref) {
  return SellerVoucherApiService(ref.watch(apiClientProvider));
});

final sellerVouchersProvider = FutureProvider.autoDispose<List<Voucher>>((ref) {
  return ref.watch(sellerVoucherApiServiceProvider).getVouchers();
});
