import 'package:dio/dio.dart';

import '../models/address/address.dart';
import 'address_exception.dart';
import 'api_client.dart';

class AddressApiService {
  final ApiClient _apiClient;

  AddressApiService(this._apiClient);

  Future<List<Address>> getAddresses() async {
    try {
      final response = await _apiClient.dio.get('/api/addresses');
      return (response.data as List).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AddressException(_extractMessage(e));
    }
  }

  Future<Address> createAddress({
    required String label,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    bool isDefault = false,
  }) => _save(
    () => _apiClient.dio.post(
      '/api/addresses',
      data: _body(label, recipientName, phoneNumber, fullAddress, city, province, postalCode, isDefault),
    ),
  );

  Future<Address> updateAddress({
    required String id,
    required String label,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    bool isDefault = false,
  }) => _save(
    () => _apiClient.dio.put(
      '/api/addresses/$id',
      data: _body(label, recipientName, phoneNumber, fullAddress, city, province, postalCode, isDefault),
    ),
  );

  Future<void> deleteAddress(String id) async {
    try {
      await _apiClient.dio.delete('/api/addresses/$id');
    } on DioException catch (e) {
      throw AddressException(_extractMessage(e));
    }
  }

  Future<Address> setDefault(String id) => _save(() => _apiClient.dio.patch('/api/addresses/$id/default'));

  Future<Address> _save(Future<Response> Function() call) async {
    try {
      final response = await call();
      return Address.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AddressException(_extractMessage(e));
    }
  }

  Map<String, dynamic> _body(
    String label,
    String recipientName,
    String phoneNumber,
    String fullAddress,
    String city,
    String province,
    String postalCode,
    bool isDefault,
  ) {
    return {
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'fullAddress': fullAddress,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
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
