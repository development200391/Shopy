import '../models/address/address.dart';

class AddressState {
  final List<Address> items;
  final bool loading;
  final String? error;

  const AddressState({this.items = const [], this.loading = false, this.error});

  Address? get defaultAddress {
    if (items.isEmpty) return null;
    return items.where((a) => a.isDefault).firstOrNull ?? items.first;
  }

  AddressState copyWith({List<Address>? items, bool? loading, String? error, bool clearError = false}) {
    return AddressState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
