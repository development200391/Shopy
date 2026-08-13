import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/order/seller_order_detail.dart';
import '../models/order/seller_order_summary.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerOrderApiService {
  final ApiClient _apiClient;

  SellerOrderApiService(this._apiClient);

  Future<PagedResult<SellerOrderSummary>> getOrders({
    required String status,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/orders',
        queryParameters: {'status': status, 'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => SellerOrderSummary.fromJson(json),
      );
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<SellerOrderDetail> getOrder(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/seller/orders/$id');
      return SellerOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> accept(String id) async {
    try {
      await _apiClient.dio.post('/api/seller/orders/$id/accept');
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> reject(String id, String reason) async {
    try {
      await _apiClient.dio.post('/api/seller/orders/$id/reject', data: {'reason': reason});
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> ship(
    String id, {
    required String courierCode,
    required String courierService,
    required String trackingNumber,
    String? proofPhotoUrl,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/seller/orders/$id/ship',
        data: {
          'courierCode': courierCode,
          'courierService': courierService,
          'trackingNumber': trackingNumber,
          'proofPhotoUrl': proofPhotoUrl,
        },
      );
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
