import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/product/seller_product_detail.dart';
import '../models/product/seller_product_summary.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerProductApiService {
  final ApiClient _apiClient;

  SellerProductApiService(this._apiClient);

  Future<PagedResult<SellerProductSummary>> getProducts({
    String status = 'all',
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/products',
        queryParameters: {
          'status': status,
          if (search != null && search.isNotEmpty) 'q': search,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => SellerProductSummary.fromJson(json),
      );
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<SellerProductDetail> getProduct(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/seller/products/$id');
      return SellerProductDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<SellerProductDetail> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/api/seller/products', data: data);
      return SellerProductDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<SellerProductDetail> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/api/seller/products/$id', data: data);
      return SellerProductDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.dio.delete('/api/seller/products/$id');
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> setActive(String id, bool isActive) async {
    try {
      await _apiClient.dio.patch('/api/seller/products/$id/active', data: {'isActive': isActive});
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> bulkUpdate(List<Map<String, dynamic>> items) async {
    try {
      await _apiClient.dio.patch('/api/seller/products/bulk', data: {'items': items});
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
