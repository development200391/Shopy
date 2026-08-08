import 'package:dio/dio.dart';

import '../models/wishlist/wishlist_item.dart';
import 'api_client.dart';
import 'wishlist_exception.dart';

class WishlistApiService {
  final ApiClient _apiClient;

  WishlistApiService(this._apiClient);

  Future<List<WishlistItem>> getWishlist() async {
    try {
      final response = await _apiClient.dio.get('/api/wishlist');
      return (response.data as List)
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw WishlistException(_extractMessage(e));
    }
  }

  Future<WishlistItem> addFavorite(String productId) async {
    try {
      final response = await _apiClient.dio.post('/api/wishlist', data: {'productId': productId});
      return WishlistItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw WishlistException(_extractMessage(e));
    }
  }

  Future<void> removeFavorite(String productId) async {
    try {
      await _apiClient.dio.delete('/api/wishlist/$productId');
    } on DioException catch (e) {
      throw WishlistException(_extractMessage(e));
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
