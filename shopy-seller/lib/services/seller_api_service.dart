import 'package:dio/dio.dart';

import '../models/auth/auth_response.dart';
import '../models/store/seller_me.dart';
import '../models/store/store_detail.dart';
import '../models/store/store_summary.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerApiService {
  final ApiClient _apiClient;

  SellerApiService(this._apiClient);

  Future<SellerMe> getMe() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/me');
      return SellerMe.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<AuthResponse> openStore({
    required String name,
    required String slug,
    String? description,
    String? phoneNumber,
    required String addressLabel,
    required String addressPicName,
    required String addressPhoneNumber,
    required String addressFullAddress,
    required String addressCity,
    required String addressProvince,
    required String addressPostalCode,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/store',
        data: {
          'name': name,
          'slug': slug,
          if (description != null && description.isNotEmpty) 'description': description,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
          'addressLabel': addressLabel,
          'addressPicName': addressPicName,
          'addressPhoneNumber': addressPhoneNumber,
          'addressFullAddress': addressFullAddress,
          'addressCity': addressCity,
          'addressProvince': addressProvince,
          'addressPostalCode': addressPostalCode,
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreSummary?> getStoreStatus() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/store/status');
      return StoreSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreDetail> getStoreDetail() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/store');
      return StoreDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreDetail> updateStore({
    required String name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? phoneNumber,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/seller/store',
        data: {
          'name': name,
          'description': description,
          'logoUrl': logoUrl,
          'bannerUrl': bannerUrl,
          'phoneNumber': phoneNumber,
        },
      );
      return StoreDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreDetail> setStoreOpen(bool isOpen) async {
    try {
      final response = await _apiClient.dio.patch(
        '/api/seller/store/open',
        data: {'isOpen': isOpen},
      );
      return StoreDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  /// `category`: "logo" | "banner" | "document" — lihat `UploadsController` backend.
  Future<String> uploadFile(String filePath, String category) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.dio.post(
        '/api/uploads',
        data: formData,
        queryParameters: {'category': category},
      );
      return response.data['url'] as String;
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
