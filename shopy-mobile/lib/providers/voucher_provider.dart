import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/voucher_api_service.dart';
import 'auth_provider.dart';

final voucherApiServiceProvider = Provider<VoucherApiService>((ref) {
  return VoucherApiService(ref.watch(apiClientProvider));
});
