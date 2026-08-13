import 'package:dio/dio.dart';

import '../models/catalog/category.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class CategoryApiService {
  final ApiClient _apiClient;

  CategoryApiService(this._apiClient);

  Future<List<Category>> getRootCategories() async {
    try {
      final response = await _apiClient.dio.get('/api/categories');
      return (response.data as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<List<Category>> getChildCategories(String slug) async {
    try {
      final response = await _apiClient.dio.get('/api/categories/$slug');
      final children = (response.data as Map<String, dynamic>)['childCategories'] as List;
      return children.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
