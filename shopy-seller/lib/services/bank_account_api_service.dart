import 'package:dio/dio.dart';

import '../models/store/bank_account.dart';
import 'api_client.dart';
import 'seller_exception.dart';

class BankAccountApiService {
  final ApiClient _apiClient;

  BankAccountApiService(this._apiClient);

  Future<List<BankAccount>> getBankAccounts() async {
    try {
      final response = await _apiClient.dio.get('/api/seller/bank-accounts');
      return (response.data as List)
          .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<BankAccount> createBankAccount({
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    bool isDefault = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/seller/bank-accounts',
        data: {
          'bankCode': bankCode,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
          'isDefault': isDefault,
        },
      );
      return BankAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<BankAccount> setDefault(String id) async {
    try {
      final response = await _apiClient.dio.patch('/api/seller/bank-accounts/$id/default');
      return BankAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  Future<void> deleteBankAccount(String id) async {
    try {
      await _apiClient.dio.delete('/api/seller/bank-accounts/$id');
    } on DioException catch (e) {
      throw SellerException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
