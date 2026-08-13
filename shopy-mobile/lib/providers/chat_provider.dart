import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/chat_api_service.dart';
import '../services/uploads_api_service.dart';
import 'auth_provider.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  return ChatApiService(ref.watch(apiClientProvider));
});

final uploadsApiServiceProvider = Provider<UploadsApiService>((ref) {
  return UploadsApiService(ref.watch(apiClientProvider));
});
