import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review/seller_review.dart';
import '../services/seller_review_api_service.dart';
import 'auth_provider.dart';

final sellerReviewApiServiceProvider = Provider<SellerReviewApiService>((ref) {
  return SellerReviewApiService(ref.watch(apiClientProvider));
});

final sellerReviewSummaryProvider = FutureProvider.autoDispose<SellerReviewSummary>((ref) {
  return ref.watch(sellerReviewApiServiceProvider).getSummary();
});

/// `filter`: null (semua) | "belum-dibalas" | "1".."5".
final sellerReviewsProvider = FutureProvider.autoDispose.family<List<SellerReview>, String?>((ref, filter) {
  return ref.watch(sellerReviewApiServiceProvider).getReviews(filter: filter);
});
