import '../models/store/bank_account.dart';

class BankAccountState {
  final List<BankAccount> items;
  final bool loading;
  final String? error;

  const BankAccountState({this.items = const [], this.loading = false, this.error});

  BankAccountState copyWith({
    List<BankAccount>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return BankAccountState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
