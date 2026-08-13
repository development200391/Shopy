import 'package:dio/dio.dart';

import '../models/catalog/paged_result.dart';
import '../models/finance/balance_transaction.dart';
import '../models/finance/store_balance.dart';
import '../models/finance/withdrawal.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class SellerFinanceApiService {
  final ApiClient _apiClient;

  SellerFinanceApiService(this._apiClient);

  Future<StoreBalance> getBalance() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/finance/balance');
      return StoreBalance.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  /// `type`: null (semua) | "income" | "withdrawal".
  Future<PagedResult<BalanceTransaction>> getTransactions({
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/finance/transactions',
        queryParameters: {if (type != null) 'type': type, 'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => BalanceTransaction.fromJson(json),
      );
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<Withdrawal> requestWithdrawal({required String bankAccountId, required int amount}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/finance/withdrawals',
        data: {'bankAccountId': bankAccountId, 'amount': amount},
      );
      return Withdrawal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<PagedResult<Withdrawal>> getWithdrawals({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/seller/finance/withdrawals',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(response.data as Map<String, dynamic>, (json) => Withdrawal.fromJson(json));
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
