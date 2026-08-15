import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/seller_document_api_service.dart';
import 'auth_provider.dart';

final sellerDocumentApiServiceProvider = Provider<SellerDocumentApiService>((ref) {
  return SellerDocumentApiService(ref.watch(apiClientProvider));
});

final sellerDocumentsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(sellerDocumentApiServiceProvider).getDocuments();
});
