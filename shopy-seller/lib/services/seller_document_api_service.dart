import 'package:dio/dio.dart';

import '../models/store/store_document.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerDocumentApiService {
  final ApiClient _apiClient;

  SellerDocumentApiService(this._apiClient);

  Future<List<StoreDocument>> getDocuments() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/store/documents');
      return (response.data as List).map((e) => StoreDocument.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<StoreDocument> createDocument({required StoreDocumentType type, required String fileUrl}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/store/documents',
        data: {'type': type.apiValue, 'fileUrl': fileUrl},
      );
      return StoreDocument.fromJson(response.data as Map<String, dynamic>);
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
