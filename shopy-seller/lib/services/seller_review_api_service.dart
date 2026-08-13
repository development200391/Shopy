import 'package:dio/dio.dart';

import '../models/review/seller_review.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerReviewApiService {
  final ApiClient _apiClient;

  SellerReviewApiService(this._apiClient);

  Future<SellerReviewSummary> getSummary() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/reviews/summary');
      return SellerReviewSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  /// `filter`: null (semua) | "belum-dibalas" | "1".."5".
  Future<List<SellerReview>> getReviews({String? filter}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/reviews',
        queryParameters: {if (filter != null) 'filter': filter, 'pageSize': 50},
      );
      final items = (response.data as Map<String, dynamic>)['items'] as List;
      return items.map((e) => SellerReview.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<SellerReview> reply(String id, String reply) async {
    try {
      final response = await _apiClient.dio.post('/api/seller/reviews/$id/reply', data: {'reply': reply});
      return SellerReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
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
