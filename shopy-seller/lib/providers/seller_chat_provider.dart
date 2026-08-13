import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat/chat_room.dart';
import '../services/seller_chat_api_service.dart';
import 'auth_provider.dart';

final sellerChatApiServiceProvider = Provider<SellerChatApiService>((ref) {
  return SellerChatApiService(ref.watch(apiClientProvider));
});

final sellerChatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((ref) {
  return ref.watch(sellerChatApiServiceProvider).getRooms();
});
