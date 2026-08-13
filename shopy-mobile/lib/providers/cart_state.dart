import '../models/cart/cart_item.dart';

/// Ongkir flat per toko untuk simulasi UI — cerminan quote default
/// (`Couriers.Default`) yang dipakai backend saat checkout (TASKSELLER.md Fase 4).
const int kMockShippingCost = 15000;

/// Sekelompok item keranjang milik 1 toko — dipakai untuk merender keranjang
/// & checkout per toko (Fase 4: checkout dipecah jadi 1 `SubOrder` per toko).
class CartStoreGroup {
  final String storeId;
  final String storeName;
  final List<CartItem> items;

  const CartStoreGroup({required this.storeId, required this.storeName, required this.items});

  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
}

List<CartStoreGroup> _groupByStore(List<CartItem> items) {
  final storeOrder = <String>[];
  final itemsByStore = <String, List<CartItem>>{};
  final namesByStore = <String, String>{};

  for (final item in items) {
    if (!itemsByStore.containsKey(item.storeId)) storeOrder.add(item.storeId);
    itemsByStore.putIfAbsent(item.storeId, () => []).add(item);
    namesByStore[item.storeId] = item.storeName;
  }

  return [
    for (final storeId in storeOrder)
      CartStoreGroup(storeId: storeId, storeName: namesByStore[storeId]!, items: itemsByStore[storeId]!),
  ];
}

class CartState {
  final List<CartItem> items;
  final bool loading;
  final String? error;

  const CartState({this.items = const [], this.loading = false, this.error});

  bool get isEmpty => items.isEmpty;

  bool get allSelected => items.isNotEmpty && items.every((item) => item.selected);

  List<CartItem> get selectedItems => items.where((item) => item.selected).toList();

  int get selectedCount => selectedItems.length;

  /// Total qty semua barang (dipakai untuk badge di bottom nav).
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.qty);

  List<CartStoreGroup> get storeGroups => _groupByStore(items);

  List<CartStoreGroup> get selectedStoreGroups => _groupByStore(selectedItems);

  int get subtotal => selectedItems.fold(0, (sum, item) => sum + item.subtotal);

  /// 1 ongkir per toko yang punya barang terpilih — sinkron dengan cara
  /// backend membuat 1 `SubOrder` (+ 1 ongkir) per toko saat checkout.
  int get shippingCost => selectedStoreGroups.length * kMockShippingCost;

  /// Diskon voucher toko baru diketahui di halaman Checkout (per toko, lihat
  /// `checkout_screen.dart`) — total di level Keranjang murni subtotal+ongkir.
  int get total => subtotal + shippingCost;

  CartState copyWith({List<CartItem>? items, bool? loading, String? error, bool clearError = false}) {
    return CartState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
