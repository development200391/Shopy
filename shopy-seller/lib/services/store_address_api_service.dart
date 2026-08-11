import 'package:dio/dio.dart';

import '../models/store/store_address.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class StoreAddressApiService {
  final ApiClient _apiClient;

  StoreAddressApiService(this._apiClient);

  Future<List<StoreAddress>> getAddresses() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/store/addresses');
      return (response.data as List)
          .map((e) => StoreAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreAddress> createAddress({
    required String label,
    required String picName,
    required String phoneNumber,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    bool isDefault = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/store/addresses',
        data: {
          'label': label,
          'picName': picName,
          'phoneNumber': phoneNumber,
          'fullAddress': fullAddress,
          'city': city,
          'province': province,
          'postalCode': postalCode,
          'isDefault': isDefault,
        },
      );
      return StoreAddress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreAddress> setDefault(String id) async {
    try {
      final response = await _apiClient.dio.patch('/api/seller/store/addresses/$id/default');
      return StoreAddress.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _apiClient.dio.delete('/api/seller/store/addresses/$id');
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
