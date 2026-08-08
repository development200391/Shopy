import 'package:dio/dio.dart';

import '../models/cart/cart_item.dart';
import 'api_client.dart';
import 'cart_exception.dart';

class CartApiService {
  final ApiClient _apiClient;

  CartApiService(this._apiClient);

  Future<List<CartItem>> getCart() => _request(() => _apiClient.dio.get('/api/cart'));

  Future<List<CartItem>> addItem(String productId, int quantity) => _request(
    () => _apiClient.dio.post('/api/cart/items', data: {'productId': productId, 'quantity': quantity}),
  );

  Future<List<CartItem>> updateItem(String itemId, int quantity) => _request(
    () => _apiClient.dio.put('/api/cart/items/$itemId', data: {'quantity': quantity}),
  );

  Future<List<CartItem>> removeItem(String itemId) =>
      _request(() => _apiClient.dio.delete('/api/cart/items/$itemId'));

  Future<List<CartItem>> clearCart() => _request(() => _apiClient.dio.delete('/api/cart'));

  Future<List<CartItem>> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      final items = (response.data['items'] as List).cast<Map<String, dynamic>>();
      return items.map(CartItem.fromJson).toList();
    } on DioException catch (e) {
      throw CartException(_extractMessage(e));
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
