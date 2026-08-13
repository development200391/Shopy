import 'package:dio/dio.dart';

import '../models/promo/voucher.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerVoucherApiService {
  final ApiClient _apiClient;

  SellerVoucherApiService(this._apiClient);

  Future<List<Voucher>> getVouchers() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/vouchers');
      return (response.data as List).map((e) => Voucher.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<Voucher> getVoucher(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/seller/vouchers/$id');
      return Voucher.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<Voucher> createVoucher(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/api/seller/vouchers', data: data);
      return Voucher.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<Voucher> updateVoucher(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/api/seller/vouchers/$id', data: data);
      return Voucher.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> deleteVoucher(String id) async {
    try {
      await _apiClient.dio.delete('/api/seller/vouchers/$id');
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> setActive(String id, bool isActive) async {
    try {
      await _apiClient.dio.patch('/api/seller/vouchers/$id/active', data: {'isActive': isActive});
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
