import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/review_api_service.dart';
import 'auth_provider.dart';

final reviewApiServiceProvider = Provider<ReviewApiService>((ref) {
  return ReviewApiService(ref.watch(apiClientProvider));
});
