import '../models/store/store_address.dart';

class StoreAddressState {
  final List<StoreAddress> items;
  final bool loading;
  final String? error;

  const StoreAddressState({this.items = const [], this.loading = false, this.error});

  StoreAddressState copyWith({
    List<StoreAddress>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return StoreAddressState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
