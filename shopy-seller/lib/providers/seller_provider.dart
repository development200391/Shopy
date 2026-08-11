import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store/seller_me.dart';
import '../services/seller_api_service.dart';
import 'auth_provider.dart';

final sellerApiServiceProvider = Provider<SellerApiService>((ref) {
  return SellerApiService(ref.watch(apiClientProvider));
});

/// Dipanggil ulang (via `ref.refresh`) tiap kali perlu re-route setelah auth
/// atau setelah toko baru dibuka — sumber kebenaran status toko selalu dari server,
/// bukan dari claim JWT yang mungkin sudah basi di sesi lama.
final sellerMeProvider = FutureProvider.autoDispose<SellerMe>((ref) {
  return ref.watch(sellerApiServiceProvider).getMe();
});
