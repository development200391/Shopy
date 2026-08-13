import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/finance/balance_transaction.dart';
import '../models/finance/store_balance.dart';
import '../models/finance/withdrawal.dart';
import '../services/seller_finance_api_service.dart';
import 'auth_provider.dart';

final sellerFinanceApiServiceProvider = Provider<SellerFinanceApiService>((ref) {
  return SellerFinanceApiService(ref.watch(apiClientProvider));
});

final storeBalanceProvider = FutureProvider.autoDispose<StoreBalance>((ref) {
  return ref.watch(sellerFinanceApiServiceProvider).getBalance();
});

/// `type`: null (semua) | "income" | "withdrawal" — sesuai tab filter di halaman Keuangan.
final balanceTransactionsProvider = FutureProvider.autoDispose.family<List<BalanceTransaction>, String?>((
  ref,
  type,
) async {
  final result = await ref.watch(sellerFinanceApiServiceProvider).getTransactions(type: type);
  return result.items;
});

final withdrawalsProvider = FutureProvider.autoDispose<List<Withdrawal>>((ref) async {
  final result = await ref.watch(sellerFinanceApiServiceProvider).getWithdrawals();
  return result.items;
});
