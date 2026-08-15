import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard/seller_statistics.dart';
import '../services/seller_dashboard_api_service.dart';
import 'auth_provider.dart';

final sellerDashboardApiServiceProvider = Provider<SellerDashboardApiService>((ref) {
  return SellerDashboardApiService(ref.watch(apiClientProvider));
});

final sellerDashboardProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(sellerDashboardApiServiceProvider).getDashboard();
});

final sellerStatisticsProvider = FutureProvider.autoDispose.family<SellerStatistics, String>((ref, period) {
  return ref.watch(sellerDashboardApiServiceProvider).getStatistics(period);
});
