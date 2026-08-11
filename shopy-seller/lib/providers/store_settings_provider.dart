import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store/bank_account.dart';
import '../models/store/store_address.dart';
import '../services/bank_account_api_service.dart';
import '../services/store_address_api_service.dart';
import 'auth_provider.dart';
import 'bank_account_state.dart';
import 'seller_provider.dart';
import 'store_address_state.dart';

/// Detail toko sendiri — di-`ref.invalidate()` tiap habis update profil/toggle buka-tutup.
final storeDetailProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(sellerApiServiceProvider).getStoreDetail();
});

final storeAddressApiServiceProvider = Provider<StoreAddressApiService>((ref) {
  return StoreAddressApiService(ref.watch(apiClientProvider));
});

final storeAddressesProvider =
    NotifierProvider<StoreAddressNotifier, StoreAddressState>(StoreAddressNotifier.new);

class StoreAddressNotifier extends Notifier<StoreAddressState> {
  @override
  StoreAddressState build() {
    _load();
    return const StoreAddressState(loading: true);
  }

  StoreAddressApiService get _api => ref.read(storeAddressApiServiceProvider);

  Future<void> _load() async {
    try {
      final items = await _api.getAddresses();
      state = state.copyWith(items: items, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> create({
    required String label,
    required String picName,
    required String phoneNumber,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    bool isDefault = false,
  }) async {
    final created = await _api.createAddress(
      label: label,
      picName: picName,
      phoneNumber: phoneNumber,
      fullAddress: fullAddress,
      city: city,
      province: province,
      postalCode: postalCode,
      isDefault: isDefault,
    );
    _replaceAll(created);
  }

  Future<void> setDefault(String id) async {
    final updated = await _api.setDefault(id);
    _replaceAll(updated);
  }

  Future<void> delete(String id) async {
    await _api.deleteAddress(id);
    state = state.copyWith(items: state.items.where((a) => a.id != id).toList());
  }

  void _replaceAll(StoreAddress updatedOrCreated) {
    final exists = state.items.any((a) => a.id == updatedOrCreated.id);
    final items = [
      for (final a in state.items)
        if (a.id == updatedOrCreated.id)
          updatedOrCreated
        else
          (updatedOrCreated.isDefault ? a.copyWith(isDefault: false) : a),
      if (!exists) updatedOrCreated,
    ];
    state = state.copyWith(items: items, clearError: true);
  }
}

final bankAccountApiServiceProvider = Provider<BankAccountApiService>((ref) {
  return BankAccountApiService(ref.watch(apiClientProvider));
});

final bankAccountsProvider =
    NotifierProvider<BankAccountNotifier, BankAccountState>(BankAccountNotifier.new);

class BankAccountNotifier extends Notifier<BankAccountState> {
  @override
  BankAccountState build() {
    _load();
    return const BankAccountState(loading: true);
  }

  BankAccountApiService get _api => ref.read(bankAccountApiServiceProvider);

  Future<void> _load() async {
    try {
      final items = await _api.getBankAccounts();
      state = state.copyWith(items: items, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> create({
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    bool isDefault = false,
  }) async {
    final created = await _api.createBankAccount(
      bankCode: bankCode,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolderName: accountHolderName,
      isDefault: isDefault,
    );
    _replaceAll(created);
  }

  Future<void> setDefault(String id) async {
    final updated = await _api.setDefault(id);
    _replaceAll(updated);
  }

  Future<void> delete(String id) async {
    await _api.deleteBankAccount(id);
    state = state.copyWith(items: state.items.where((a) => a.id != id).toList());
  }

  void _replaceAll(BankAccount updatedOrCreated) {
    final exists = state.items.any((a) => a.id == updatedOrCreated.id);
    final items = [
      for (final a in state.items)
        if (a.id == updatedOrCreated.id)
          updatedOrCreated
        else
          (updatedOrCreated.isDefault ? a.copyWith(isDefault: false) : a),
      if (!exists) updatedOrCreated,
    ];
    state = state.copyWith(items: items, clearError: true);
  }
}
