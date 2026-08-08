import 'package:dio/dio.dart';

import '../models/payment/payment.dart';
import '../models/payment/payment_method.dart';
import 'api_client.dart';
import 'payment_exception.dart';

class PaymentApiService {
  final ApiClient _apiClient;

  PaymentApiService(this._apiClient);

  Future<Payment> createPayment({required String orderId, required PaymentMethod method}) => _request(
    () => _apiClient.dio.post('/api/orders/$orderId/payments', data: {'method': method.apiValue}),
  );

  Future<Payment> getLatestPayment(String orderId) =>
      _request(() => _apiClient.dio.get('/api/orders/$orderId/payments/latest'));

  Future<Payment> refreshLatestPayment(String orderId) =>
      _request(() => _apiClient.dio.post('/api/orders/$orderId/payments/latest/refresh'));

  Future<Payment> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      return Payment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw PaymentException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) {
        return data['detail'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
