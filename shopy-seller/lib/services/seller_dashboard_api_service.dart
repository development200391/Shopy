import 'package:dio/dio.dart';

import '../models/dashboard/seller_dashboard.dart';
import '../models/dashboard/seller_statistics.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerDashboardApiService {
  final ApiClient _apiClient;

  SellerDashboardApiService(this._apiClient);

  Future<SellerDashboard> getDashboard() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/dashboard');
      return SellerDashboard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<SellerStatistics> getStatistics(String period) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/statistics',
        queryParameters: {'period': period},
      );
      return SellerStatistics.fromJson(response.data as Map<String, dynamic>);
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
