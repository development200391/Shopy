import 'package:dio/dio.dart';

import '../models/promo/voucher_validation.dart';
import 'api_client.dart';
import 'order_exception.dart';

class VoucherApiService {
  final ApiClient _apiClient;

  VoucherApiService(this._apiClient);

  Future<VoucherValidation> validate({
    required String storeId,
    required String code,
    required int subtotal,
    int shippingCost = 0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/vouchers/validate',
        data: {'storeId': storeId, 'code': code, 'subtotal': subtotal, 'shippingCost': shippingCost},
      );
      return VoucherValidation.fromJson(response.data as Map<String, dynamic>);
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
