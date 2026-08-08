import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/payment_api_service.dart';
import 'auth_provider.dart';

final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  return PaymentApiService(ref.watch(apiClientProvider));
});
