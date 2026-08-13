import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/order/order_detail.dart';
import '../models/order/sub_order_detail.dart';
import '../models/order/sub_order_status.dart';
import '../models/order/sub_order_summary.dart';
import 'api_client.dart';
import 'order_exception.dart';

class OrderApiService {
  final ApiClient _apiClient;

  OrderApiService(this._apiClient);

  Future<PagedResult<SubOrderSummary>> getSubOrders({
    SubOrderStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/orders/sub-orders',
        queryParameters: {if (status != null) 'status': status.apiValue, 'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, SubOrderSummary.fromJson);
    } on DioException catch (e) {
      throw OrderException(_extractMessage(e));
    }
  }

  Future<SubOrderDetail> getSubOrderDetail(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/orders/sub-orders/$id');
      return SubOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_extractMessage(e));
    }
  }

  Future<SubOrderDetail> updateSubOrderStatus(String id, SubOrderStatus status) async {
    try {
      final response = await _apiClient.dio.patch(
        '/api/orders/sub-orders/$id/status',
        data: {'status': status.apiValue},
      );
      return SubOrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_extractMessage(e));
    }
  }

  /// `vouchers`: 1 entry per toko yang mau pakai kode voucher, `{storeId: code}`.
  Future<OrderDetail> checkout({
    required String addressId,
    required List<String> cartItemIds,
    String? note,
    Map<String, String> vouchers = const {},
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/orders',
        data: {
          'addressId': addressId,
          'cartItemIds': cartItemIds,
          if (note != null && note.isNotEmpty) 'note': note,
          if (vouchers.isNotEmpty)
            'vouchers': [
              for (final entry in vouchers.entries) {'storeId': entry.key, 'code': entry.value},
            ],
        },
      );
      return OrderDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_extractMessage(e));
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
