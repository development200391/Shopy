import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/review/review.dart';
import 'api_client.dart';
import 'review_exception.dart';

class ReviewApiService {
  final ApiClient _apiClient;

  ReviewApiService(this._apiClient);

  Future<PagedResult<Review>> getProductReviews(String productId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/products/$productId/reviews',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, Review.fromJson);
    } on DioException catch (e) {
      throw ReviewException(_extractMessage(e));
    }
  }

  Future<Review> createReview(
    String subOrderId, {
    required String productId,
    required int rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/orders/$subOrderId/reviews',
        data: {
          'productId': productId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        },
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ReviewException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
