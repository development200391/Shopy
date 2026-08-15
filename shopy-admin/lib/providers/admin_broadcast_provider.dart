import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_broadcast_api_service.dart';
import 'auth_provider.dart';

final adminBroadcastApiServiceProvider = Provider<AdminBroadcastApiService>((ref) {
  return AdminBroadcastApiService(ref.watch(apiClientProvider));
});
