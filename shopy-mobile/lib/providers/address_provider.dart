import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address/address.dart';
import '../services/address_api_service.dart';
import 'address_state.dart';
import 'auth_provider.dart';

final addressApiServiceProvider = Provider<AddressApiService>((ref) {
  return AddressApiService(ref.watch(apiClientProvider));
});

final addressProvider = NotifierProvider<AddressNotifier, AddressState>(AddressNotifier.new);

class AddressNotifier extends Notifier<AddressState> {
  @override
  AddressState build() {
    _load();
    return const AddressState(loading: true);
  }

  AddressApiService get _api => ref.read(addressApiServiceProvider);

  Future<void> _load() async {
    try {
      final items = await _api.getAddresses();
      state = state.copyWith(items: items, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> reload() => _load();

  Future<void> create({
    required String label,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    bool isDefault = false,
  }) async {
    final created = await _api.createAddress(
      label: label,
      recipientName: recipientName,
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

  /// Server cuma balikin 1 address yang dimutasi, tapi jadiin dia default
  /// berarti address lain otomatis bukan default lagi — refleksikan itu di
  /// state lokal tanpa perlu fetch ulang semuanya.
  void _replaceAll(Address updatedOrCreated) {
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
