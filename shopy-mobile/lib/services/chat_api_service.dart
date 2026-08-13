import 'package:dio/dio.dart';

import '../models/chat/chat_message.dart';
import '../models/chat/chat_room.dart';
import 'api_client.dart';
import 'chat_exception.dart';

class ChatApiService {
  final ApiClient _apiClient;

  ChatApiService(this._apiClient);

  Future<ChatRoom> openRoom(String storeId) async {
    try {
      final response = await _apiClient.dio.post('/api/chats', data: {'storeId': storeId});
      return ChatRoom.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChatException(_extractMessage(e));
    }
  }

  Future<List<ChatMessage>> getMessages(String roomId, {DateTime? before}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/chats/$roomId/messages',
        queryParameters: {if (before != null) 'before': before.toUtc().toIso8601String()},
      );
      return (response.data as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ChatException(_extractMessage(e));
    }
  }

  Future<ChatMessage> sendMessage(String roomId, {String? body, String? attachmentUrl}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/chats/$roomId/messages',
        data: {'body': body, 'attachmentUrl': attachmentUrl},
      );
      return ChatMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ChatException(_extractMessage(e));
    }
  }

  Future<void> markRead(String roomId) async {
    try {
      await _apiClient.dio.post('/api/chats/$roomId/read');
    } on DioException catch (e) {
      throw ChatException(_extractMessage(e));
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
