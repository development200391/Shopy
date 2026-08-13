import 'package:dio/dio.dart';

import '../models/chat/chat_message.dart';
import '../models/chat/chat_room.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerChatApiService {
  final ApiClient _apiClient;

  SellerChatApiService(this._apiClient);

  Future<List<ChatRoom>> getRooms() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/chats');
      return (response.data as List).map((e) => ChatRoom.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  /// Cari room yang sudah ada dengan pembeli tertentu — sisi seller tidak
  /// bisa membuat room baru (hanya pembeli yang bisa memulai percakapan lewat
  /// `POST /api/chats`), null kalau pembeli itu belum pernah chat.
  Future<ChatRoom?> findRoomByBuyer(String buyerUserId) async {
    try {
      final response = await _apiClient.dio.get('/api/seller/chats/by-buyer/$buyerUserId');
      return ChatRoom.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw SellerException(_extractMessage(e));
    }
  }

  Future<List<ChatMessage>> getMessages(String roomId, {DateTime? before}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/chats/$roomId/messages',
        queryParameters: {if (before != null) 'before': before.toUtc().toIso8601String()},
      );
      return (response.data as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<ChatMessage> sendMessage(
    String roomId, {
    String? body,
    String? attachmentUrl,
    String? productId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/chats/$roomId/messages',
        data: {'body': body, 'attachmentUrl': attachmentUrl, 'productId': productId},
      );
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> markRead(String roomId) async {
    try {
      await _apiClient.dio.post('/api/seller/chats/$roomId/read');
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
